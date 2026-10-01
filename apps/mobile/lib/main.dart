import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/bowl_builder/data/demo_bowl_repository.dart';
import 'features/bowl_builder/state/bowl_providers.dart';

void main() {
  const defaultScenario = String.fromEnvironment(
    'DEMO_SCENARIO',
    defaultValue: 'success',
  );
  final scenario = Uri.base.queryParameters['scenario'] ?? defaultScenario;
  runApp(
    ProviderScope(
      overrides: [
        bowlRepositoryProvider.overrideWithValue(
          DemoBowlRepository(scenario: scenario),
        ),
      ],
      child: const DonburiXApp(),
    ),
  );
}
