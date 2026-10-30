import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/preferences.dart';
import 'features/bowl_builder/data/demo_bowl_repository.dart';
import 'features/bowl_builder/state/bowl_providers.dart';
import 'features/orders/domain/geofence.dart';
import 'features/orders/state/order_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const defaultScenario = String.fromEnvironment(
    'DEMO_SCENARIO',
    defaultValue: 'success',
  );
  final query = Uri.base.queryParameters;
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
