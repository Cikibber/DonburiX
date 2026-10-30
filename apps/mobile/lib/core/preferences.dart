import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan lokal. Null berarti data hanya hidup selama sesi (mis. test).
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);
