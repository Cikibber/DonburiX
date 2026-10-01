import 'package:donburix/features/bowl_builder/data/demo_bowl_repository.dart';
import 'package:donburix/features/bowl_builder/domain/bowl_models.dart';
import 'package:donburix/features/bowl_builder/domain/bowl_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'repository uses canonical prices rather than caller-provided price',
    () async {
      final repository = DemoBowlRepository();
      final ids = ['rice', 'chicken', 'teriyaki', 'egg'];
      final ingredients = demoIngredients
          .where((item) => ids.contains(item.id))
          .map(
            (item) => Ingredient(
              id: item.id,
              name: item.name,
              category: item.category,
              price: 1,
              availableStock: 99,
            ),
          )
          .toList();
      final entry = await repository.addToCart(
        BowlDraft(ingredients: ingredients, quantity: 2, note: ' test '),
      );
      expect(entry.bowl.totalPrice, 50000);
      expect(entry.bowl.note, 'test');
    },
  );

  test(
    'draft validation rejects duplicate categories and insufficient stock',
    () {
      final rice = demoIngredients.first;
      expect(
        () => BowlValidation.validateDraft(
          BowlDraft(ingredients: [rice, rice], quantity: 1, note: ''),
        ),
        throwsA(isA<BowlFailure>()),
      );
      final items = demoIngredients
          .where(
            (item) => ['rice', 'tofu', 'teriyaki', 'egg'].contains(item.id),
          )
          .toList();
      expect(
        () => BowlValidation.validateDraft(
          BowlDraft(ingredients: items, quantity: 7, note: ''),
        ),
        throwsA(isA<BowlFailure>()),
      );
    },
  );
}
