// Regresi untuk bug yang ditemukan setelah deployment (Tugas 10).
// Nomor di nama test adalah nomor GitHub Issue.
import 'dart:convert';

import 'package:donburix/features/bowl_builder/data/demo_bowl_repository.dart';
import 'package:donburix/features/bowl_builder/domain/bowl_models.dart';
import 'package:donburix/features/kitchen/state/kds_access.dart';
import 'package:donburix/features/orders/domain/order_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'order_checkout_test.dart' as flow;

CheckoutDraft _checkout() => CheckoutDraft(
  customerName: 'Budi',
  customerEmail: 'budi@mail.com',
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
        quantity: 2,
        note: '',
      ),
    ),
  ],
);

int _stockOf(List<Ingredient> catalog, String id) =>
    catalog.firstWhere((item) => item.id == id).availableStock;

Future<void> _placeOrder(WidgetTester tester) async {
  await flow.addBowlToCart(tester);
  await flow.openCart(tester);
  await flow.openCheckout(tester);
  await tester.enterText(find.byKey(const Key('customer-name-input')), 'Budi');
  await tester.tap(find.byKey(const Key('checkout-submit')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('#3 dua tab berbagi penyimpanan', () {
    test('tab lain tidak menimpa pesanan, stok, dan nomor urut', () async {
      final prefs = await SharedPreferences.getInstance();
      final customerTab = DemoBowlRepository(prefs: prefs);
      final kitchenTab = DemoBowlRepository(prefs: prefs);

      final order = await customerTab.createOrder(_checkout());
      await kitchenTab.restock('rice', 5);

      final reopened = DemoBowlRepository(prefs: prefs);
      final orders = await reopened.latestOrders();
      expect(orders.map((item) => item.displayId), [order.displayId]);
      expect(_stockOf(await reopened.loadIngredients(), 'rice'), 20 - 2 + 5);

      final next = await kitchenTab.createOrder(_checkout());
      expect(next.displayId, endsWith('-002'));
      expect(next.id, isNot(order.id));
    });

    test('antrean dan stok tab lain ter-update saat sinkronisasi', () async {
      final prefs = await SharedPreferences.getInstance();
      final customerTab = DemoBowlRepository(prefs: prefs);
      final kitchenTab = DemoBowlRepository(prefs: prefs);
      addTearDown(customerTab.dispose);
      addTearDown(kitchenTab.dispose);
      final queueSizes = <int>[];
      var stockEvents = 0;
      kitchenTab.watchOrders().listen(
        (orders) => queueSizes.add(orders.length),
      );
      kitchenTab.stockChanges.listen((_) => stockEvents++);

      await customerTab.createOrder(_checkout());
      await kitchenTab.syncFromStorage();
      await pumpEventQueue();

      expect(queueSizes.last, 1);
      expect(stockEvents, 1);

      // Tanpa perubahan, sinkronisasi berikutnya tidak memicu apa pun.
      await kitchenTab.syncFromStorage();
      await pumpEventQueue();
      expect(stockEvents, 1);
    });

    test('dapur di tab lain bisa memajukan pesanan baru', () async {
      final prefs = await SharedPreferences.getInstance();
      final customerTab = DemoBowlRepository(prefs: prefs);
      final kitchenTab = DemoBowlRepository(prefs: prefs);

      final order = await customerTab.createOrder(_checkout());
      final advanced = await kitchenTab.advanceStatus(order.id);

      expect(advanced.status, OrderStatus.preparing);
    });
  });

  test('#12 pesanan ke-1000 ditolak sebelum stok dipotong', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      DemoBowlRepository.storageKey: jsonEncode({
        'orders': <Object>[],
        'stock': <String, int>{},
        'sequenceDay': '${now.year}-${now.month}-${now.day}',
        'dailySequence': 999,
      }),
    });
    final repository = DemoBowlRepository(
      prefs: await SharedPreferences.getInstance(),
    );

    await expectLater(
      repository.createOrder(_checkout()),
      throwsA(
        isA<OrderFailure>().having(
          (error) => error.message,
          'message',
          contains('999'),
        ),
      ),
    );
    expect(_stockOf(await repository.loadIngredients(), 'chicken'), 12);
  });

  test('#14 pesan penguncian menampilkan sisa waktu', () {
    var now = DateTime(2026, 11, 12, 10);
    final container = ProviderContainer(
      overrides: [
        kdsPinProvider.overrideWithValue('4826'),
        kdsClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(kdsAccessProvider.notifier);
    for (var i = 0; i < KdsAccessNotifier.maxAttempts; i++) {
      notifier.unlock('0000');
    }

    now = now.add(const Duration(seconds: 50));

    expect(notifier.unlock('4826'), contains('10 detik'));
  });

  testWidgets('#4 lebar konten dibatasi di layar desktop', (tester) async {
    await flow.mountDemo(tester);
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(NavigationBar)).width,
      lessThanOrEqualTo(720),
    );
  });

  testWidgets('#5 Lacak Pesanan kembali ke tab Pesanan dengan navigasi', (
    tester,
  ) async {
    await flow.mountDemo(tester);
    await _placeOrder(tester);

    await tester.tap(find.byKey(const Key('order-success-track')));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar).hitTestable(), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.textContaining('DX-'), findsOneWidget);
  });

  testWidgets('#6 pembatalan meminta konfirmasi', (tester) async {
    await flow.mountDemo(tester);
    await _placeOrder(tester);
    await tester.tap(find.byKey(const Key('order-success-track')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('DX-'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cancel-order-button')));
    await tester.pumpAndSettle();
    expect(find.text('Status: Dipesan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cancel-dismiss')));
    await tester.pumpAndSettle();
    expect(find.text('Status: Dipesan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cancel-order-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cancel-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Status: Dibatalkan'), findsOneWidget);
  });

  testWidgets('#7 tombol kurangi nonaktif pada 1 porsi', (tester) async {
    await flow.mountDemo(tester);
    await flow.addBowlToCart(tester);
    await flow.openCart(tester);

    final decrease = tester.widget<IconButton>(
      find.byKey(const Key('cart-decrease-local-1')),
    );
    expect(decrease.onPressed, isNull);
    expect(find.byKey(const Key('cart-error')), findsNothing);
  });

  testWidgets('#8 nama pemesan terisi dari akun', (tester) async {
    await flow.mountDemo(tester);
    await flow.addBowlToCart(tester);
    await flow.openCart(tester);
    await flow.openCheckout(tester);

    expect(
      find.descendant(
        of: find.byKey(const Key('customer-name-input')),
        matching: find.text('Budi'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('checkout-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-success')), findsOneWidget);
  });

  testWidgets('#13 dan #15 detail: garis tahapan dan jam pemesanan', (
    tester,
  ) async {
    await flow.mountDemo(tester);
    await _placeOrder(tester);
    await tester.tap(find.byKey(const Key('order-success-track')));
    await tester.pumpAndSettle();

    final time = RegExp(r'\d{2}/\d{2} \d{2}:\d{2}');
    expect(find.textContaining(time), findsOneWidget);

    await tester.tap(find.textContaining('DX-'));
    await tester.pumpAndSettle();

    expect(find.text('│'), findsNothing);
    expect(find.byKey(const Key('timeline-line-placed')), findsOneWidget);
    expect(find.byKey(const Key('order-time')), findsOneWidget);
  });
}
