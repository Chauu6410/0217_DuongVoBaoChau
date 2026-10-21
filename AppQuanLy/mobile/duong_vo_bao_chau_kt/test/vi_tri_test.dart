import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:duong_vo_bao_chau_kt/services/api_client.dart';
import 'package:duong_vo_bao_chau_kt/services/vi_tri_service.dart';
import 'package:duong_vo_bao_chau_kt/screens/vi_tri_sheet.dart';

class FakeLocation extends ViTriService {
  bool sent = false;
  bool opened = false;
  @override
  Future<Map<String, dynamic>> getLocation(int deviceId) async => {
    'latitude': sent ? 10.762622 : null,
    'longitude': sent ? 106.660172 : null,
    'lastUpdatedLocation': sent ? '2026-10-22T03:00:00Z' : null,
  };
  @override
  Future<void> updateLocation(int deviceId, double latitude, double longitude) async {
    expect(deviceId, 7);
    expect(latitude, 10.762622);
    expect(longitude, 106.660172);
    sent = true;
  }
  @override
  Future<void> openMaps(double latitude, double longitude) async { opened = true; }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'BASE_URL=http://10.0.2.2:5121');
  });
  test('Location API uses device path, validates ranges and sends DTO', () async {
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        expect(request.url.path, '/api/Device/7/location');
        return http.Response('{"latitude":0,"longitude":0,"lastUpdatedLocation":null}', 200);
      }
      expect(request.url.path, '/api/Device/update-location');
      expect(jsonDecode(request.body), {'deviceId': 7, 'latitude': 10.762622, 'longitude': 106.660172});
      return http.Response('{}', 200);
    });
    final service = ViTriService(api: ApiClient(client: client));
    expect((await service.getLocation(7))['latitude'], 0);
    await service.updateLocation(7, 10.762622, 106.660172);
    await expectLater(service.updateLocation(7, 91, 106), throwsA(isA<ApiException>()));
    expect(ViTriService.mapsUri(10.762622, 106.660172).queryParameters['destination'], '10.762622,106.660172');
    client.close();
  });

  testWidgets('Empty location, confirmed mock send, refresh and Maps button work', (tester) async {
    final service = FakeLocation();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ViTriSheet(
      deviceId: 7, deviceName: 'Dien thoai be An', service: service))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Thiết bị chưa chia sẻ'), findsOneWidget);
    expect(find.text('Mở Google Maps'), findsNothing);
    await tester.ensureVisible(find.text('Gửi tọa độ mẫu (demo)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi tọa độ mẫu (demo)'));
    await tester.pumpAndSettle();
    expect(find.text('Gửi tọa độ mẫu?'), findsOneWidget);
    await tester.tap(find.text('Gửi vị trí'));
    await tester.pumpAndSettle();
    expect(service.sent, true);
    await tester.ensureVisible(find.text('Mở Google Maps'));
    await tester.pumpAndSettle();
    expect(find.text('10.762622, 106.660172'), findsOneWidget);
    await tester.tap(find.text('Mở Google Maps'));
    await tester.pumpAndSettle();
    expect(service.opened, true);
    expect(tester.takeException(), isNull);
  });
}
