import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bowl_builder/domain/bowl_models.dart';
import '../../bowl_builder/state/bowl_providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builder = ref.watch(bowlBuilderProvider);
    final total = ref.watch(cartTotalProvider);
    final notifier = ref.read(bowlBuilderProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang Anda')),
      body: builder.cart.isEmpty
          ? const _CartEmpty()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                if (builder.cartError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE5DF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        builder.cartError!,
                        key: const Key('cart-error'),
                      ),
                    ),
                  ),
                for (final entry in builder.cart)
                  _CartCard(
                    entry: entry,
                    onDecrease: () => notifier.updateCartQuantity(
                      entry.id,
                      entry.bowl.quantity - 1,
                    ),
                    onIncrease: () => notifier.updateCartQuantity(
                      entry.id,
                      entry.bowl.quantity + 1,
                    ),
                    onRemove: () => notifier.removeFromCart(entry.id),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF272A21),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total keranjang',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      Text(
                        formatRupiah(total),
                        key: const Key('cart-total'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('checkout-button'),
                  onPressed: () {},
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Lanjut ke Checkout'),
                ),
              ],
            ),
    );
  }
}

class _CartCard extends StatelessWidget {
  const _CartCard({
    required this.entry,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final CartEntry entry;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('cart-item-${entry.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.bowl.ingredients.map((item) => item.name).join(' · '),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.bowl.quantity} porsi${entry.bowl.note.isEmpty ? '' : ' · ${entry.bowl.note}'}',
            ),
            const SizedBox(height: 4),
            Text(
              formatRupiah(entry.bowl.totalPrice),
              key: Key('cart-subtotal-${entry.id}'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton.filledTonal(
                  key: Key('cart-decrease-${entry.id}'),
                  tooltip: 'Kurangi',
                  onPressed: onDecrease,
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '${entry.bowl.quantity}',
                    key: Key('cart-quantity-${entry.id}'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton.filledTonal(
                  key: Key('cart-increase-${entry.id}'),
                  tooltip: 'Tambah',
                  onPressed: onIncrease,
                  icon: const Icon(Icons.add),
                ),
                const Spacer(),
                IconButton(
                  key: Key('cart-remove-${entry.id}'),
                  tooltip: 'Hapus',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartEmpty extends StatelessWidget {
  const _CartEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Keranjang masih kosong',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Racik bowl favorit Anda, lalu kelola jumlahnya di sini.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
