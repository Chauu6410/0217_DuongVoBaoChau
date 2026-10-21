import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/config_url.dart';
import 'api_client.dart';

class ViTriService {
  final ApiClient api;
  ViTriService({ApiClient? api}) : api = api ?? ApiClient();

  Future<Map<String, dynamic>> getLocation(int deviceId) async {
    final data = await api.get('${Config_URL.devices}/$deviceId/location');
    if (data is! Map) throw ApiException('API chưa trả về thông tin vị trí.');
    return Map<String, dynamic>.from(data);
  }

  Future<void> updateLocation(
    int deviceId,
    double latitude,
    double longitude,
  ) async {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      throw ApiException('Tọa độ không hợp lệ.');
    }
    await api.post('${Config_URL.devices}/update-location', {
      'deviceId': deviceId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw ApiException(
        'GPS đang tắt. Hãy bật Vị trí trong cài đặt thiết bị.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw ApiException(
        'Quyền vị trí bị từ chối vĩnh viễn. Hãy mở Cài đặt ứng dụng để cấp lại quyền.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw ApiException('Bạn chưa cấp quyền vị trí.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  static Uri mapsUri(double latitude, double longitude) => Uri.https(
    'www.google.com',
    '/maps/dir/',
    {'api': '1', 'destination': '$latitude,$longitude'},
  );

  Future<void> openMaps(double latitude, double longitude) async {
    if (!await launchUrl(
      mapsUri(latitude, longitude),
      mode: LaunchMode.externalApplication,
    )) {
      throw ApiException(
        'Không mở được Google Maps. Hãy kiểm tra ứng dụng bản đồ hoặc trình duyệt.',
      );
    }
  }
}
