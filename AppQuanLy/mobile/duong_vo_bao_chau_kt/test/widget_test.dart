import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duong_vo_bao_chau_kt/main.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duong_vo_bao_chau_kt/screens/login_screen.dart';
import 'package:duong_vo_bao_chau_kt/services/api_client.dart';
import 'package:duong_vo_bao_chau_kt/services/auth_service.dart';

void main() {
  testWidgets('Get OTP fills field and shows code in SnackBar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'BASE_URL=http://10.0.2.2:5121');
    final client = MockClient(
      (_) async => http.Response('{"otp":"012345"}', 200),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authService: AuthService(api: ApiClient(client: client)),
        ),
      ),
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'test@example.com');
    await tester.enterText(fields.at(1), 'LabTest123!');
    await tester.ensureVisible(find.text('Lấy OTP'));
    await tester.tap(find.text('Lấy OTP'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(fields.at(2)).controller!.text,
      '012345',
    );
    expect(find.text('Mã OTP của bạn là: 012345'), findsOneWidget);
    client.close();
  });
  testWidgets('Login validates required fields and opens registration', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('OTP'), findsOneWidget);
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Đăng nhập'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập username'), findsOneWidget);
    expect(find.text('Nhập password'), findsOneWidget);
    expect(find.text('OTP phải gồm đúng 6 chữ số'), findsOneWidget);
    await tester.ensureVisible(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Họ và tên'), findsOneWidget);
    expect(find.text('Nhập lại password'), findsOneWidget);
  });
}
