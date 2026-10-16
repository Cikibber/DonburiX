import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bowl_builder/domain/bowl_models.dart';
import '../domain/order_models.dart';
import '../state/order_providers.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan')),
      body: orders.when(
        loading: () => const Center(
          child: CircularProgressIndicator(key: Key('orders-loading')),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 56),
                const SizedBox(height: 24),
                Text(
                  error is OrderFailure
                      ? error.message
                      : 'Terjadi kendala. Silakan coba lagi.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () =>
                      ref.read(orderListProvider.notifier).refresh(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 56),
                      SizedBox(height: 24),
                      Text(
                        'Belum ada pesanan',
                        style: TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Racik bowl, checkout, dan lacak statusnya di sini.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final order = items[index];
                  return Card(
                    key: Key('order-${order.id}'),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(order.displayId),
                      subtitle: Text(
                        '${order.customerName} · ${order.type.label} · ${order.totalPortions} porsi',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatRupiah(order.totalPrice),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(order.status.label),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                OrderDetailScreen(order: order),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
