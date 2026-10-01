import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/bowl_models.dart';
import '../domain/bowl_validation.dart';
import '../state/bowl_providers.dart';
import 'widgets/feature_message.dart';
import 'widgets/ingredient_field.dart';

class BowlBuilderScreen extends ConsumerStatefulWidget {
  const BowlBuilderScreen({super.key});

  @override
  ConsumerState<BowlBuilderScreen> createState() => _BowlBuilderScreenState();
}

class _BowlBuilderScreenState extends ConsumerState<BowlBuilderScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(ingredientCatalogProvider);
    final builder = ref.watch(bowlBuilderProvider);
    final cartQuantity = builder.cart.fold(
      0,
      (sum, entry) => sum + entry.bowl.quantity,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9F1),
        title: const Text(
          'DONBURI X',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        actions: [
          TextButton.icon(
            key: const Key('cart-button'),
            onPressed: () => _showCart(context, builder.cart),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text('Keranjang ($cartQuantity)'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: catalog.when(
        skipLoadingOnRefresh: false,
        loading: () => const FeatureMessage(
          icon: Icons.rice_bowl,
          title: 'Menyiapkan pilihan bahan…',
          description: 'Sebentar, bowl favorit Anda segera bisa diracik.',
          isLoading: true,
        ),
        error: (error, stackTrace) => FeatureMessage(
          icon: Icons.cloud_off_outlined,
          title: 'Bahan belum dapat dimuat',
          description: error is BowlFailure
              ? error.message
              : 'Terjadi kendala. Silakan coba lagi.',
          actionLabel: 'Coba Lagi',
          onAction: () => ref.invalidate(ingredientCatalogProvider),
        ),
        data: (ingredients) => ingredients.isEmpty
            ? FeatureMessage(
                icon: Icons.rice_bowl_outlined,
                title: 'Belum ada pilihan bahan',
                description:
                    'Dapur belum menyediakan bahan untuk diracik. Periksa kembali nanti.',
                actionLabel: 'Muat Ulang',
                onAction: () => ref.invalidate(ingredientCatalogProvider),
              )
            : _buildForm(context, ingredients, builder),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    List<Ingredient> ingredients,
    BowlBuilderState builder,
  ) {
    final notifier = ref.read(bowlBuilderProvider.notifier);
    final total = ref.watch(bowlTotalProvider);
    final quantity = int.tryParse(builder.quantityText.trim()) ?? 1;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DIRACIK ANDA. DISIAPKAN SEGAR.',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bowl Anda,\nrasa Anda.',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pilih empat komponen favorit. Kami menyiapkannya ketika Anda tiba.',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1E6D6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.science_outlined, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Prototype tugas 4 · data lokal, belum terhubung ke dapur',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                for (final category in IngredientCategory.values) ...[
                  IngredientField(
                    category: category,
                    ingredients: ingredients,
                    selectedId: builder.selectedIds[category],
                    quantity: quantity,
                    enabled: !builder.isSubmitting,
                    onSelected: (id) => notifier.select(category, id),
                  ),
                  const SizedBox(height: 24),
                ],
                TextFormField(
                  key: const Key('quantity-input'),
                  initialValue: builder.quantityText,
                  enabled: !builder.isSubmitting,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah porsi',
                    helperText: '1–10 porsi per racikan',
                  ),
                  validator: BowlValidation.quantity,
                  onChanged: notifier.setQuantity,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('note-input'),
                  initialValue: builder.note,
                  enabled: !builder.isSubmitting,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan untuk dapur (opsional)',
                    helperText: 'Maksimal 120 karakter',
                  ),
                  validator: BowlValidation.note,
                  onChanged: notifier.setNote,
                ),
                const SizedBox(height: 24),
                if (builder.submitError != null)
                  _feedback(builder.submitError!, true),
                if (builder.successMessage != null)
                  _feedback(builder.successMessage!, false),
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
                          'Total racikan',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      Text(
                        formatRupiah(total),
                        key: const Key('bowl-total'),
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
                  key: const Key('submit-button'),
                  onPressed: builder.isSubmitting
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            notifier.submit();
                          }
                        },
                  icon: builder.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            key: Key('submit-loading'),
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.add_shopping_cart),
                  label: Text(
                    builder.isSubmitting
                        ? 'Menambahkan…'
                        : 'Tambahkan ke Keranjang',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Stok belum dipesan pada tahap keranjang. Validasi ulang dan reservasi dilakukan saat checkout.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _feedback(String message, bool isError) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isError ? const Color(0xFFFCE5DF) : const Color(0xFFE4EEDC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          key: Key(isError ? 'submit-error' : 'submit-success'),
        ),
      ),
    ),
  );

  void _showCart(BuildContext context, List<CartEntry> entries) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .7,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'Keranjang Anda',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                if (entries.isEmpty) const Text('Keranjang masih kosong.'),
                for (final entry in entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      entry.bowl.ingredients
                          .map((item) => item.name)
                          .join(' · '),
                    ),
                    subtitle: Text(
                      '${entry.bowl.quantity} porsi${entry.bowl.note.isEmpty ? '' : ' · ${entry.bowl.note}'}',
                    ),
                    trailing: Text(formatRupiah(entry.bowl.totalPrice)),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Keranjang lokal untuk demonstrasi. Muat ulang aplikasi akan menghapus isinya.',
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Lanjut Meracik'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
