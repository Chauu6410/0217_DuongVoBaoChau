import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:duong_vo_bao_chau_kt/main.dart';
import 'package:duong_vo_bao_chau_kt/screens/registration_screen.dart';
import 'package:duong_vo_bao_chau_kt/screens/home_screen.dart';
import 'package:duong_vo_bao_chau_kt/screens/staff_dashboard_screen.dart';
import 'package:duong_vo_bao_chau_kt/screens/admin_screen.dart';
import 'package:duong_vo_bao_chau_kt/services/api_client.dart';

void main() {
  testWidgets('Material screens fit a narrow phone and preserve device menu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'BASE_URL=http://10.0.2.2:5121');
    await tester.pumpWidget(const MyApp());
    final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
    expect(theme.colorScheme.primary, const Color(0xFF1E3A8A));
    expect(tester.takeException(), isNull);
    for (final page in <Widget>[const RegisterScreen(), const AdminScreen()]) {
      await tester.pumpWidget(MaterialApp(theme: theme, home: page));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode([
          {
            'id': 1,
            'deviceName': 'Dien thoai cua be An ten rat dai',
            'batteryLevel': 15,
            'isLocked': true,
          },
        ]),
        200,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: StaffDashboardScreen(api: ApiClient(client: client)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: HomeScreen(api: ApiClient(client: client)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byTooltip('Thao tác thiết bị'), 150);
    await tester.tap(find.byTooltip('Thao tác thiết bị'));
    await tester.pumpAndSettle();
    expect(find.text('Sửa'), findsOneWidget);
    expect(find.text('Xóa'), findsOneWidget);
    expect(find.text('Đang khóa'), findsOneWidget);
    expect(tester.takeException(), isNull);
    client.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
