import 'dart:async';

import '../domain/bowl_models.dart';
import '../domain/bowl_repository.dart';
import '../domain/bowl_validation.dart';

const demoIngredients = [
  Ingredient(
    id: 'rice',
    name: 'Nasi putih',
    category: IngredientCategory.base,
    price: 6000,
    availableStock: 20,
  ),
  Ingredient(
    id: 'brown-rice',
    name: 'Nasi merah',
    category: IngredientCategory.base,
    price: 8000,
    availableStock: 8,
  ),
  Ingredient(
    id: 'chicken',
    name: 'Ayam teriyaki',
    category: IngredientCategory.protein,
    price: 14000,
    availableStock: 12,
  ),
  Ingredient(
    id: 'tofu',
    name: 'Tahu crispy',
    category: IngredientCategory.protein,
    price: 10000,
    availableStock: 6,
  ),
  Ingredient(
    id: 'beef',
    name: 'Sapi yakiniku',
    category: IngredientCategory.protein,
    price: 18000,
    availableStock: 0,
  ),
  Ingredient(
    id: 'teriyaki',
    name: 'Saus teriyaki',
    category: IngredientCategory.sauce,
    price: 2000,
    availableStock: 20,
  ),
  Ingredient(
    id: 'sambal',
    name: 'Sambal matah',
    category: IngredientCategory.sauce,
    price: 3000,
    availableStock: 10,
  ),
  Ingredient(
    id: 'egg',
    name: 'Telur',
    category: IngredientCategory.addon,
    price: 3000,
    availableStock: 10,
  ),
  Ingredient(
    id: 'vegetables',
    name: 'Sayur segar',
    category: IngredientCategory.addon,
    price: 2000,
    availableStock: 15,
  ),
];

class DemoBowlRepository implements BowlRepository {
  DemoBowlRepository({this.scenario = 'success'});

  final String scenario;
  final List<CartEntry> _cart = [];
  int _loadAttempts = 0;
  int _submitAttempts = 0;

  @override
  Future<List<Ingredient>> loadIngredients() async {
    _loadAttempts++;
    if (scenario == 'loading') return Completer<List<Ingredient>>().future;
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (scenario == 'empty') return [];
    if (scenario == 'error' && _loadAttempts == 1) {
      throw const BowlFailure(
        'Pilihan bahan belum dapat dimuat. Silakan coba lagi.',
      );
    }
    return demoIngredients;
  }

  @override
  Future<CartEntry> addToCart(BowlDraft draft) async {
    _submitAttempts++;
    await Future<void>.delayed(Duration(seconds: scenario == 'submit' ? 5 : 1));
    if (scenario == 'submit-error' && _submitAttempts == 1) {
      throw const BowlFailure('Bowl belum tersimpan. Coba tambahkan kembali.');
    }
    final canonical = <Ingredient>[];
    for (final selected in draft.ingredients) {
      final matches = demoIngredients.where((item) => item.id == selected.id);
      if (matches.length != 1) {
        throw const BowlFailure('Bahan tidak ditemukan.');
      }
      canonical.add(matches.single);
    }
    final checked = BowlDraft(
      ingredients: canonical,
      quantity: draft.quantity,
      note: draft.note.trim(),
    );
    BowlValidation.validateDraft(checked);
    final entry = CartEntry(id: 'local-${_cart.length + 1}', bowl: checked);
    _cart.add(entry);
    return entry;
  }
}
