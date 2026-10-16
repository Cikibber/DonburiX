import 'package:donburix/app.dart';
import 'package:donburix/features/bowl_builder/data/demo_bowl_repository.dart';
import 'package:donburix/features/bowl_builder/domain/bowl_models.dart';
import 'package:donburix/features/bowl_builder/state/bowl_providers.dart';
import 'package:donburix/features/orders/domain/order_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bowl_builder_widget_test.dart' as shared;

Future<void> mountDemo(
  WidgetTester tester, {
  String scenario = 'success',
}) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bowlRepositoryProvider.overrideWithValue(
          DemoBowlRepository(scenario: scenario),
        ),
      ],
      child: const DonburiXApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> addBowlToCart(WidgetTester tester, {String quantity = '1'}) async {
  await shared.selectBowl(tester);
  if (quantity != '1') {
    await tester.enterText(find.byKey(const Key('quantity-input')), quantity);
  }
  await shared.submit(tester);
  await tester.pumpAndSettle();
}

Future<void> openCart(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('cart-button')));
  await tester.tap(find.byKey(const Key('cart-button')));
  await tester.pumpAndSettle();
}

Future<void> openCheckout(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('checkout-button')));
  await tester.pumpAndSettle();
}

Future<void> goOrdersTab(WidgetTester tester) async {
  await tester.tap(find.text('Pesanan'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AC1 checkout requires a customer name', (tester) async {
    await mountDemo(tester);
    await addBowlToCart(tester);
    await openCart(tester);
    await openCheckout(tester);

    await tester.tap(find.byKey(const Key('checkout-submit')));
    await tester.pump();

    expect(find.text('Nama pemesan wajib diisi.'), findsOneWidget);
    expect(find.byKey(const Key('order-success')), findsNothing);
  });

  testWidgets('AC2 order appears in history with number and status', (
    tester,
  ) async {
    await mountDemo(tester);
    await addBowlToCart(tester);
    await openCart(tester);
    await openCheckout(tester);

    await tester.enterText(
      find.byKey(const Key('customer-name-input')),
      'Budi',
    );
    await tester.tap(find.byKey(const Key('checkout-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('order-success')), findsOneWidget);
    await tester.tap(find.byKey(const Key('order-success-track')));
    await tester.pumpAndSettle();

    expect(find.textContaining('DX-'), findsOneWidget);
    expect(find.textContaining('Budi'), findsOneWidget);
    expect(find.text('Dipesan'), findsOneWidget);
    expect(find.text('Rp 25.000'), findsWidgets);
  });

  testWidgets('AC3 detail shows items, total, and status timeline', (
    tester,
  ) async {
    await mountDemo(tester);
    await addBowlToCart(tester);
    await openCart(tester);
    await openCheckout(tester);

    await tester.enterText(
      find.byKey(const Key('customer-name-input')),
      'Budi',
    );
    await tester.tap(find.byKey(const Key('checkout-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('order-success-track')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('DX-'));
    await tester.pumpAndSettle();

    expect(
      find.text('Nasi putih · Ayam teriyaki · Saus teriyaki · Telur'),
      findsOneWidget,
    );
    expect(find.textContaining('Rp 25.000'), findsWidgets);
    expect(find.text('Tahapan pesanan'), findsOneWidget);
    expect(find.byKey(const Key('timeline-placed')), findsOneWidget);
    expect(find.byKey(const Key('timeline-preparing')), findsOneWidget);
    expect(find.byKey(const Key('timeline-ready')), findsOneWidget);
    expect(find.byKey(const Key('timeline-completed')), findsOneWidget);
  });

  testWidgets('AC4 cart is emptied after successful checkout', (tester) async {
    await mountDemo(tester);
    await addBowlToCart(tester);
    await openCart(tester);
    await openCheckout(tester);

    await tester.enterText(
      find.byKey(const Key('customer-name-input')),
      'Budi',
    );
    await tester.tap(find.byKey(const Key('checkout-submit')));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Keranjang (0)'), findsOneWidget);
  });

  testWidgets('AC5 empty history shows the empty state', (tester) async {
    await mountDemo(tester, scenario: 'orders-empty');
    await goOrdersTab(tester);

    expect(find.text('Belum ada pesanan'), findsOneWidget);
    expect(find.textContaining('DX-'), findsNothing);
  });

  testWidgets('orders error shows retry without crashing', (tester) async {
    await mountDemo(tester, scenario: 'orders-error');
    await goOrdersTab(tester);

    expect(
      find.text('Riwayat pesanan belum dapat dimuat. Silakan coba lagi.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(
      find.text('Riwayat pesanan belum dapat dimuat. Silakan coba lagi.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkout failure keeps cart and allows retry', (tester) async {
    await mountDemo(tester, scenario: 'checkout-error');
    await addBowlToCart(tester);
    await openCart(tester);
    await openCheckout(tester);

    await tester.enterText(
      find.byKey(const Key('customer-name-input')),
      'Budi',
    );
    await tester.tap(find.byKey(const Key('checkout-submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('Pesanan belum tersimpan. Silakan coba lagi.'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Keranjang (1)'), findsOneWidget);
  });

  testWidgets('checkout guards against double submit', (tester) async {
    await mountDemo(tester);
    await addBowlToCart(tester);
    await openCart(tester);
    await openCheckout(tester);

    await tester.enterText(
      find.byKey(const Key('customer-name-input')),
      'Budi',
    );
    await tester.tap(find.byKey(const Key('checkout-submit')));
    await tester.tap(find.byKey(const Key('checkout-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('order-success')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Keranjang (0)'), findsOneWidget);
  });

  test('server revalidation recalculates price from the catalog', () async {
    final repository = DemoBowlRepository();
    final tampered = BowlDraft(
      ingredients: demoIngredients
          .where(
            (item) => ['rice', 'chicken', 'teriyaki', 'egg'].contains(item.id),
          )
          .map(
            (item) => Ingredient(
              id: item.id,
              name: item.name,
              category: item.category,
              price: 1,
              availableStock: 99,
            ),
          )
          .toList(),
      quantity: 1,
      note: '',
    );
    final order = await repository.createOrder(
      CheckoutDraft(
        customerName: 'Budi',
        type: OrderType.takeaway,
        items: [CartEntry(id: 'tampered', bowl: tampered)],
      ),
    );
    expect(order.totalPrice, 25000);
    expect(order.displayId, startsWith('DX-'));
  });
}
