import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NhatKyService {
  final String userId;
  NhatKyService(this.userId);
  String get _key => 'nhat_ky_$userId';

  static String ngay(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> save(String date, Map<String, dynamic> entry) async {
    final data = await load();
    data[date] = entry;
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_key, jsonEncode(data))) {
      throw Exception('Chưa lưu được nhật ký. Hãy thử lại.');
    }
  }

  static List<String> bayNgay(DateTime now) =>
      List.generate(7, (i) => ngay(DateTime(now.year, now.month, now.day - i)));

  static int soNgayHoanThanh(Map<String, dynamic> data, DateTime now) =>
      bayNgay(now)
          .where((date) => data[date] is Map && data[date]['done'] == true)
          .length;
}
