import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_bowl_repository.dart';
import '../domain/bowl_models.dart';
import '../domain/bowl_repository.dart';
import '../domain/bowl_validation.dart';

final bowlRepositoryProvider = Provider<BowlRepository>(
  (ref) => DemoBowlRepository(),
);

final ingredientCatalogProvider =
    AsyncNotifierProvider<IngredientCatalog, List<Ingredient>>(
      IngredientCatalog.new,
      retry: (retryCount, error) => null,
    );

class IngredientCatalog extends AsyncNotifier<List<Ingredient>> {
  @override
  Future<List<Ingredient>> build() {
    return ref.watch(bowlRepositoryProvider).loadIngredients();
  }
}

class BowlBuilderState {
  BowlBuilderState({
    Map<IngredientCategory, String> selectedIds = const {},
    this.quantityText = '1',
    this.note = '',
    this.isSubmitting = false,
    this.submitError,
    this.successMessage,
    this.cartError,
    List<CartEntry> cart = const [],
  }) : selectedIds = Map.unmodifiable(selectedIds),
       cart = List.unmodifiable(cart);

  final Map<IngredientCategory, String> selectedIds;
  final String quantityText;
  final String note;
  final bool isSubmitting;
  final String? submitError;
  final String? successMessage;
  final String? cartError;
  final List<CartEntry> cart;

  BowlBuilderState copyWith({
    Map<IngredientCategory, String>? selectedIds,
    String? quantityText,
    String? note,
    bool? isSubmitting,
    String? submitError,
    String? successMessage,
    String? cartError,
    List<CartEntry>? cart,
  }) => BowlBuilderState(
    selectedIds: selectedIds ?? this.selectedIds,
    quantityText: quantityText ?? this.quantityText,
    note: note ?? this.note,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    submitError: submitError,
    successMessage: successMessage,
    cartError: cartError,
    cart: cart ?? this.cart,
  );
}

final bowlBuilderProvider =
    NotifierProvider<BowlBuilderNotifier, BowlBuilderState>(
      BowlBuilderNotifier.new,
    );

class BowlBuilderNotifier extends Notifier<BowlBuilderState> {
  @override
  BowlBuilderState build() => BowlBuilderState();

  void select(IngredientCategory category, String id) {
    if (state.isSubmitting) return;
    state = state.copyWith(selectedIds: {...state.selectedIds, category: id});
  }

  void setQuantity(String value) {
    if (!state.isSubmitting) state = state.copyWith(quantityText: value);
  }

  void setNote(String value) {
    if (!state.isSubmitting) state = state.copyWith(note: value);
  }

  void removeFromCart(String entryId) {
    if (state.isSubmitting) return;
    state = state.copyWith(
      cart: state.cart.where((entry) => entry.id != entryId).toList(),
    );
  }

  void updateCartQuantity(String entryId, int quantity) {
    if (state.isSubmitting) return;
    final index = state.cart.indexWhere((entry) => entry.id == entryId);
    if (index == -1) return;
    final entry = state.cart[index];
    final candidate = BowlDraft(
      ingredients: entry.bowl.ingredients,
      quantity: quantity,
      note: entry.bowl.note,
    );
    try {
      BowlValidation.validateDraft(candidate);
    } on BowlFailure catch (error) {
      state = state.copyWith(cartError: error.message);
      return;
    }
    final updated = List<CartEntry>.of(state.cart);
    updated[index] = CartEntry(id: entry.id, bowl: candidate);
    state = state.copyWith(cart: updated);
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;
    final catalog = ref.read(ingredientCatalogProvider).asData?.value;
    if (catalog == null) return;
    final draft = BowlDraft(
      ingredients: catalog
          .where((item) => state.selectedIds[item.category] == item.id)
          .toList(),
      quantity: int.tryParse(state.quantityText.trim()) ?? 0,
      note: state.note.trim(),
    );
    try {
      BowlValidation.validateDraft(draft);
    } on BowlFailure catch (error) {
      state = state.copyWith(submitError: error.message);
      return;
    }
    state = state.copyWith(isSubmitting: true);
    try {
      final entry = await ref.read(bowlRepositoryProvider).addToCart(draft);
      if (!ref.mounted) return;
      state = state.copyWith(
        isSubmitting: false,
        cart: [...state.cart, entry],
        successMessage:
            '${entry.bowl.quantity} porsi berhasil ditambahkan ke keranjang.',
      );
    } on BowlFailure catch (error) {
      if (ref.mounted) {
        state = state.copyWith(isSubmitting: false, submitError: error.message);
      }
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: 'Bowl belum tersimpan. Silakan coba lagi.',
        );
      }
    }
  }
}

final bowlTotalProvider = Provider<int>((ref) {
  final builder = ref.watch(bowlBuilderProvider);
  final catalog = ref.watch(ingredientCatalogProvider).asData?.value ?? [];
  final quantity = int.tryParse(builder.quantityText.trim());
  if (quantity == null || quantity < 1 || quantity > 10) return 0;
  final unitPrice = catalog
      .where((item) => builder.selectedIds[item.category] == item.id)
      .fold(0, (sum, item) => sum + item.price);
  return unitPrice * quantity;
});

final cartTotalProvider = Provider<int>((ref) {
  final builder = ref.watch(bowlBuilderProvider);
  return builder.cart.fold(0, (sum, entry) => sum + entry.bowl.totalPrice);
});

final cartItemCountProvider = Provider<int>((ref) {
  final builder = ref.watch(bowlBuilderProvider);
  return builder.cart.fold(0, (sum, entry) => sum + entry.bowl.quantity);
});
