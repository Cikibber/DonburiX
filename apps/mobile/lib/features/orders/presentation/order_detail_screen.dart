import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/session_provider.dart';
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
    final actorEmail = ref.read(sessionProvider)?.email ?? '';

    void toast(String message) {
      messenger?.showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> arrive() async {
      try {
        await ref
            .read(bowlRepositoryProvider)
            .markArrived(
              live.id,
              ref.read(customerLocationProvider),
              actorEmail: actorEmail,
            );
        toast('Kedatangan terdeteksi. Dapur mulai menyiapkan pesanan.');
      } on OrderFailure catch (error) {
        toast(error.message);
      }
    }

    Future<void> cancel() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Batalkan pesanan?'),
          content: Text(
            'Pesanan ${live.displayId} akan dibatalkan dan tidak dapat '
            'dipulihkan.',
          ),
          actions: [
            TextButton(
              key: const Key('cancel-dismiss'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Tidak'),
            ),
            FilledButton(
              key: const Key('cancel-confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ya, batalkan'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      try {
        await ref
            .read(bowlRepositoryProvider)
            .cancelOrder(live.id, actorEmail: actorEmail);
        ref.invalidate(ingredientCatalogProvider);
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
            key: const Key('order-time'),
            'Dipesan ${formatOrderTime(live.createdAt)}',
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
            if (live.type == OrderType.takeaway &&
                !live.arrived &&
                live.status == OrderStatus.placed)
              FilledButton.icon(
                key: const Key('arrival-button'),
                onPressed: arrive,
                icon: const Icon(Icons.near_me_outlined),
                label: const Text('Saya Sudah Tiba'),
              ),
            if (live.arrived)
              const Text(
                key: Key('arrival-confirmed'),
                'Kedatangan terdeteksi dalam radius 500 m gerai.',
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
              'Status mengikuti layar dapur secara otomatis. Untuk takeaway, dapur mulai merakit saat Anda berada dalam radius 500 m.',
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
            if (!isLast)
              Container(
                key: Key('timeline-line-${status.name}'),
                width: 2,
                height: 16,
                color: done ? Colors.green : Colors.grey.shade400,
              ),
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
