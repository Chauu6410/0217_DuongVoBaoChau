import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duong_vo_bao_chau_kt/services/api_client.dart';
import 'package:duong_vo_bao_chau_kt/services/auth_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'BASE_URL=http://10.0.2.2:5121');
  });

  test('Register sends backend DTO', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/Authenticate/register');
      expect(jsonDecode(request.body), {
        'email': 'test@example.com',
        'password': 'LabTest123!',
        'fullName': 'Test Parent',
        'role': 'Parent',
      });
      return http.Response(
        jsonEncode({'authenticatorKey': 'TEST_SETUP_KEY'}),
        200,
      );
    });
    final service = AuthService(api: ApiClient(client: client));
    await service.register('Test Parent', 'LabTest123!', 'test@example.com');
    client.close();
  });

  test('Generate OTP sends credentials and preserves leading zero', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/Authenticate/generate-otp');
      expect(jsonDecode(request.body), {
        'username': 'test@example.com',
        'password': 'LabTest123!',
      });
      return http.Response('{"otp":"012345"}', 200);
    });
    expect(
      await AuthService(api: ApiClient(client: client))
          .generateOTP('test@example.com', 'LabTest123!'),
      '012345',
    );
    client.close();
  });

  test('Login sends otpCode, reads ASP.NET role and saves JWT', () async {
    String encode(Map<String, dynamic> data) =>
        base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
    final token =
        '${encode({'alg': 'HS256'})}.${encode({'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000, 'http://schemas.microsoft.com/ws/2008/06/identity/claims/role': 'Parent'})}.test';
    final client = MockClient((request) async {
      expect(request.url.path, '/api/Authenticate/login');
      expect(jsonDecode(request.body), {
        'username': 'test@example.com',
        'password': 'LabTest123!',
        'otpCode': '012345',
      });
      return http.Response(jsonEncode({'Token': token}), 200);
    });
    expect(
      await AuthService(api: ApiClient(client: client))
          .login('test@example.com', 'LabTest123!', '012345'),
      'Parent',
    );
    expect(
      (await SharedPreferences.getInstance()).getString(ApiClient.tokenKey),
      token,
    );
    client.close();
  });

  test('Identity password errors are readable', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode([
          {
            'code': 'PasswordRequiresUpper',
            'description': 'Passwords must have uppercase.',
          },
        ]),
        400,
      ),
    );
    await expectLater(
      ApiClient(client: client).post('/api/Authenticate/register', {}),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Passwords must have uppercase.'),
        ),
      ),
    );
    client.close();
  });
}
