import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:duong_vo_bao_chau_kt/screens/admin_screen.dart';
import 'package:duong_vo_bao_chau_kt/screens/staff_dashboard_screen.dart';
import 'package:duong_vo_bao_chau_kt/screens/tai_khoan_screen.dart';
import 'package:duong_vo_bao_chau_kt/services/api_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'BASE_URL=http://10.0.2.2:5121');
  });

  testWidgets('Admin shows all management options', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminScreen()));
    expect(find.text('Quản lý người dùng'), findsOneWidget);
    expect(find.text('Quản lý nhân viên'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Quản lý danh mục thiết bị'),
      200,
    );
    expect(find.text('Quản lý danh mục thiết bị'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Đăng xuất'), 200);
    expect(find.text('Đăng xuất'), findsOneWidget);
  });

  testWidgets('Staff stats and warnings use API data', (tester) async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/Device');
      return http.Response(
        jsonEncode([
          {
            'id': 1,
            'deviceName': 'Phone A',
            'batteryLevel': 90,
            'isLocked': false,
          },
          {
            'id': 2,
            'deviceName': 'Phone B',
            'batteryLevel': 20,
            'isLocked': true,
          },
          {
            'id': 3,
            'deviceName': 'Phone C',
            'batteryLevel': 0,
            'isLocked': false,
          },
        ]),
        200,
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        home: StaffDashboardScreen(api: ApiClient(client: client)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Phone B'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Pin yếu: 20%\nThiết bị đang bị khóa'), findsOneWidget);
    client.close();
  });

  testWidgets('Staff account list requests role filter and supports search', (
    tester,
  ) async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/Users');
      expect(request.url.queryParameters['role'], 'Staff');
      return http.Response(
        jsonEncode([
          {
            'fullName': 'Nhan vien',
            'email': 'staff@example.com',
            'roles': ['Staff'],
          },
        ]),
        200,
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        home: TaiKhoanScreen(
          role: 'Staff',
          api: ApiClient(client: client),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nhan vien'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'no-match');
    await tester.pump();
    expect(find.text('Không tìm thấy tài khoản.'), findsOneWidget);
    client.close();
  });
}
