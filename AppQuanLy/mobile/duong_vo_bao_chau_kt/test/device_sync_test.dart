import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duong_vo_bao_chau_kt/screens/home_screen.dart';
import 'package:duong_vo_bao_chau_kt/services/api_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'BASE_URL=http://10.0.2.2:5121');
  });
  testWidgets('Open device list refreshes external changes after five seconds', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    var count = 0;
    final client = MockClient((_) async => http.Response(jsonEncode([
      {'id': 1, 'deviceName': ++count == 1 ? 'Original' : 'Updated elsewhere', 'batteryLevel': 80, 'isLocked': false},
    ]), 200));
    await tester.pumpWidget(MaterialApp(home: HomeScreen(api: ApiClient(client: client))));
    await tester.pumpAndSettle();
    expect(find.text('Original'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Updated elsewhere'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    client.close();
  });

  testWidgets('Management can assign an existing device to a parent', (tester) async {
    Map<String, dynamic>? saved;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/parents')) {
        return http.Response('[{"id":"parent-id","email":"parent@example.com"}]', 200);
      }
      if (request.method == 'PUT') {
        saved = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
        return http.Response('', 204);
      }
      return http.Response(jsonEncode([
        {'id': 5, 'deviceName': 'iPad', 'batteryLevel': 100, 'isLocked': false, 'userId': 'admin-id'},
      ]), 200);
    });
    await tester.pumpWidget(MaterialApp(home: HomeScreen(management: true, api: ApiClient(client: client))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byTooltip('Thao tác thiết bị'), 150);
    await tester.tap(find.byTooltip('Thao tác thiết bị'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sửa'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('parent@example.com').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(saved?['userId'], 'parent-id');
    expect(saved?['id'], 5);
    await tester.pumpWidget(const SizedBox.shrink());
    client.close();
  });
}
