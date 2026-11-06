import 'package:donburix/features/auth/domain/customer.dart';
import 'package:donburix/features/auth/state/session_provider.dart';
import 'package:donburix/features/kitchen/state/kds_access.dart';

const testCustomer = Customer(name: 'Budi', email: 'budi@mail.com');

class SignedInSession extends SessionNotifier {
  @override
  Customer? build() => testCustomer;
}

/// Override sesi agar widget test langsung masuk ke aplikasi.
final signedIn = sessionProvider.overrideWith(SignedInSession.new);

class UnlockedKds extends KdsAccessNotifier {
  @override
  KdsAccess build() => const KdsAccess(unlocked: true);
}

/// Override gerbang PIN untuk test yang menguji isi layar dapur.
final kdsUnlocked = kdsAccessProvider.overrideWith(UnlockedKds.new);
