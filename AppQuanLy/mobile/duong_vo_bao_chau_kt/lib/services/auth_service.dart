import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config_url.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _api;
  AuthService({ApiClient? api}) : _api = api ?? ApiClient();
  Future<String> generateOTP(String username, String password) async {
    final result = await _api.post(Config_URL.generateOtp, {
      'username': username.trim(),
      'password': password,
    });
    final code = result is Map
        ? result['otp'] ??
              result['Otp'] ??
              result['otpCode'] ??
              result['OtpCode']
        : null;
    if (code is! String || !RegExp(r'^\d{6}$').hasMatch(code)) {
      throw ApiException('API chưa trả về otpCode gồm 6 chữ số.');
    }
    return code;
  }

  Future<String> login(String username, String password, String otp) async {
    final result = await _api.post(Config_URL.login, {
      'username': username,
      'password': password,
      'otpCode': otp,
    });
    final token = result is Map
        ? result['token'] ?? result['Token'] ?? result['accessToken']
        : null;
    if (token is! String || token.isEmpty) {
      throw Exception('API chưa trả về token.');
    }
    final claims = JwtDecoder.decode(token);
    if (JwtDecoder.isExpired(token)) throw Exception('Token đã hết hạn.');
    final role =
        claims['role'] ??
        claims['Role'] ??
        claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
    final roles = role is List ? role : [role];
    final selected = [
      'Admin',
      'Staff',
      'Parent',
    ].where(roles.contains).firstOrNull;
    if (selected == null) throw Exception('Tài khoản chưa có quyền hợp lệ.');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiClient.tokenKey, token);
    return selected;
  }

  Future<void> register(
    String fullName,
    String password,
    String email, {
    String role = 'Parent',
  }) async {
    await _api.post(Config_URL.register, {
      'fullName': fullName,
      'password': password,
      'email': email,
      'role': role,
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiClient.tokenKey);
  }

  Future<String> currentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiClient.tokenKey);
    if (token == null || JwtDecoder.isExpired(token)) {
      throw ApiException('Phiên đăng nhập hết hạn. Hãy đăng nhập lại.');
    }
    final claims = JwtDecoder.decode(token);
    final id =
        claims['UserId'] ??
        claims['sub'] ??
        claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];
    if (id is! String || id.isEmpty) throw ApiException('Token thiếu UserId.');
    return id;
  }
}
