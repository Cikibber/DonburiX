import 'package:donburix/features/bowl_builder/data/demo_bowl_repository.dart';
import 'package:donburix/features/bowl_builder/domain/bowl_models.dart';
import 'package:donburix/features/orders/domain/order_models.dart';
import 'package:donburix/features/orders/domain/order_rules.dart';
import 'package:flutter_test/flutter_test.dart';

BowlDraft _bowl(int quantity) => BowlDraft(
  ingredients: demoIngredients
      .where((item) => ['rice', 'chicken', 'teriyaki', 'egg'].contains(item.id))
      .toList(),
  quantity: quantity,
  note: '',
);

CheckoutDraft _checkout({int quantity = 1, String name = 'Budi'}) =>
    CheckoutDraft(
      customerName: name,
      type: OrderType.takeaway,
      items: [CartEntry(id: 'entry-1', bowl: _bowl(quantity))],
    );

int _stockOf(List<Ingredient> catalog, String id) =>
    catalog.firstWhere((item) => item.id == id).availableStock;

void main() {
  test('US5 AC1: batal sebelum dapur mulai mengembalikan stok penuh', () async {
    final repository = DemoBowlRepository();
    final order = await repository.createOrder(_checkout(quantity: 2));

    final reserved = await repository.loadIngredients();
    expect(_stockOf(reserved, 'chicken'), 10);

    final cancelled = await repository.cancelOrder(order.id);
    expect(cancelled.cancelled, isTrue);

    final restored = await repository.loadIngredients();
    expect(_stockOf(restored, 'chicken'), 12);
    expect(_stockOf(restored, 'egg'), 10);
  });

  test(
    'US5 AC2: batal ditolak setelah Disiapkan dan stok tetap terpakai',
    () async {
      final repository = DemoBowlRepository();
      final order = await repository.createOrder(_checkout(quantity: 2));
      await repository.advanceStatus(order.id);

      await expectLater(
        repository.cancelOrder(order.id),
        throwsA(
          isA<OrderFailure>().having(
            (error) => error.message,
            'message',
            OrderCancellation.rejectedMessage,
          ),
        ),
      );

      final stock = await repository.loadIngredients();
      expect(_stockOf(stock, 'chicken'), 10);
      expect((await repository.latestOrders()).single.cancelled, isFalse);
    },
  );

  test('US5 AC3: aturan pembatalan mengikuti status dan flag batal', () {
    final order = Order(
      id: 'order-1',
      displayId: 'DX-20261023-001',
      customerName: 'Budi',
      type: OrderType.takeaway,
      items: const [],
      totalPrice: 0,
      status: OrderStatus.placed,
      createdAt: DateTime(2026, 10, 23),
    );

    expect(OrderCancellation.canCancel(order), isTrue);
    expect(
      OrderCancellation.canCancel(order.copyWith(cancelled: true)),
      isFalse,
    );
    expect(
      OrderCancellation.canCancel(
        order.copyWith(status: OrderStatus.preparing),
      ),
      isFalse,
    );
  });

  test('US5 AC4: membatalkan pesanan yang tidak ada ditolak', () async {
    final repository = DemoBowlRepository();
    await expectLater(
      repository.cancelOrder('missing'),
      throwsA(isA<OrderFailure>()),
    );
  });
}
