import 'package:donburix/app.dart';
import 'package:donburix/features/bowl_builder/data/demo_bowl_repository.dart';
import 'package:donburix/features/bowl_builder/domain/bowl_models.dart';
import 'package:donburix/features/bowl_builder/state/bowl_providers.dart';
import 'package:donburix/features/orders/domain/geofence.dart';
import 'package:donburix/features/orders/domain/order_models.dart';
import 'package:donburix/features/orders/state/order_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

Future<void> _mount(
  WidgetTester tester,
  DemoBowlRepository repository, {
  GeoPoint location = Geofence.demoNearby,
}) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        signedIn,
        bowlRepositoryProvider.overrideWithValue(repository),
        customerLocationProvider.overrideWithValue(location),
      ],
      child: const DonburiXApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('P7 KDS AC1: dapur melihat antrean dan memajukan status', (
    tester,
  ) async {
    final repository = DemoBowlRepository();
    final order = (await tester.runAsync(
      () => repository.createOrder(_checkout()),
    ))!;
    await _mount(tester, repository);

    await _tab(tester, 'Dapur');
    expect(find.text(order.displayId), findsOneWidget);
    await tester.tap(find.byKey(Key('kds-advance-${order.id}')));
    await tester.pumpAndSettle();

    expect(
      (await repository.latestOrders()).single.status,
      OrderStatus.preparing,
    );
    expect(find.text('Disiapkan'), findsWidgets);
  });

  testWidgets('P7 KDS AC2: restok bahan habis dari layar dapur', (
    tester,
  ) async {
    final repository = DemoBowlRepository();
    await _mount(tester, repository);

    await _tab(tester, 'Dapur');
    await tester.scrollUntilVisible(
      find.byKey(const Key('kds-restock-beef')),
      200,
    );
    await tester.tap(find.byKey(const Key('kds-restock-beef')));
    await tester.pumpAndSettle();

    final catalog = (await tester.runAsync(repository.loadIngredients))!;
    expect(catalog.firstWhere((item) => item.id == 'beef').availableStock, 5);
  });

  testWidgets('P7 geofence AC6: tombol Saya Sudah Tiba memicu persiapan', (
    tester,
  ) async {
    final repository = DemoBowlRepository();
    final order = (await tester.runAsync(
      () => repository.createOrder(_checkout()),
    ))!;
    await _mount(tester, repository);

    await _tab(tester, 'Pesanan');
    await tester.tap(find.text(order.displayId));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('arrival-button')));
    await tester.pumpAndSettle();

    expect(find.text('Status: Disiapkan'), findsOneWidget);
    expect(find.byKey(const Key('arrival-button')), findsNothing);
  });

  testWidgets('P7 geofence AC7: di luar radius tampil pesan, status tetap', (
    tester,
  ) async {
    final repository = DemoBowlRepository();
    final order = (await tester.runAsync(
      () => repository.createOrder(_checkout()),
    ))!;
    await _mount(tester, repository, location: Geofence.demoFar);

    await _tab(tester, 'Pesanan');
    await tester.tap(find.text(order.displayId));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('arrival-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('dari gerai'), findsOneWidget);
    expect(find.text('Status: Dipesan'), findsOneWidget);
  });

  testWidgets('P7 riwayat AC1: pelanggan hanya melihat pesanannya sendiri', (
    tester,
  ) async {
    final repository = DemoBowlRepository();
    final mine = (await tester.runAsync(
      () => repository.createOrder(_checkout()),
    ))!;
    final other = (await tester.runAsync(
      () => repository.createOrder(
        _checkout(name: 'Sari', email: 'sari@mail.com'),
      ),
    ))!;
    await _mount(tester, repository);

    await _tab(tester, 'Pesanan');
    expect(find.text(mine.displayId), findsOneWidget);
    expect(find.text(other.displayId), findsNothing);
  });
}
