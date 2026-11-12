import '../../orders/domain/geofence.dart';
import '../../orders/domain/order_models.dart';
import 'bowl_models.dart';

abstract interface class BowlRepository {
  Future<List<Ingredient>> loadIngredients();
  Future<CartEntry> addToCart(BowlDraft draft);
  Future<Order> createOrder(CheckoutDraft draft);
  Future<List<Order>> latestOrders();

  /// [actorEmail] = akun pelanggan yang meminta; null = staf/sistem.
  Future<Order?> findByDisplayId(String displayId, {String? actorEmail});
  Stream<Order> watchOrder(String orderId);
  Future<Order> advanceStatus(String orderId);
  Future<Order> cancelOrder(String orderId, {String? actorEmail});
  Stream<List<Order>> watchOrders();
  Future<Order> markArrived(
    String orderId,
    GeoPoint location, {
    String? actorEmail,
  });
  Future<void> restock(String ingredientId, int amount);

  /// Stok berubah dari luar aplikasi ini, mis. tab browser lain.
  Stream<void> get stockChanges;
}
