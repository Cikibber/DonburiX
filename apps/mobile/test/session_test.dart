import 'package:donburix/app.dart';
import 'package:donburix/core/preferences.dart';
import 'package:donburix/features/auth/domain/customer.dart';
import 'package:donburix/features/auth/state/session_provider.dart';
import 'package:donburix/features/bowl_builder/data/demo_bowl_repository.dart';
import 'package:donburix/features/bowl_builder/state/bowl_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container() async {
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('P7 auth AC1: nama dan email divalidasi', () {
    expect(Customer.validateName(''), isNotNull);
    expect(Customer.validateName('  '), isNotNull);
    expect(Customer.validateName('A' * 41), isNotNull);
    expect(Customer.validateName('Budi'), isNull);
    expect(Customer.validateEmail(''), isNotNull);
    expect(Customer.validateEmail('budi'), isNotNull);
    expect(Customer.validateEmail('budi@mail'), isNotNull);
    expect(Customer.validateEmail('budi@mail.com'), isNull);
  });

  test('P7 auth AC2: login tersimpan dan bertahan, logout menghapus', () async {
    final container = await _container();
    final session = container.read(sessionProvider.notifier);

    expect(session.login(name: '', email: 'x'), isNotNull);
    expect(container.read(sessionProvider), isNull);

    expect(session.login(name: ' Budi ', email: 'BUDI@Mail.com '), isNull);
    expect(container.read(sessionProvider)?.name, 'Budi');
    expect(container.read(sessionProvider)?.email, 'budi@mail.com');

    final reopened = await _container();
    expect(reopened.read(sessionProvider)?.email, 'budi@mail.com');

    session.logout();
    expect(container.read(sessionProvider), isNull);
    final afterLogout = await _container();
    expect(afterLogout.read(sessionProvider), isNull);
  });

  testWidgets('P7 auth AC3: belum login tampil layar masuk, lalu ke builder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bowlRepositoryProvider.overrideWithValue(DemoBowlRepository()),
        ],
        child: const DonburiXApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(find.text('Nama wajib diisi.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login-name')), 'Budi');
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'budi@mail.com',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Bowl Anda,\nrasa Anda.'), findsOneWidget);
  });
}
