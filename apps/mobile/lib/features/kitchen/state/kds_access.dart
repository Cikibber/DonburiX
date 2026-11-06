import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security_log.dart';

/// PIN staf dapur saat build. Kosong = layar dapur selalu terkunci.
final kdsPinProvider = Provider<String>(
  (ref) => const String.fromEnvironment('KDS_PIN'),
);

final kdsClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class KdsAccess {
  const KdsAccess({this.unlocked = false, this.failures = 0, this.lockedUntil});

  final bool unlocked;
  final int failures;
  final DateTime? lockedUntil;
}

final kdsAccessProvider = NotifierProvider<KdsAccessNotifier, KdsAccess>(
  KdsAccessNotifier.new,
);

// ponytail: PIN ikut terkompilasi di klien dan hitungan hilang saat reload,
// jadi ini pembatas demo. Backend harus memeriksa peran staf di server.
class KdsAccessNotifier extends Notifier<KdsAccess> {
  static const maxAttempts = 5;
  static const lockout = Duration(minutes: 1);

  @override
  KdsAccess build() => const KdsAccess();

  /// Mengembalikan pesan error, atau null bila berhasil.
  String? unlock(String pin) {
    final expected = ref.read(kdsPinProvider);
    if (expected.isEmpty) {
      logSecurityEvent('kds.not_configured');
      return 'Layar dapur belum dikonfigurasi (KDS_PIN).';
    }
    final now = ref.read(kdsClockProvider)();
    final until = state.lockedUntil;
    if (until != null && now.isBefore(until)) {
      logSecurityEvent('kds.pin_blocked');
      return 'Terlalu banyak percobaan. Coba lagi dalam 1 menit.';
    }
    if (pin == expected) {
      logSecurityEvent('kds.unlocked', level: 'info');
      state = const KdsAccess(unlocked: true);
      return null;
    }
    final failures = state.failures + 1;
    if (failures >= maxAttempts) {
      logSecurityEvent('kds.locked_out', fields: {'attempts': failures});
      state = KdsAccess(lockedUntil: now.add(lockout));
      return 'Terlalu banyak percobaan. Coba lagi dalam 1 menit.';
    }
    logSecurityEvent('kds.pin_denied', fields: {'attempt': failures});
    state = KdsAccess(failures: failures);
    return 'PIN salah.';
  }

  /// Hitungan gagal tetap ada agar keluar-masuk tidak melewati penguncian.
  void lock() => state = KdsAccess(
    failures: state.failures,
    lockedUntil: state.lockedUntil,
  );
}
