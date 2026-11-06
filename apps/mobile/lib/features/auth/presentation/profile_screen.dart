import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bowl_builder/state/bowl_providers.dart';
import '../../kitchen/state/kds_access.dart';
import '../../orders/state/order_providers.dart';
import '../state/session_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(sessionProvider);
    final orderCount = ref.watch(orderListProvider).value?.length ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(customer?.name ?? '-'),
            subtitle: Text(customer?.email ?? '-'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text('$orderCount pesanan tersimpan'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.location_on_outlined),
            title: Text('Izin lokasi'),
            subtitle: Text(
              'Lokasi dipakai sekali saat Anda menekan "Saya Sudah Tiba" '
              'agar dapur merakit bowl ketika Anda berada dalam 500 m.',
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            key: const Key('logout-button'),
            onPressed: () {
              // Keranjang dan form milik akun lama tidak ikut terbawa.
              ref.invalidate(bowlBuilderProvider);
              ref.invalidate(checkoutFormProvider);
              ref.read(kdsAccessProvider.notifier).lock();
              ref.read(sessionProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
