import 'package:donburix/features/bowl_builder/data/demo_bowl_repository.dart';
import 'package:donburix/features/bowl_builder/domain/bowl_models.dart';
import 'package:donburix/features/orders/domain/order_models.dart';
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
  test('US1 AC1: checkout memotong stok sesuai jumlah porsi', () async {
    final repository = DemoBowlRepository();
    final order = await repository.createOrder(_checkout(quantity: 2));

    expect(order.totalPortions, 2);
    final stock = await repository.loadIngredients();
    expect(_stockOf(stock, 'chicken'), 10);
    expect(_stockOf(stock, 'rice'), 18);
    expect(_stockOf(stock, 'teriyaki'), 18);
    expect(_stockOf(stock, 'egg'), 8);
  });

  test(
    'US1 AC2: stok habis menolak checkout tanpa mengurangi stok lain',
    () async {
      final repository = DemoBowlRepository();
      await repository.createOrder(_checkout(quantity: 10));

      await expectLater(
        repository.createOrder(_checkout(quantity: 1)),
        throwsA(
          isA<OrderFailure>().having(
            (error) => error.message,
            'message',
            contains('tidak cukup'),
          ),
        ),
      );

      final stock = await repository.loadIngredients();
      expect(_stockOf(stock, 'egg'), 0);
      expect(_stockOf(stock, 'chicken'), 2);
    },
  );

  test(
    'US1 AC3: reservasi stok all-or-nothing, tidak ada potongan parsial',
    () async {
      final repository = DemoBowlRepository();
      final items = [
        CartEntry(id: 'entry-a', bowl: _bowl(8)),
        CartEntry(id: 'entry-b', bowl: _bowl(8)),
      ];

      await expectLater(
        repository.createOrder(
          CheckoutDraft(
            customerName: 'Rina',
            type: OrderType.dineIn,
            items: items,
          ),
        ),
        throwsA(
          isA<OrderFailure>().having(
            (error) => error.message,
            'message',
            contains('Ayam teriyaki'),
          ),
        ),
      );

      final stock = await repository.loadIngredients();
      expect(_stockOf(stock, 'chicken'), 12);
      expect(_stockOf(stock, 'rice'), 20);
      expect(await repository.latestOrders(), isEmpty);
    },
  );
}
