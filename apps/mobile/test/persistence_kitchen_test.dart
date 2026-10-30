import 'package:donburix/features/bowl_builder/data/demo_bowl_repository.dart';
import 'package:donburix/features/bowl_builder/domain/bowl_models.dart';
import 'package:donburix/features/orders/domain/order_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CheckoutDraft _checkout({String email = 'budi@mail.com'}) => CheckoutDraft(
  customerName: 'Budi',
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
        quantity: 2,
        note: 'Saus dipisah',
      ),
    ),
  ],
);

int _stockOf(List<Ingredient> catalog, String id) =>
    catalog.firstWhere((item) => item.id == id).availableStock;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'P7 storage AC1: pesanan dan stok bertahan setelah aplikasi dibuka ulang',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final first = DemoBowlRepository(prefs: prefs);
      final order = await first.createOrder(_checkout());
      await first.advanceStatus(order.id);

      final reopened = DemoBowlRepository(prefs: prefs);
      final orders = await reopened.latestOrders();

      expect(orders, hasLength(1));
      expect(orders.single.displayId, order.displayId);
      expect(orders.single.status, OrderStatus.preparing);
      expect(orders.single.customerEmail, 'budi@mail.com');
      expect(orders.single.items.single.bowl.note, 'Saus dipisah');
      expect(orders.single.totalPrice, 50000);
      expect(_stockOf(await reopened.loadIngredients(), 'chicken'), 10);

      final next = await reopened.createOrder(_checkout());
      expect(next.displayId, endsWith('-002'));
      expect(next.id, isNot(order.id));
    },
  );

  test('P7 storage AC2: data rusak tidak membuat aplikasi crash', () async {
    SharedPreferences.setMockInitialValues({
      DemoBowlRepository.storageKey: '{bukan json',
    });
    final prefs = await SharedPreferences.getInstance();
    final repository = DemoBowlRepository(prefs: prefs);

    expect(await repository.latestOrders(), isEmpty);
    expect(_stockOf(await repository.loadIngredients(), 'chicken'), 12);
  });

  test('P7 kitchen AC1: restok menambah stok dan tersimpan', () async {
    final prefs = await SharedPreferences.getInstance();
    final repository = DemoBowlRepository(prefs: prefs);

    await repository.restock('beef', 5);

    expect(_stockOf(await repository.loadIngredients(), 'beef'), 5);
    final reopened = DemoBowlRepository(prefs: prefs);
    expect(_stockOf(await reopened.loadIngredients(), 'beef'), 5);
  });

  test('P7 kitchen AC2: restok tidak valid ditolak', () async {
    final repository = DemoBowlRepository();
    for (final amount in [0, -1, 101]) {
      await expectLater(
        repository.restock('beef', amount),
        throwsA(isA<BowlFailure>()),
      );
    }
    await expectLater(
      repository.restock('tidak-ada', 5),
      throwsA(isA<BowlFailure>()),
    );
  });

  test(
    'P7 kitchen AC3: daftar pesanan live mengikuti perubahan dapur',
    () async {
      final repository = DemoBowlRepository();
      final snapshots = <List<Order>>[];
      final subscription = repository.watchOrders().listen(snapshots.add);
      await Future<void>.delayed(Duration.zero);

      final order = await repository.createOrder(_checkout());
      await repository.advanceStatus(order.id);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(snapshots.first, isEmpty);
      expect(snapshots.last.single.status, OrderStatus.preparing);
    },
  );
}
