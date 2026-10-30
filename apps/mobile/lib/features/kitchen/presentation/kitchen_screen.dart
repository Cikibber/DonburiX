import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bowl_builder/domain/bowl_models.dart';
import '../../bowl_builder/state/bowl_providers.dart';
import '../../orders/domain/order_models.dart';
import '../../orders/domain/order_rules.dart';
import '../../orders/state/order_providers.dart';

/// Kitchen Display System: antrean aktif dan stok bahan untuk staf dapur.
class KitchenScreen extends ConsumerWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(kitchenOrdersProvider);
    final catalog = ref.watch(ingredientCatalogProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } on OrderFailure catch (error) {
        messenger?.showSnackBar(SnackBar(content: Text(error.message)));
      } on BowlFailure catch (error) {
        messenger?.showSnackBar(SnackBar(content: Text(error.message)));
      }
    }

    final repository = ref.read(bowlRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dapur (KDS)')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _heading(context, 'Antrean aktif'),
          ...orders.when(
            loading: () => const [
              Center(child: CircularProgressIndicator(key: Key('kds-loading'))),
            ],
            error: (error, _) => [
              Text(
                error is OrderFailure
                    ? error.message
                    : 'Antrean belum dapat dimuat.',
              ),
              TextButton(
                onPressed: () => ref.invalidate(kitchenOrdersProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
            data: (items) {
              // Antrean FIFO: pesanan paling lama di atas.
              final active = items.reversed
                  .where(
                    (order) =>
                        !order.cancelled &&
                        order.status != OrderStatus.completed,
                  )
                  .toList();
              if (active.isEmpty) {
                return const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Tidak ada pesanan aktif.'),
                  ),
                ];
              }
              return [
                for (final order in active)
                  _KitchenOrderCard(
                    order: order,
                    onAdvance: () =>
                        run(() => repository.advanceStatus(order.id)),
                  ),
              ];
            },
          ),
          const SizedBox(height: 24),
          _heading(context, 'Stok bahan'),
          ...catalog.when(
            loading: () => const [LinearProgressIndicator()],
            error: (_, _) => [const Text('Stok belum dapat dimuat.')],
            data: (ingredients) => [
              for (final item in ingredients)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  subtitle: Text(
                    item.availableStock == 0
                        ? '${item.category.label} · Habis'
                        : '${item.category.label} · ${item.availableStock} porsi',
                  ),
                  trailing: OutlinedButton(
                    key: Key('kds-restock-${item.id}'),
                    onPressed: () => run(() async {
                      await repository.restock(item.id, 5);
                      ref.invalidate(ingredientCatalogProvider);
                    }),
                    child: const Text('+5'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}

class _KitchenOrderCard extends StatelessWidget {
  const _KitchenOrderCard({required this.order, required this.onAdvance});

  final Order order;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final next = OrderStatusFlow.next(order.status);
    return Card(
      key: Key('kds-order-${order.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.displayId,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(order.status.label)),
              ],
            ),
            Text(
              '${order.customerName} · ${order.type.label} · '
              '${order.totalPortions} porsi · ${OrderEta.label(order.estimatedMinutes)}',
            ),
            if (order.type == OrderType.takeaway)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      order.arrived ? Icons.near_me : Icons.schedule,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.arrived
                          ? 'Pelanggan sudah tiba'
                          : 'Menunggu kedatangan',
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            for (final entry in order.items)
              Text(
                '${entry.bowl.quantity}× ${entry.bowl.ingredients.map((item) => item.name).join(' · ')}'
                '${entry.bowl.note.isEmpty ? '' : '\nCatatan: ${entry.bowl.note}'}',
              ),
            if (next != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                key: Key('kds-advance-${order.id}'),
                onPressed: onAdvance,
                child: Text(switch (next) {
                  OrderStatus.preparing => 'Mulai Siapkan',
                  OrderStatus.ready => 'Tandai Siap Diambil',
                  OrderStatus.completed => 'Selesaikan (Diambil)',
                  OrderStatus.placed => next.label,
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
