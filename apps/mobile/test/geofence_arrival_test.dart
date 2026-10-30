import 'package:donburix/features/bowl_builder/data/demo_bowl_repository.dart';
import 'package:donburix/features/bowl_builder/domain/bowl_models.dart';
import 'package:donburix/features/orders/domain/geofence.dart';
import 'package:donburix/features/orders/domain/order_models.dart';
import 'package:flutter_test/flutter_test.dart';

CheckoutDraft _checkout(OrderType type) => CheckoutDraft(
  customerName: 'Budi',
  type: type,
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

void main() {
  test('P7 geofence AC1: jarak haversine mendekati nilai nyata', () {
    // 0,001 derajat lintang ~ 111 meter.
    const a = GeoPoint(-6.2000, 106.8166);
    const b = GeoPoint(-6.2010, 106.8166);
    expect(Geofence.distanceMeters(a, b), closeTo(111, 2));
    expect(Geofence.distanceMeters(a, a), 0);
  });

  test('P7 geofence AC2: radius 500 m menentukan di dalam/luar', () {
    expect(Geofence.contains(Geofence.store), isTrue);
    expect(Geofence.contains(Geofence.demoNearby), isTrue);
    expect(Geofence.contains(Geofence.demoFar), isFalse);
  });

  test('P7 geofence AC3: tiba di radius memicu status Disiapkan', () async {
    final repository = DemoBowlRepository();
    final order = await repository.createOrder(_checkout(OrderType.takeaway));

    final arrived = await repository.markArrived(order.id, Geofence.demoNearby);

    expect(arrived.arrived, isTrue);
    expect(arrived.status, OrderStatus.preparing);
  });

  test('P7 geofence AC4: di luar radius ditolak, status tetap', () async {
    final repository = DemoBowlRepository();
    final order = await repository.createOrder(_checkout(OrderType.takeaway));

    await expectLater(
      repository.markArrived(order.id, Geofence.demoFar),
      throwsA(
        isA<OrderFailure>().having(
          (error) => error.message,
          'message',
          contains('dari gerai'),
        ),
      ),
    );
    final current = (await repository.latestOrders()).single;
    expect(current.arrived, isFalse);
    expect(current.status, OrderStatus.placed);
  });

  test(
    'P7 geofence AC5: dine-in dan pesanan batal tidak memakai geofence',
    () async {
      final repository = DemoBowlRepository();
      final dineIn = await repository.createOrder(_checkout(OrderType.dineIn));
      await expectLater(
        repository.markArrived(dineIn.id, Geofence.demoNearby),
        throwsA(isA<OrderFailure>()),
      );

      final takeaway = await repository.createOrder(
        _checkout(OrderType.takeaway),
      );
      await repository.cancelOrder(takeaway.id);
      await expectLater(
        repository.markArrived(takeaway.id, Geofence.demoNearby),
        throwsA(isA<OrderFailure>()),
      );
    },
  );
}
