import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duong_vo_bao_chau_kt/screens/dong_hanh_screen.dart';
import 'package:duong_vo_bao_chau_kt/services/nhat_ky_service.dart';

void main() {
  testWidgets('Parent selects mood, completes challenge and saves diary', (
    tester,
  ) async {
    String encode(Map<String, dynamic> value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    SharedPreferences.setMockInitialValues({
      'token':
          '${encode({'alg': 'HS256'})}.${encode({'UserId': 'test-parent', 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})}.test',
    });
    await tester.pumpWidget(const MaterialApp(home: DongHanhScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Con đang cảm thấy thế nào?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Vui vẻ'));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lưu hôm nay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu hôm nay'));
    await tester.pumpAndSettle();
    final data = await NhatKyService('test-parent').load();
    final today = data[NhatKyService.ngay(DateTime.now())];
    expect(today['mood'], 'Vui vẻ');
    expect(today['done'], true);
    expect(find.text('Đã lưu nhật ký hôm nay.'), findsOneWidget);
  });
}
