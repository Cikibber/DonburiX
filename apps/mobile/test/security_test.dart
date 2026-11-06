import 'dart:convert';

import 'package:donburix/app.dart';
import 'package:donburix/core/preferences.dart';
import 'package:donburix/features/auth/domain/customer.dart';
import 'package:donburix/features/auth/state/session_provider.dart';
import 'package:donburix/features/bowl_builder/data/demo_bowl_repository.dart';
import 'package:donburix/features/bowl_builder/domain/bowl_models.dart';
import 'package:donburix/features/bowl_builder/state/bowl_providers.dart';
import 'package:donburix/features/kitchen/state/kds_access.dart';
import 'package:donburix/features/orders/domain/geofence.dart';
import 'package:donburix/features/orders/domain/order_models.dart';
import 'package:donburix/main.dart' show demoQuery;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_support.dart';

CheckoutDraft _checkout({
  String name = 'Budi',
  String email = 'budi@mail.com',
}) => CheckoutDraft(
  customerName: name,
  customerEmail: email,
  type: OrderType.takeaway,
  items: [
    CartEntry(
      id: 'entry-1',
      bowl: BowlDraft(
        ingredients: demoIngredients
            .where(
              (item) =>
                  ['rice', 'chicken', 'teriyaki', 'egg'].contains(item.id),
            )
            .toList(),
        quantity: 1,
        note: '',
      ),
    ),
  ],
);

