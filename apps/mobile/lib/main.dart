import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/preferences.dart';
import 'features/bowl_builder/data/demo_bowl_repository.dart';
import 'features/bowl_builder/state/bowl_providers.dart';
import 'features/orders/domain/geofence.dart';
import 'features/orders/state/order_providers.dart';

/// Hook demo lewat URL hanya untuk build non-release, agar tautan buatan orang
/// lain tidak bisa mengubah perilaku aplikasi yang sudah di-deploy.
Map<String, String> demoQuery(Uri uri, {bool release = kReleaseMode}) =>
    release ? const {} : uri.queryParameters;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const defaultScenario = String.fromEnvironment(
    'DEMO_SCENARIO',
    defaultValue: 'success',
  );
  final query = demoQuery(Uri.base);
  final scenario = query['scenario'] ?? defaultScenario;
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        bowlRepositoryProvider.overrideWithValue(
          // Scenario demo kondisi UI memakai data bersih, bukan data tersimpan.
          DemoBowlRepository(
            scenario: scenario,
            prefs: scenario == 'success' ? prefs : null,
            // Tab browser lain (mis. layar dapur) berbagi penyimpanan ini.
            syncInterval: const Duration(seconds: 2),
          ),
        ),
        customerLocationProvider.overrideWithValue(
          query['location'] == 'far' ? Geofence.demoFar : Geofence.demoNearby,
        ),
      ],
      child: const DonburiXApp(),
    ),
  );
}
