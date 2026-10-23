import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bowl_builder/state/bowl_providers.dart';
import '../domain/order_models.dart';

final orderListProvider = StreamNotifierProvider<OrderList, List<Order>>(
  OrderList.new,
);

/// Sinkronisasi status dapur ke pelanggan per pesanan.
final orderStreamProvider = StreamProvider.family<Order, String>(
  (ref, orderId) => ref.watch(bowlRepositoryProvider).watchOrder(orderId),
);

class OrderList extends StreamNotifier<List<Order>> {
  @override
  Stream<List<Order>> build() {
    return ref.watch(bowlRepositoryProvider).watchOrders();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final orders = await ref.read(bowlRepositoryProvider).latestOrders();
      state = AsyncData(orders);
    } on OrderFailure catch (error) {
      state = AsyncError(error, StackTrace.current);
    } catch (_) {
      state = AsyncError(
        const OrderFailure('Riwayat pesanan belum dapat dimuat.'),
        StackTrace.current,
      );
    }
  }
}

class CheckoutFormState {
  const CheckoutFormState({
    this.customerName = '',
    this.type = OrderType.takeaway,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final String customerName;
  final OrderType type;
  final bool isSubmitting;
  final String? errorMessage;

  CheckoutFormState copyWith({
    String? customerName,
    OrderType? type,
    bool? isSubmitting,
    String? errorMessage,
  }) => CheckoutFormState(
    customerName: customerName ?? this.customerName,
    type: type ?? this.type,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errorMessage: errorMessage,
  );
}

final checkoutFormProvider =
    NotifierProvider<CheckoutFormNotifier, CheckoutFormState>(
      CheckoutFormNotifier.new,
    );

class CheckoutFormNotifier extends Notifier<CheckoutFormState> {
  @override
  CheckoutFormState build() => const CheckoutFormState();

  void setCustomerName(String value) {
    if (!state.isSubmitting) state = state.copyWith(customerName: value);
  }

  void setType(OrderType type) {
    if (!state.isSubmitting) state = state.copyWith(type: type);
  }

  Future<Order?> submit() async {
    if (state.isSubmitting) return null;
    final nameError = validateCustomerName(state.customerName);
    if (nameError != null) {
      state = state.copyWith(errorMessage: nameError);
      return null;
    }
    final cart = ref.read(bowlBuilderProvider).cart;
    if (cart.isEmpty) {
      state = state.copyWith(errorMessage: 'Keranjang masih kosong.');
      return null;
    }
    state = state.copyWith(isSubmitting: true);
    try {
      final order = await ref
          .read(bowlRepositoryProvider)
          .createOrder(
            CheckoutDraft(
              customerName: state.customerName.trim(),
              type: state.type,
              items: cart,
            ),
          );
      if (!ref.mounted) return null;
      for (final entry in cart) {
        ref.read(bowlBuilderProvider.notifier).removeFromCart(entry.id);
      }
      state = state.copyWith(isSubmitting: false);
      ref.read(orderListProvider.notifier).refresh();
      return order;
    } on OrderFailure catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: error.message,
        );
      }
      return null;
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Pesanan belum tersimpan. Silakan coba lagi.',
        );
      }
      return null;
    }
  }
}
