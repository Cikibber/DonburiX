import 'package:donburix/features/auth/domain/customer.dart';
import 'package:donburix/features/auth/state/session_provider.dart';

const testCustomer = Customer(name: 'Budi', email: 'budi@mail.com');

class SignedInSession extends SessionNotifier {
  @override
  Customer? build() => testCustomer;
}

/// Override sesi agar widget test langsung masuk ke aplikasi.
final signedIn = sessionProvider.overrideWith(SignedInSession.new);
