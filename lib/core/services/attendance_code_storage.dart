import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/attendance/data/models/attendance_model.dart';

class AttendanceCodeStorage {
  static const _employeeCodesKey = 'attendance_recent_employee_codes';
  static const _attendanceCodesKey = 'attendance_recent_attendance_codes';
  static const _maxCodes = 5;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<List<String>> loadCodes(AttendanceClaimType type) async {
    final raw = await _storage.read(key: _keyFor(type));
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveCode(AttendanceClaimType type, String code) async {
    final cleaned = code.trim();
    if (cleaned.isEmpty) return;

    final existing = await loadCodes(type);
    final updated = [
      cleaned,
      ...existing.where((value) => value != cleaned),
    ].take(_maxCodes).toList();

    await _storage.write(key: _keyFor(type), value: jsonEncode(updated));
  }

  static String _keyFor(AttendanceClaimType type) {
    return type == AttendanceClaimType.employeeCode
        ? _employeeCodesKey
        : _attendanceCodesKey;
  }
}
