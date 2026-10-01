enum IngredientCategory {
  base('Base', 'Pilih nasi atau karbohidrat'),
  protein('Protein', 'Pilih lauk utama'),
  sauce('Saus', 'Pilih rasa favorit'),
  addon('Add-on', 'Lengkapi bowl Anda');

  const IngredientCategory(this.label, this.hint);

  final String label;
  final String hint;
}

class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.availableStock,
  });

  final String id;
  final String name;
  final IngredientCategory category;
  final int price;
  final int availableStock;
}

class BowlDraft {
  BowlDraft({
    required List<Ingredient> ingredients,
    required this.quantity,
    required this.note,
  }) : ingredients = List.unmodifiable(ingredients);

  final List<Ingredient> ingredients;
  final int quantity;
  final String note;

  int get unitPrice => ingredients.fold(0, (sum, item) => sum + item.price);
  int get totalPrice => unitPrice * quantity;
}

class CartEntry {
  const CartEntry({required this.id, required this.bowl});

  final String id;
  final BowlDraft bowl;
}

class BowlFailure implements Exception {
  const BowlFailure(this.message);

  final String message;
}

String formatRupiah(int amount) {
  final digits = amount.toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
  return 'Rp $grouped';
}
