import 'dart:async';

import '../domain/bowl_models.dart';
import '../domain/bowl_repository.dart';
import '../domain/bowl_validation.dart';
import '../../orders/domain/order_models.dart';
import '../../orders/domain/order_rules.dart';

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

  /// Sisa stok aktual, dipotong saat checkout dan dikembalikan saat batal.
  final Map<String, int> _stock = {
    for (final item in demoIngredients) item.id: item.availableStock,
  };

  final StreamController<Order> _orderUpdates =
      StreamController<Order>.broadcast();
  String? _sequenceDay;
  int _dailySequence = 0;
  int _loadAttempts = 0;
  int _submitAttempts = 0;
  int _checkoutAttempts = 0;

  void dispose() => _orderUpdates.close();

  List<Ingredient> _catalogSnapshot() => [
    for (final item in demoIngredients)
      Ingredient(
        id: item.id,
        name: item.name,
        category: item.category,
        price: item.price,
        availableStock: _stock[item.id] ?? item.availableStock,
      ),
  ];

  Order? _findById(String orderId) {
    for (final order in _orders) {
      if (order.id == orderId) return order;
    }
    return null;
  }

  int _activeQueuePortions() => _orders.fold(0, (sum, order) {
    if (order.cancelled) return sum;
    if (order.status == OrderStatus.completed) return sum;
    return sum + order.totalPortions;
  });

  @override
  Future<List<Ingredient>> loadIngredients() async {
    _loadAttempts++;
    if (scenario == 'loading') return Completer<List<Ingredient>>().future;
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (scenario == 'empty') return const [];
    if (scenario == 'error' && _loadAttempts == 1) {
      throw const BowlFailure(
        'Pilihan bahan belum dapat dimuat. Silakan coba lagi.',
      );
    }
    return _catalogSnapshot();
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
      final matches = _catalogSnapshot().where(
        (item) => item.id == selected.id,
      );
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
  Future<Order?> findByDisplayId(String displayId) async {
    final needle = OrderIdRules.normalize(displayId);
    if (needle.isEmpty) return null;
    for (final order in _orders) {
      if (OrderIdRules.normalize(order.displayId) == needle) return order;
    }
    return null;
  }

  @override
  Stream<Order> watchOrder(String orderId) async* {
    final current = _findById(orderId);
    if (current == null) {
      throw const OrderFailure('Pesanan tidak ditemukan.');
    }
    yield current;
    yield* _orderUpdates.stream.where((order) => order.id == orderId);
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

    final checked = <CartEntry>[];
    var total = 0;
    final required = <String, int>{};
    final names = <String, String>{};
    for (final entry in draft.items) {
      final bowl = BowlDraft(
        ingredients: entry.bowl.ingredients
            .map((item) => _canonical(item.id))
            .toList(),
        quantity: entry.bowl.quantity,
        note: entry.bowl.note,
      );
      try {
        BowlValidation.validateDraft(bowl);
      } on BowlFailure catch (error) {
        throw OrderFailure(error.message);
      }
      for (final item in bowl.ingredients) {
        required[item.id] = (required[item.id] ?? 0) + bowl.quantity;
        names[item.id] = item.name;
      }
      total += bowl.totalPrice;
      checked.add(CartEntry(id: entry.id, bowl: bowl));
    }

    final orderPortions = checked.fold(
      0,
      (sum, entry) => sum + entry.bowl.quantity,
    );

    // Reservasi stok all-or-nothing: tidak ada potongan parsial.
    for (final entry in required.entries) {
      final available = _stock[entry.key] ?? 0;
      if (available < entry.value) {
        throw OrderFailure(
          'Stok ${names[entry.key]} tidak cukup. Tersisa $available porsi.',
        );
      }
    }
    for (final entry in required.entries) {
      _stock[entry.key] = (_stock[entry.key] ?? 0) - entry.value;
    }

    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    if (_sequenceDay != dayKey) {
      _sequenceDay = dayKey;
      _dailySequence = 0;
    }
    _dailySequence++;

    final order = Order(
      id: 'order-${_orders.length + 1}',
      displayId: OrderIdRules.next(createdAt: now, sequence: _dailySequence),
      customerName: name,
      type: draft.type,
      items: List.unmodifiable(checked),
      totalPrice: total,
      status: OrderStatus.placed,
      createdAt: now,
      estimatedMinutes: OrderEta.estimate(
        // Saat pesanan masuk, antrean berisi pesanan ini sendiri.
        activePortions: _activeQueuePortions() + orderPortions,
        orderPortions: 0,
        type: draft.type,
      ),
    );
    _orders.insert(0, order);
    _orderUpdates.add(order);
    return order;
  }

  @override
  Future<Order> advanceStatus(String orderId) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) {
      throw const OrderFailure('Pesanan tidak ditemukan.');
    }
    final order = _orders[index];
    if (order.cancelled) {
      throw const OrderFailure('Pesanan sudah dibatalkan.');
    }
    final next = OrderStatusFlow.next(order.status);
    if (next == null) {
      throw const OrderFailure('Pesanan sudah selesai.');
    }
    final updated = order.copyWith(status: next);
    _orders[index] = updated;
    _orderUpdates.add(updated);
    return updated;
  }

  @override
  Future<Order> cancelOrder(String orderId) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) {
      throw const OrderFailure('Pesanan tidak ditemukan.');
    }
    final order = _orders[index];
    if (!OrderCancellation.canCancel(order)) {
      throw const OrderFailure(OrderCancellation.rejectedMessage);
    }
    for (final entry in order.items) {
      for (final item in entry.bowl.ingredients) {
        _stock[item.id] = (_stock[item.id] ?? 0) + entry.bowl.quantity;
      }
    }
    final updated = order.copyWith(cancelled: true);
    _orders[index] = updated;
    _orderUpdates.add(updated);
    return updated;
  }

  Ingredient _canonical(String id) {
    final matches = _catalogSnapshot().where((item) => item.id == id);
    if (matches.length != 1) {
      throw const BowlFailure('Bahan tidak ditemukan.');
    }
    return matches.single;
  }
}
