import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences.dart';
import '../domain/customer.dart';

final sessionProvider = NotifierProvider<SessionNotifier, Customer?>(
  SessionNotifier.new,
);

/// Login pelanggan lokal (simulasi Firebase Auth, tanpa kata sandi).
class SessionNotifier extends Notifier<Customer?> {
  static const storageKey = 'donburix.session.v1';

  @override
  Customer? build() {
    final raw = ref.watch(sharedPreferencesProvider)?.getString(storageKey);
    if (raw == null) return null;
    try {
      return Customer.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return null;
    }
  }

  /// Mengembalikan pesan error, atau null bila berhasil.
  String? login({required String name, required String email}) {
    final error = Customer.validateName(name) ?? Customer.validateEmail(email);
    if (error != null) return error;
    final customer = Customer(
      name: name.trim(),
      email: email.trim().toLowerCase(),
    );
    ref
        .read(sharedPreferencesProvider)
        ?.setString(storageKey, jsonEncode(customer.toJson()));
    state = customer;
    return null;
  }

  void logout() {
    ref.read(sharedPreferencesProvider)?.remove(storageKey);
    state = null;
  }
}
