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
  test('US2 AC1: antrean kosong dine-in satu porsi memakai batas minimum', () {
    expect(
      OrderEta.estimate(
        activePortions: 0,
        orderPortions: 1,
        type: OrderType.dineIn,
      ),
      8,
    );
  });

  test('US2 AC2: takeaway menambah waktu pengemasan', () {
    expect(
      OrderEta.estimate(
        activePortions: 0,
        orderPortions: 1,
        type: OrderType.takeaway,
      ),
      10,
    );
    expect(
      OrderEta.estimate(
        activePortions: 5,
        orderPortions: 2,
        type: OrderType.takeaway,
      ),
      22,
    );
  });

  test('US2 AC3: estimasi dijepit maksimum 45 menit saat dapur penuh', () {
    expect(
      OrderEta.estimate(
        activePortions: 100,
        orderPortions: 10,
        type: OrderType.takeaway,
      ),
      45,
    );
  });

  test(
    'US2 AC4: estimasi tersimpan saat pesanan dibuat dan naik saat antrean bertambah',
    () async {
      final repository = DemoBowlRepository();
      final first = await repository.createOrder(_checkout());
      final second = await repository.createOrder(_checkout());

      expect(first.estimatedMinutes, 10);
      expect(second.estimatedMinutes, 12);
      expect(OrderEta.label(second.estimatedMinutes), '± 12 menit');
    },
  );

  test('US2 AC5: input negatif ditolak', () {
    expect(
      () => OrderEta.estimate(
        activePortions: -1,
        orderPortions: 0,
        type: OrderType.dineIn,
      ),
      throwsArgumentError,
    );
  });
}
