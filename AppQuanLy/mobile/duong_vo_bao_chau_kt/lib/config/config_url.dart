import 'package:flutter_dotenv/flutter_dotenv.dart';

// Giữ tên lớp theo yêu cầu bài lab.
// ignore: camel_case_types
class Config_URL {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL']?.trim() ?? '';
    if (url.isEmpty) throw Exception('Chưa cấu hình BASE_URL trong .env');
    return url.replaceFirst(RegExp(r'/+$'), '');
  }

  static const login = '/api/Authenticate/login';
  static const generateOtp = '/api/Authenticate/generate-otp';
  static const register = '/api/Authenticate/register';
  static const devices = '/api/Device';
  static const users = '/api/Users';
}
