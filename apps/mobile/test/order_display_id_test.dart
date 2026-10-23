import 'package:donburix/features/bowl_builder/data/demo_bowl_repository.dart';
import 'package:donburix/features/bowl_builder/domain/bowl_models.dart';
import 'package:donburix/features/orders/domain/order_models.dart';
import 'package:donburix/features/orders/domain/order_rules.dart';
import 'package:flutter_test/flutter_test.dart';

CheckoutDraft _checkout({String name = 'Budi'}) => CheckoutDraft(
  customerName: name,
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

void main() {
  test('US3 AC1: format nomor DX-YYYYMMDD-NNN hanya menerima pola resmi', () {
    final id = OrderIdRules.next(
      createdAt: DateTime(2026, 10, 23),
      sequence: 7,
    );
    expect(id, 'DX-20261023-007');
    expect(OrderIdRules.isValid(id), isTrue);
    expect(OrderIdRules.isValid('DX-2026-007'), isFalse);
    expect(OrderIdRules.normalize(' dx-20261023-007 '), 'DX-20261023-007');
  });

  test('US3 AC2: urutan nomor naik per hari dan tidak bentrok', () async {
    final repository = DemoBowlRepository();
    final first = await repository.createOrder(_checkout());
    final second = await repository.createOrder(_checkout());

    expect(first.displayId, matches(RegExp(r'^DX-\d{8}-001$')));
    expect(second.displayId, matches(RegExp(r'^DX-\d{8}-002$')));
    expect(first.displayId, isNot(second.displayId));
  });

  test(
    'US3 AC3: lookup nomor tidak peka huruf besar/kecil dan spasi',
    () async {
      final repository = DemoBowlRepository();
      final order = await repository.createOrder(_checkout());

      final found = await repository.findByDisplayId(
        ' ${order.displayId.toLowerCase()} ',
      );
      expect(found?.id, order.id);
      expect(await repository.findByDisplayId('DX-00000000-999'), isNull);
      expect(await repository.findByDisplayId('   '), isNull);
    },
  );
}
