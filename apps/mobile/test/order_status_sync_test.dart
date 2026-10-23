import 'package:donburix/features/bowl_builder/data/demo_bowl_repository.dart';
import 'package:donburix/features/bowl_builder/domain/bowl_models.dart';
import 'package:donburix/features/orders/domain/order_models.dart';
import 'package:donburix/features/orders/domain/order_rules.dart';
import 'package:flutter_test/flutter_test.dart';

CheckoutDraft _checkout({String name = 'Budi'}) => CheckoutDraft(
  customerName: name,
  type: OrderType.dineIn,
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
  test('US4 AC1: status hanya boleh maju satu langkah', () {
    expect(
      OrderStatusFlow.canAdvanceTo(OrderStatus.placed, OrderStatus.preparing),
      isTrue,
    );
    expect(
      OrderStatusFlow.canAdvanceTo(OrderStatus.preparing, OrderStatus.placed),
      isFalse,
    );
    expect(
      OrderStatusFlow.canAdvanceTo(OrderStatus.placed, OrderStatus.ready),
      isFalse,
    );
    expect(OrderStatusFlow.next(OrderStatus.completed), isNull);
  });

  test(
    'US4 AC2: pelanggan menerima perubahan status di bawah 2 detik',
    () async {
      final repository = DemoBowlRepository();
      final order = await repository.createOrder(_checkout());

      final events = <Order>[];
      final subscription = repository.watchOrder(order.id).listen(events.add);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(events.single.status, OrderStatus.placed);

      final watch = Stopwatch()..start();
      final updated = await repository.advanceStatus(order.id);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      watch.stop();

      expect(updated.status, OrderStatus.preparing);
      expect(events.last.status, OrderStatus.preparing);
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      await subscription.cancel();
    },
  );

  test('US4 AC3: status selesai bersifat terminal', () async {
    final repository = DemoBowlRepository();
    final order = await repository.createOrder(_checkout());

    await repository.advanceStatus(order.id);
    await repository.advanceStatus(order.id);
    final completed = await repository.advanceStatus(order.id);

    expect(completed.status, OrderStatus.completed);
    await expectLater(
      repository.advanceStatus(order.id),
      throwsA(isA<OrderFailure>()),
    );
  });

  test(
    'US4 AC4: pesanan yang dibatalkan tidak bisa dilanjutkan dapur',
    () async {
      final repository = DemoBowlRepository();
      final order = await repository.createOrder(_checkout());
      await repository.cancelOrder(order.id);

      await expectLater(
        repository.advanceStatus(order.id),
        throwsA(isA<OrderFailure>()),
      );
    },
  );
}
