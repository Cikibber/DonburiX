import 'dart:math' as math;

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// NaN, tak hingga, dan koordinat di luar rentang bumi tidak valid.
  bool get isValid => latitude.abs() <= 90 && longitude.abs() <= 180;
}

/// Geofenced Freshness Trigger: radius 500 m dari satu gerai.
class Geofence {
  static const radiusMeters = 500.0;
  static const store = GeoPoint(-6.2000, 106.8166);

  // ponytail: titik simulasi untuk demo; ganti dengan GPS (geolocator)
  // saat aplikasi dijalankan di perangkat.
  static const demoNearby = GeoPoint(-6.2020, 106.8166);
  static const demoFar = GeoPoint(-6.2200, 106.8166);

  static const _earthRadiusMeters = 6371000.0;

  static double distanceMeters(GeoPoint a, GeoPoint b) {
    double rad(double degree) => degree * math.pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLng = rad(b.longitude - a.longitude);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.latitude)) *
            math.cos(rad(b.latitude)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusMeters * math.asin(math.sqrt(h));
  }

  static bool contains(GeoPoint point) =>
      point.isValid && distanceMeters(store, point) <= radiusMeters;
}
