import 'order_models.dart';

/// Aturan nomor pesanan publik.
///
/// Format: `DX-YYYYMMDD-NNN`, urut per hari. Huruf besar dipakai agar
/// pencarian nomor tidak bergantung pada kapitalisasi input pelanggan.
class OrderIdRules {
  static const prefix = 'DX';
  static final _pattern = RegExp(r'^DX-\d{8}-\d{3}$');

  static String next({required DateTime createdAt, required int sequence}) {
    if (sequence < 1 || sequence > 999) {
      throw ArgumentError.value(sequence, 'sequence', 'Urutan 1..999');
    }
    final day =
        '${createdAt.year.toString().padLeft(4, '0')}'
        '${createdAt.month.toString().padLeft(2, '0')}'
        '${createdAt.day.toString().padLeft(2, '0')}';
    return '$prefix-$day-${sequence.toString().padLeft(3, '0')}';
  }

  static bool isValid(String value) => _pattern.hasMatch(value.trim());

  static String normalize(String value) => value.trim().toUpperCase();
}

/// Estimasi waktu penyajian dinamis.
///
/// Dasar 6 menit, 2 menit per porsi yang masih di dapur, tambahan 2 menit
/// untuk takeaway karena proses pengemasan, lalu dijepit 8..45 menit.
class OrderEta {
  static const baseMinutes = 6;
  static const minutesPerPortion = 2;
  static const takeawayExtraMinutes = 2;
  static const minMinutes = 8;
  static const maxMinutes = 45;

  static int estimate({
    required int activePortions,
    required int orderPortions,
    required OrderType type,
  }) {
    if (activePortions < 0) {
      throw ArgumentError.value(activePortions, 'activePortions');
    }
    if (orderPortions < 0) {
      throw ArgumentError.value(orderPortions, 'orderPortions');
    }
    var minutes =
        baseMinutes + minutesPerPortion * (activePortions + orderPortions);
    if (type == OrderType.takeaway) minutes += takeawayExtraMinutes;
    return minutes.clamp(minMinutes, maxMinutes);
  }

  static String label(int minutes) => '± $minutes menit';
}

/// Status hanya boleh maju satu langkah. Tidak ada jalan mundur.
class OrderStatusFlow {
  static OrderStatus? next(OrderStatus current) => switch (current) {
    OrderStatus.placed => OrderStatus.preparing,
    OrderStatus.preparing => OrderStatus.ready,
    OrderStatus.ready => OrderStatus.completed,
    OrderStatus.completed => null,
  };

  static bool canAdvanceTo(OrderStatus from, OrderStatus to) =>
      next(from) == to;
}

/// Pembatalan hanya sebelum dapur mulai menyiapkan pesanan.
class OrderCancellation {
  static bool canCancel(Order order) =>
      !order.cancelled && order.status == OrderStatus.placed;

  static const rejectedMessage =
      'Pesanan sudah diproses dapur dan tidak dapat dibatalkan.';
}
