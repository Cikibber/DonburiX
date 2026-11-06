import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences.dart';
import '../../../core/security_log.dart';
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
      final customer = Customer.fromJson(
        jsonDecode(raw) as Map<String, Object?>,
      );
      if (Customer.validateName(customer.name) != null ||
          Customer.validateEmail(customer.email) != null) {
        throw const FormatException('Sesi tidak valid.');
      }
      return customer;
    } catch (error) {
      logSecurityEvent(
        'storage.corrupt_reset',
        fields: {
          'store': 'session',
          'cause': error is FormatException ? 'invalid_format' : 'invalid_type',
        },
      );
      return null;
    }
  }

  /// Mengembalikan pesan error, atau null bila berhasil.
  String? login({required String name, required String email}) {
    final nameError = Customer.validateName(name);
    final error = nameError ?? Customer.validateEmail(email);
    if (error != null) {
      logSecurityEvent(
        'auth.login_rejected',
        fields: {'field': nameError != null ? 'name' : 'email'},
      );
      return error;
    }
    final customer = Customer(
      name: name.trim(),
      email: email.trim().toLowerCase(),
    );
    ref
        .read(sharedPreferencesProvider)
        ?.setString(storageKey, jsonEncode(customer.toJson()));
    state = customer;
    logSecurityEvent('auth.login_ok', level: 'info');
    return null;
  }

  void logout() {
    ref.read(sharedPreferencesProvider)?.remove(storageKey);
    state = null;
    logSecurityEvent('auth.logout', level: 'info');
  }
}
