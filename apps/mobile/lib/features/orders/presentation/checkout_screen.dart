import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bowl_builder/domain/bowl_models.dart';
import '../../bowl_builder/state/bowl_providers.dart';
import '../domain/order_models.dart';
import '../state/order_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(checkoutFormProvider);
    final cart = ref.watch(bowlBuilderProvider).cart;
    final total = ref.watch(cartTotalProvider);
    final notifier = ref.read(checkoutFormProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(
            'Ringkasan pesanan',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final entry in cart)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                entry.bowl.ingredients.map((item) => item.name).join(' · '),
              ),
              subtitle: Text('${entry.bowl.quantity} porsi'),
              trailing: Text(formatRupiah(entry.bowl.totalPrice)),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Total bayar (simulasi)')),
              Text(
                formatRupiah(total),
                key: const Key('checkout-total'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: const Key('customer-name-input'),
                  initialValue: form.customerName,
                  enabled: !form.isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Nama pemesan',
                    helperText: 'Dipakai staf dapur untuk memanggil pesanan',
                  ),
                  validator: validateCustomerName,
                  onChanged: notifier.setCustomerName,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tipe pesanan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                RadioGroup<OrderType>(
                  groupValue: form.type,
                  onChanged: (value) {
                    if (!form.isSubmitting && value != null) {
                      notifier.setType(value);
                    }
                  },
                  child: Column(
                    children: [
                      for (final type in OrderType.values)
                        RadioListTile<OrderType>(
                          key: Key('order-type-${type.name}'),
                          title: Text(type.label),
                          value: type,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1E6D6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.payments_outlined, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Simulasi pembayaran: tanpa transaksi bank riil.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (form.errorMessage != null)
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
                        form.errorMessage!,
                        key: const Key('checkout-error'),
                      ),
                    ),
                  ),
                FilledButton.icon(
                  key: const Key('checkout-submit'),
                  onPressed: form.isSubmitting
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            final order = await notifier.submit();
                            if (context.mounted && order != null) {
                              Navigator.of(context).pop(order);
                            }
                          }
                        },
                  icon: form.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            key: Key('checkout-loading'),
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.receipt_long_outlined),
                  label: Text(
                    form.isSubmitting ? 'Membuat pesanan…' : 'Buat Pesanan',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
