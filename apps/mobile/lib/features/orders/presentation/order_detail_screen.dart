import 'package:flutter/material.dart';

import '../../bowl_builder/domain/bowl_models.dart';
import '../domain/order_models.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final current = OrderStatus.values.indexOf(order.status);
    return Scaffold(
      appBar: AppBar(title: Text(order.displayId)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(
            '${order.customerName} · ${order.type.label}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Total ${formatRupiah(order.totalPrice)} · ${order.totalPortions} porsi',
          ),
          const SizedBox(height: 4),
          Text('Status: ${order.status.label}'),
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
              done: i <= current,
              isLast: i == OrderStatus.values.length - 1,
            ),
          const SizedBox(height: 24),
          Text(
            'Isi pesanan',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final entry in order.items)
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
          const SizedBox(height: 16),
          const Text(
            'Estimasi dan notifikasi dapur mengikuti tahap pengembangan berikutnya.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
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
