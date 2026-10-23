import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bowl_builder/domain/bowl_models.dart';
import '../../bowl_builder/state/bowl_providers.dart';
import '../domain/order_models.dart';
import '../domain/order_rules.dart';
import '../state/order_providers.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(orderStreamProvider(order.id)).value ?? order;
    final currentIndex = live.cancelled
        ? -1
        : OrderStatus.values.indexOf(live.status);
    final messenger = ScaffoldMessenger.maybeOf(context);

    void toast(String message) {
      messenger?.showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> advance() async {
      try {
        await ref.read(bowlRepositoryProvider).advanceStatus(live.id);
        ref.read(orderListProvider.notifier).refresh();
      } on OrderFailure catch (error) {
        toast(error.message);
      }
    }

    Future<void> cancel() async {
      try {
        await ref.read(bowlRepositoryProvider).cancelOrder(live.id);
        ref.read(orderListProvider.notifier).refresh();
        toast('Pesanan dibatalkan. Stok dikembalikan.');
      } on OrderFailure catch (error) {
        toast(error.message);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(live.displayId)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(
            '${live.customerName} · ${live.type.label}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Total ${formatRupiah(live.totalPrice)} · ${live.totalPortions} porsi',
          ),
          const SizedBox(height: 4),
          Text(
            key: const Key('order-status'),
            'Status: ${live.cancelled ? 'Dibatalkan' : live.status.label}',
          ),
          if (!live.cancelled && live.status != OrderStatus.completed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                key: const Key('order-eta'),
                'Estimasi saji ${OrderEta.label(live.estimatedMinutes)}',
              ),
            ),
          if (live.cancelled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                key: const Key('order-cancelled-banner'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE5DF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Pesanan dibatalkan. Stok dikembalikan.'),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Tahapan pesanan',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < OrderStatus.values.length; i++)
            _TimelineTile(
              status: OrderStatus.values[i],
              done: i <= currentIndex,
              isLast: i == OrderStatus.values.length - 1,
            ),
          if (!live.cancelled) ...[
            const SizedBox(height: 24),
            if (live.status != OrderStatus.completed)
              FilledButton.icon(
                key: const Key('advance-status-button'),
                onPressed: advance,
                icon: const Icon(Icons.soup_kitchen_outlined),
                label: Text(
                  'Simulasikan dapur → ${OrderStatusFlow.next(live.status)?.label ?? '-'}',
                ),
              ),
            if (OrderCancellation.canCancel(live)) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('cancel-order-button'),
                onPressed: cancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Batalkan Pesanan'),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Sinkronisasi status dapur aktif; layar ini mengikuti perubahan otomatis.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Isi pesanan',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final entry in live.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                entry.bowl.ingredients.map((item) => item.name).join(' · '),
              ),
              subtitle: Text(
                '${entry.bowl.quantity} porsi${entry.bowl.note.isEmpty ? '' : ' · ${entry.bowl.note}'}',
              ),
              trailing: Text(formatRupiah(entry.bowl.totalPrice)),
            ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.status,
    required this.done,
    required this.isLast,
  });

  final OrderStatus status;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              key: Key('timeline-${status.name}'),
              color: done ? Colors.green : Colors.grey,
            ),
            if (!isLast) const SizedBox(height: 4, child: Text('│')),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              status.label,
              style: TextStyle(
                fontWeight: done ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
