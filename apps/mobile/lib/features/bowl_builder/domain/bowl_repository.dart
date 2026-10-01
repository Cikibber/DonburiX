import 'bowl_models.dart';

abstract interface class BowlRepository {
  Future<List<Ingredient>> loadIngredients();
  Future<CartEntry> addToCart(BowlDraft draft);
}
