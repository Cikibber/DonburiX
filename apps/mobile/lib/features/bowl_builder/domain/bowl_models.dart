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

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'price': price,
  };

  factory Ingredient.fromJson(Map<String, Object?> json) => Ingredient(
    id: json['id']! as String,
    name: json['name']! as String,
    category: IngredientCategory.values.byName(json['category']! as String),
    price: json['price']! as int,
    availableStock: 0,
  );
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

  Map<String, Object?> toJson() => {
    'id': id,
    'quantity': bowl.quantity,
    'note': bowl.note,
    'ingredients': [for (final item in bowl.ingredients) item.toJson()],
  };

  factory CartEntry.fromJson(Map<String, Object?> json) => CartEntry(
    id: json['id']! as String,
    bowl: BowlDraft(
      ingredients: [
        for (final item in json['ingredients']! as List)
          Ingredient.fromJson(item as Map<String, Object?>),
      ],
      quantity: json['quantity']! as int,
      note: json['note']! as String,
    ),
  );
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
