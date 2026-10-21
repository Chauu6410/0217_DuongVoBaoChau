import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duong_vo_bao_chau_kt/services/nhat_ky_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Diary is isolated per parent and same day updates instead of duplicates',
    () async {
      final parent = NhatKyService('parent-a');
      await parent.save('2026-10-21', {'mood': 'Vui vẻ', 'done': false});
      await parent.save('2026-10-21', {'mood': 'Bình thường', 'done': true});
      expect((await parent.load()).length, 1);
      expect((await parent.load())['2026-10-21']['done'], true);
      expect(await NhatKyService('parent-b').load(), isEmpty);
    },
  );

  test(
    'Summary counts only completed dates inside last seven calendar days',
    () {
      final data = <String, dynamic>{
        '2026-10-21': {'done': true},
        '2026-10-15': {'done': true},
        '2026-10-14': {'done': true},
        '2026-10-20': {'done': false},
      };
      expect(NhatKyService.soNgayHoanThanh(data, DateTime(2026, 10, 21)), 2);
      expect(NhatKyService.bayNgay(DateTime(2026, 1, 2)).last, '2025-12-27');
    },
  );
}
