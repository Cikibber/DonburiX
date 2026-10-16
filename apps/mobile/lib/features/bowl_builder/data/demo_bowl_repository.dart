import 'dart:async';

import '../domain/bowl_models.dart';
import '../domain/bowl_repository.dart';
import '../domain/bowl_validation.dart';
import '../../orders/domain/order_models.dart';

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
  final List<Order> _orders = [];
  int _loadAttempts = 0;
  int _submitAttempts = 0;
  int _checkoutAttempts = 0;

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

  @override
  Future<List<Order>> latestOrders() async {
    if (scenario == 'orders-empty') return const [];
    if (scenario == 'orders-error') {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      throw const OrderFailure(
        'Riwayat pesanan belum dapat dimuat. Silakan coba lagi.',
      );
    }
    return List.unmodifiable(_orders);
  }

  @override
  Stream<List<Order>> watchOrders() async* {
    if (scenario == 'orders-empty') {
      yield const [];
      return;
    }
    if (scenario == 'orders-error') {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      throw const OrderFailure(
        'Riwayat pesanan belum dapat dimuat. Silakan coba lagi.',
      );
    }
    yield List.unmodifiable(_orders);
  }

  @override
  Future<Order> createOrder(CheckoutDraft draft) async {
    _checkoutAttempts++;
    final name = draft.customerName.trim();
    if (name.isEmpty) {
      throw const OrderFailure('Nama pemesan wajib diisi.');
    }
    if (draft.items.isEmpty) {
      throw const OrderFailure('Keranjang masih kosong.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (scenario == 'checkout-error' && _checkoutAttempts == 1) {
      throw const OrderFailure('Pesanan belum tersimpan. Silakan coba lagi.');
    }
    var total = 0;
    for (final entry in draft.items) {
      final checked = BowlDraft(
        ingredients: entry.bowl.ingredients
            .map((item) => _canonical(item.id))
            .toList(),
        quantity: entry.bowl.quantity,
        note: entry.bowl.note,
      );
      try {
        BowlValidation.validateDraft(checked);
      } on BowlFailure catch (error) {
        throw OrderFailure(error.message);
      }
      total += checked.totalPrice;
    }
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final order = Order(
      id: 'order-${_orders.length + 1}',
      displayId: 'DX-$stamp-${(_orders.length + 1).toString().padLeft(3, '0')}',
      customerName: name,
      type: draft.type,
      items: List.unmodifiable(draft.items),
      totalPrice: total,
      status: OrderStatus.placed,
      createdAt: now,
    );
    _orders.insert(0, order);
    return order;
  }

  Ingredient _canonical(String id) {
    final matches = demoIngredients.where((item) => item.id == id);
    if (matches.length != 1) {
      throw const BowlFailure('Bahan tidak ditemukan.');
    }
    return matches.single;
  }
}
