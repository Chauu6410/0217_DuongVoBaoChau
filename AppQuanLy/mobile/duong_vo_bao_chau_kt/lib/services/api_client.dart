import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config_url.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  final http.Client? client;
  ApiClient({this.client});
  static const tokenKey = 'token';
  Future<dynamic> get(String path) => _request('GET', path);
  Future<dynamic> post(String path, Map<String, dynamic> data) =>
      _request('POST', path, data);
  Future<dynamic> put(String path, Map<String, dynamic> data) =>
      _request('PUT', path, data);
  Future<dynamic> delete(String path) => _request('DELETE', path);

  Future<dynamic> _request(
    String method,
    String path, [
    Map<String, dynamic>? data,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    final request = http.Request(
      method,
      Uri.parse('${Config_URL.baseUrl}$path'),
    );
    request.headers.addAll({
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (data != null) request.body = jsonEncode(data);
    final connection = client ?? http.Client();
    try {
      final response = await (() async {
        final stream = await connection.send(request);
        return http.Response.fromStream(stream);
      })().timeout(const Duration(seconds: 20));
      final text = utf8.decode(response.bodyBytes);
      dynamic result;
      if (text.trim().isNotEmpty) {
        try {
          result = jsonDecode(text);
        } on FormatException {
          result = text;
        }
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      }
      throw ApiException(
        'HTTP ${response.statusCode}: ${_errorMessage(result)}',
      );
    } on TimeoutException {
      throw ApiException(
        'API phản hồi quá lâu. Kiểm tra backend đang chạy tại ${Config_URL.baseUrl}.',
      );
    } on http.ClientException {
      throw ApiException(
        'Không kết nối được API tại ${Config_URL.baseUrl}. Hãy chạy backend bằng profile http và kiểm tra địa chỉ .env.',
      );
    } finally {
      if (client == null) connection.close();
    }
  }

  String _errorMessage(dynamic result) {
    if (result is Map) {
      final errors = result['errors'] ?? result['Errors'];
      if (errors is Map) {
        return errors.values.expand((v) => v is List ? v : [v]).join('\n');
      }
      return (result['message'] ??
              result['Message'] ??
              result['description'] ??
              result['Description'] ??
              result['title'] ??
              result['Title'] ??
              'Yêu cầu thất bại.')
          .toString();
    }
    if (result is List) return result.map(_errorMessage).join('\n');
    // Không đưa nguyên trang HTML/stack trace của server lên màn hình.
    return 'Yêu cầu thất bại. Kiểm tra endpoint hoặc nhật ký backend.';
  }
}
