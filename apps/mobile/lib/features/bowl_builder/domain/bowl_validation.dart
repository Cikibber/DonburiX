import 'bowl_models.dart';

class BowlValidation {
  static String? quantity(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 1 || parsed > 10) {
      return 'Jumlah harus bilangan bulat antara 1 dan 10.';
    }
    return null;
  }

  static String? note(String? value) {
    if ((value?.trim().length ?? 0) > 120) {
      return 'Catatan maksimal 120 karakter.';
    }
    return null;
  }

  static String? ingredient(
    Ingredient? value,
    IngredientCategory category,
    int quantity,
  ) {
    if (value == null) {
      return 'Pilih ${category.label.toLowerCase()} terlebih dahulu.';
    }
    if (value.category != category) return 'Kategori bahan tidak sesuai.';
    if (value.availableStock < quantity) {
      return 'Stok ${value.name} tidak cukup untuk $quantity porsi.';
    }
    return null;
  }

  static void validateDraft(BowlDraft draft) {
    final quantityError = quantity(draft.quantity.toString());
    if (quantityError != null) throw BowlFailure(quantityError);
    final noteError = note(draft.note);
    if (noteError != null) throw BowlFailure(noteError);
    for (final category in IngredientCategory.values) {
      final matches = draft.ingredients.where(
        (item) => item.category == category,
      );
      if (matches.length != 1) {
        throw BowlFailure(
          'Pilih satu ${category.label.toLowerCase()} terlebih dahulu.',
        );
      }
      final error = ingredient(matches.single, category, draft.quantity);
      if (error != null) throw BowlFailure(error);
    }
  }
}
