import '../../bowl_builder/domain/bowl_models.dart';

enum OrderType {
  takeaway('Takeaway'),
  dineIn('Dine-in');

  const OrderType(this.label);

  final String label;
}

enum OrderStatus {
  placed('Dipesan'),
  preparing('Disiapkan'),
  ready('Siap diambil'),
  completed('Selesai');

  const OrderStatus(this.label);

  final String label;
}

class Order {
  const Order({
    required this.id,
    required this.displayId,
    required this.customerName,
    required this.type,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String displayId;
  final String customerName;
  final OrderType type;
  final List<CartEntry> items;
  final int totalPrice;
  final OrderStatus status;
  final DateTime createdAt;

  int get totalPortions =>
      items.fold(0, (sum, entry) => sum + entry.bowl.quantity);
}

class OrderFailure implements Exception {
  const OrderFailure(this.message);

  final String message;
}

class CheckoutDraft {
  const CheckoutDraft({
    required this.customerName,
    required this.type,
    required this.items,
  });

  final String customerName;
  final OrderType type;
  final List<CartEntry> items;
}

String? validateCustomerName(String? value) {
  if ((value?.trim().isEmpty ?? true)) {
    return 'Nama pemesan wajib diisi.';
  }
  return null;
}