int _stockOf(List<Ingredient> catalog, String id) =>
    catalog.firstWhere((item) => item.id == id).availableStock;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SEC-01 geofence', () {
    for (final (label, point) in [
      ('lintang NaN', const GeoPoint(double.nan, 106.8166)),
      ('bujur tak hingga', const GeoPoint(-6.2, double.infinity)),
      ('lintang di luar rentang (+360)', const GeoPoint(353.8, 106.8166)),
      ('bujur di luar rentang (+360)', const GeoPoint(-6.2, 466.8166)),
    ]) {
      test('$label ditolak dan status tetap', () async {
        final repository = DemoBowlRepository();
        final order = await repository.createOrder(_checkout());

        await expectLater(
          repository.markArrived(order.id, point),
          throwsA(
            isA<OrderFailure>().having(
              (error) => error.message,
              'message',
              'Lokasi tidak valid.',
            ),
          ),
        );

        final current = (await repository.latestOrders()).single;
        expect(current.arrived, isFalse);
        expect(current.status, OrderStatus.placed);
      });
    }
  });

  group('SEC-04 data tersimpan yang dimanipulasi', () {
    Future<DemoBowlRepository> reopenWith(Map<String, Object?> json) async {
      SharedPreferences.setMockInitialValues({
        DemoBowlRepository.storageKey: jsonEncode(json),
      });
      return DemoBowlRepository(prefs: await SharedPreferences.getInstance());
    }

    test('stok negatif tidak diterima', () async {
      final repository = await reopenWith({
        'orders': <Object?>[],
        'stock': {'chicken': -5},
        'dailySequence': 0,
      });
      expect(_stockOf(await repository.loadIngredients(), 'chicken'), 12);
    });

    test('stok rusak sebagian tidak diterapkan sebagian', () async {
      final repository = await reopenWith({
        'orders': <Object?>[],
        'stock': {'chicken': 999, 'beef': 'banyak'},
        'dailySequence': 0,
      });
      expect(_stockOf(await repository.loadIngredients(), 'chicken'), 12);
    });

    test('nomor urut negatif tidak diterima', () async {
      final repository = await reopenWith({
        'orders': <Object?>[],
        'stock': <String, Object?>{},
        'sequenceDay': _todayKey(),
        'dailySequence': -7,
      });
      final order = await repository.createOrder(_checkout());
      expect(order.displayId, endsWith('-001'));
    });

    for (final (label, session) in [
      ('email tidak valid', {'name': 'Budi', 'email': 'bukan-email'}),
      ('nama kosong', {'name': '  ', 'email': 'budi@mail.com'}),
      ('nama terlalu panjang', {'name': 'x' * 41, 'email': 'budi@mail.com'}),
    ]) {
      test('sesi dengan $label dianggap belum masuk', () async {
        SharedPreferences.setMockInitialValues({
          SessionNotifier.storageKey: jsonEncode(session),
        });
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        expect(container.read(sessionProvider), isNull);
      });
    }
  });

  group('SEC-05 batas panjang input', () {
    test('nama pemesan lebih dari 40 karakter ditolak repository', () async {
      await expectLater(
        DemoBowlRepository().createOrder(_checkout(name: 'x' * 41)),
        throwsA(isA<OrderFailure>()),
      );
    });

    test('nama pemesan 40 karakter diterima', () async {
      final order = await DemoBowlRepository().createOrder(
        _checkout(name: 'x' * 40),
      );
      expect(order.customerName, hasLength(40));
    });

    test('validator form menolak nama pemesan terlalu panjang', () {
      expect(validateCustomerName('x' * 41), isNotNull);
      expect(validateCustomerName('x' * 40), isNull);
    });

    test('email lebih dari 254 karakter ditolak', () {
      final local = 'a' * 250;
      expect(Customer.validateEmail('$local@mail.com'), isNotNull);
    });
  });

  group('SEC-02 kepemilikan pesanan', () {
    const other = 'sari@mail.com';

    test('pesanan milik orang lain tidak bisa dibatalkan', () async {
      final repository = DemoBowlRepository();
      final order = await repository.createOrder(_checkout());
      final stockAfterOrder = _stockOf(
        await repository.loadIngredients(),
        'chicken',
      );

      await expectLater(
        repository.cancelOrder(order.id, actorEmail: other),
        throwsA(
          isA<OrderFailure>().having(
            (error) => error.message,
            'message',
            'Pesanan tidak ditemukan.',
          ),
        ),
      );

      expect((await repository.latestOrders()).single.cancelled, isFalse);
      expect(
        _stockOf(await repository.loadIngredients(), 'chicken'),
        stockAfterOrder,
      );
    });

    test('pesanan milik orang lain tidak bisa ditandai tiba', () async {
      final repository = DemoBowlRepository();
      final order = await repository.createOrder(_checkout());

      await expectLater(
        repository.markArrived(
          order.id,
          Geofence.demoNearby,
          actorEmail: other,
        ),
        throwsA(isA<OrderFailure>()),
      );
      expect((await repository.latestOrders()).single.arrived, isFalse);
    });

    test('pencarian nomor pesanan tidak membuka pesanan orang lain', () async {
      final repository = DemoBowlRepository();
      final order = await repository.createOrder(_checkout());

      expect(
        await repository.findByDisplayId(order.displayId, actorEmail: other),
        isNull,
      );
      expect(
        (await repository.findByDisplayId(
          order.displayId,
          actorEmail: 'budi@mail.com',
        ))?.id,
        order.id,
      );
    });

    test('pemilik tetap bisa membatalkan dan menandai tiba', () async {
      final repository = DemoBowlRepository();
      final first = await repository.createOrder(_checkout());
      final second = await repository.createOrder(_checkout());

      final cancelled = await repository.cancelOrder(
        first.id,
        actorEmail: 'budi@mail.com',
      );
      final arrived = await repository.markArrived(
        second.id,
        Geofence.demoNearby,
        actorEmail: 'budi@mail.com',
      );

      expect(cancelled.cancelled, isTrue);
      expect(arrived.arrived, isTrue);
    });

    testWidgets('layar Pesanan menolak pencarian pesanan orang lain', (
      tester,
    ) async {
      final repository = DemoBowlRepository();
      final foreign = (await tester.runAsync(
        () => repository.createOrder(_checkout(email: other)),
      ))!;
      (await tester.runAsync(() => repository.createOrder(_checkout())))!;
      await _mountApp(tester, repository);

      await tester.tap(find.text('Pesanan').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('order-lookup-input')),
        foreign.displayId,
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.textContaining('tidak ditemukan'), findsOneWidget);
      expect(find.byKey(const Key('order-status')), findsNothing);
    });
  });

  group('SEC-03 gerbang PIN dapur', () {
    ProviderContainer container({
      String pin = '4826',
      DateTime Function()? clock,
    }) {
      final result = ProviderContainer(
        overrides: [
          kdsPinProvider.overrideWithValue(pin),
          if (clock != null) kdsClockProvider.overrideWithValue(clock),
        ],
      );
      addTearDown(result.dispose);
      return result;
    }

    test('PIN salah ditolak, PIN benar membuka', () {
      final kds = container();
      final notifier = kds.read(kdsAccessProvider.notifier);

      expect(notifier.unlock('0000'), isNotNull);
      expect(kds.read(kdsAccessProvider).unlocked, isFalse);
      expect(notifier.unlock('4826'), isNull);
      expect(kds.read(kdsAccessProvider).unlocked, isTrue);
    });

    test('tanpa KDS_PIN layar dapur selalu terkunci', () {
      final kds = container(pin: '');

      expect(kds.read(kdsAccessProvider.notifier).unlock(''), isNotNull);
      expect(kds.read(kdsAccessProvider).unlocked, isFalse);
    });

    test('lima kali salah mengunci sementara, lalu terbuka lagi', () {
      var now = DateTime(2026, 11, 6, 10);
      final kds = container(clock: () => now);
      final notifier = kds.read(kdsAccessProvider.notifier);

      for (var i = 0; i < KdsAccessNotifier.maxAttempts; i++) {
        notifier.unlock('0000');
      }
      // PIN benar pun ditolak selama penguncian.
      expect(notifier.unlock('4826'), contains('Terlalu banyak'));
      expect(kds.read(kdsAccessProvider).unlocked, isFalse);

      now = now.add(KdsAccessNotifier.lockout);
      expect(notifier.unlock('4826'), isNull);
      expect(kds.read(kdsAccessProvider).unlocked, isTrue);
    });

    test('mengunci ulang tidak menghapus hitungan penguncian', () {
      final now = DateTime(2026, 11, 6, 10);
      final kds = container(clock: () => now);
      final notifier = kds.read(kdsAccessProvider.notifier);

      for (var i = 0; i < KdsAccessNotifier.maxAttempts; i++) {
        notifier.unlock('0000');
      }
      notifier.lock();

      expect(notifier.unlock('4826'), contains('Terlalu banyak'));
    });

    testWidgets('antrean tidak tampil sebelum PIN benar', (tester) async {
      final repository = DemoBowlRepository();
      final order = (await tester.runAsync(
        () => repository.createOrder(_checkout()),
      ))!;
      await _mountApp(tester, repository);

      await tester.tap(find.text('Dapur').last);
      await tester.pumpAndSettle();
      expect(find.byKey(Key('kds-order-${order.id}')), findsNothing);
      expect(find.byKey(const Key('kds-restock-beef')), findsNothing);

      await tester.enterText(find.byKey(const Key('kds-pin')), '0000');
      await tester.tap(find.byKey(const Key('kds-unlock')));
      await tester.pumpAndSettle();
      expect(find.textContaining('PIN salah'), findsOneWidget);
      expect(find.byKey(Key('kds-order-${order.id}')), findsNothing);

      await tester.enterText(find.byKey(const Key('kds-pin')), '4826');
      await tester.tap(find.byKey(const Key('kds-unlock')));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('kds-order-${order.id}')), findsOneWidget);

      await tester.tap(find.byKey(const Key('kds-lock')));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('kds-order-${order.id}')), findsNothing);
    });
  });

  group('SEC-06 hook demo URL', () {
    final uri = Uri.parse('https://x.test/?scenario=orders-error&location=far');

    test('diabaikan pada build release', () {
      expect(demoQuery(uri, release: true), isEmpty);
    });

    test('tetap aktif di luar release untuk demo lokal', () {
      expect(demoQuery(uri, release: false)['scenario'], 'orders-error');
    });
  });

  group('SEC-07 log keamanan', () {
    List<Map<String, Object?>> captureLogs() {
      final logs = <Map<String, Object?>>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        logs.add(jsonDecode(message!) as Map<String, Object?>);
      };
      addTearDown(() => debugPrint = original);
      return logs;
    }

    test('akses ditolak tercatat tanpa email pelanggan', () async {
      final logs = captureLogs();
      final repository = DemoBowlRepository();
      final order = await repository.createOrder(_checkout());

      await expectLater(
        repository.cancelOrder(order.id, actorEmail: 'sari@mail.com'),
        throwsA(isA<OrderFailure>()),
      );

      expect(logs.single['event'], 'order.access_denied');
      expect(logs.single['action'], 'cancel');
      expect(logs.single['order'], order.displayId);
      expect(logs.single['ts'], isA<String>());
      expect(jsonEncode(logs), isNot(contains('@')));
    });

    test('lokasi di luar radius tercatat tanpa koordinat', () async {
      final logs = captureLogs();
      final repository = DemoBowlRepository();
      final order = await repository.createOrder(_checkout());

      await expectLater(
        repository.markArrived(order.id, Geofence.demoFar),
        throwsA(isA<OrderFailure>()),
      );

      expect(logs.single['event'], 'geofence.rejected');
      expect(logs.single['reason'], 'outside_radius');
      expect(jsonEncode(logs), isNot(contains('106.8')));
    });

    test('data rusak dan PIN salah tercatat tanpa isi data', () async {
      final logs = captureLogs();
      SharedPreferences.setMockInitialValues({
        DemoBowlRepository.storageKey: '{"rahasia@mail.com"',
      });
      DemoBowlRepository(prefs: await SharedPreferences.getInstance());
      final kds = ProviderContainer(
        overrides: [kdsPinProvider.overrideWithValue('4826')],
      );
      addTearDown(kds.dispose);
      kds.read(kdsAccessProvider.notifier).unlock('9999');

      expect(logs.map((log) => log['event']), [
        'storage.corrupt_reset',
        'kds.pin_denied',
      ]);
      expect(logs.first['cause'], 'invalid_format');
      expect(jsonEncode(logs), isNot(contains('rahasia')));
      expect(jsonEncode(logs), isNot(contains('9999')));
    });

    test('login ditolak mencatat field, bukan nilainya', () {
      final logs = captureLogs();
      final session = ProviderContainer();
      addTearDown(session.dispose);

      session
          .read(sessionProvider.notifier)
          .login(name: 'Budi', email: 'salah-format');

      expect(logs.single['event'], 'auth.login_rejected');
      expect(logs.single['field'], 'email');
      expect(jsonEncode(logs), isNot(contains('salah-format')));
    });

    testWidgets('layar login mencatat penolakan dan tetap menampilkan pesan', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: DonburiXApp()));
      await tester.enterText(find.byKey(const Key('login-name')), 'Budi');
      await tester.enterText(find.byKey(const Key('login-email')), 'budi');

      final lines = <String>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) => lines.add(message!);
      try {
        await tester.tap(find.byKey(const Key('login-submit')));
        await tester.pump();
      } finally {
        debugPrint = original;
      }

      expect(find.text('Format email tidak valid.'), findsOneWidget);
      expect(lines.single, contains('auth.login_rejected'));
      expect(lines.single, isNot(contains('budi')));
    });
  });
}

Future<void> _mountApp(
  WidgetTester tester,
  DemoBowlRepository repository,
) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        signedIn,
        bowlRepositoryProvider.overrideWithValue(repository),
        kdsPinProvider.overrideWithValue('4826'),
      ],
      child: const DonburiXApp(),
    ),
  );
  await tester.pumpAndSettle();
}

String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}
