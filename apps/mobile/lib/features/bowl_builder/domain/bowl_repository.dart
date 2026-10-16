import '../../orders/domain/order_models.dart';
import 'bowl_models.dart';

abstract interface class BowlRepository {
  Future<List<Ingredient>> loadIngredients();
  Future<CartEntry> addToCart(BowlDraft draft);
  Future<Order> createOrder(CheckoutDraft draft);
  Future<List<Order>> latestOrders();
  Stream<List<Order>> watchOrders();
}
