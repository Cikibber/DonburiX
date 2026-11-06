import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Satu kejadian keamanan sebagai satu baris JSON di konsol.
///
/// Jangan isi [fields] dengan email, nama, PIN, atau koordinat.
// ponytail: hanya konsol perangkat; kirim ke server log saat backend ada.
void logSecurityEvent(
  String event, {
  String level = 'warn',
  Map<String, Object?> fields = const {},
}) {
  debugPrint(
    jsonEncode({
      'ts': DateTime.now().toUtc().toIso8601String(),
      'level': level,
      'event': event,
      ...fields,
    }),
  );
}
