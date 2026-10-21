import 'dart:async';

import 'package:flutter/material.dart';

import '../services/vi_tri_service.dart';
import '../widgets/app_ui.dart';

class ViTriSheet extends StatefulWidget {
  final int deviceId;
  final String deviceName;
  final ViTriService? service;
  const ViTriSheet({
    super.key,
    required this.deviceId,
    required this.deviceName,
    this.service,
  });
  @override
  State<ViTriSheet> createState() => _ViTriSheetState();
}

class _ViTriSheetState extends State<ViTriSheet> {
  late final ViTriService _service = widget.service ?? ViTriService();
  Map<String, dynamic>? _location;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getLocation(widget.deviceId);
      if (mounted) setState(() => _location = data);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send(bool mock) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(mock ? 'Gửi tọa độ mẫu?' : 'Gửi GPS máy đang chạy app?'),
        content: Text(
          mock
              ? 'Ghi tọa độ demo 10.762622, 106.660172 cho "${widget.deviceName}". Đây không phải vị trí thật.'
              : 'Lấy GPS từ máy đang mở app và lưu cho "${widget.deviceName}". Chỉ dùng thao tác này khi mô phỏng máy con.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gửi vị trí'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      double latitude = 10.762622, longitude = 106.660172;
      if (!mock) {
        final position = await _service.currentPosition();
        latitude = position.latitude;
        longitude = position.longitude;
      }
      await _service.updateLocation(widget.deviceId, latitude, longitude);
      if (!mounted) return;
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              mock ? 'Đã gửi vị trí mẫu (demo).' : 'Đã gửi vị trí hiện tại.',
            ),
          ),
        );
      }
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _error =
              'Chưa lấy được GPS trong 20 giây. Thử lại hoặc dùng tọa độ mẫu.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _time(dynamic raw) {
    if (raw is! String) return 'Chưa có thời gian cập nhật';
    // SQL datetime2 lưu UTC nhưng có thể trả chuỗi thiếu hậu tố Z.
    final normalized = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(raw)
        ? raw
        : '${raw}Z';
    final date = DateTime.tryParse(normalized)?.toLocal();
    if (date == null) return 'Chưa có thời gian cập nhật';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}:${two(date.second)}';
  }

  Future<void> _maps(double lat, double lng) async {
    setState(() => _busy = true);
    try {
      await _service.openMaps(lat, lng);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = (_location?['latitude'] as num?)?.toDouble();
    final lng = (_location?['longitude'] as num?)?.toDouble();
    final hasLocation =
        lat != null &&
        lng != null &&
        lat.isFinite &&
        lng.isFinite &&
        lat.abs() <= 90 &&
        lng.abs() <= 180;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFCFFAFE),
                  child: Icon(Icons.location_on, color: ocean),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.deviceName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  tooltip: 'Đóng',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (hasLocation) ...[
              const Text(
                'Vị trí được lưu gần nhất',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              SelectableText(
                '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ocean,
                ),
              ),
              const SizedBox(height: 8),
              Text('Cập nhật: ${_time(_location?['lastUpdatedLocation'])}'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _busy ? null : () => _maps(lat, lng),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Mở Google Maps'),
              ),
            ] else if (_error == null)
              const Text(
                'Thiết bị chưa chia sẻ vị trí. Hãy gửi GPS hoặc tọa độ mẫu để thử.',
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextButton.icon(
              onPressed: _busy || _loading ? null : _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại vị trí'),
            ),
            const Divider(height: 32),
            Text(
              'Mô phỏng máy con',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'GPS được lấy từ máy đang chạy app. Chức năng này không tự lấy GPS từ điện thoại khác.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy || _loading ? null : () => _send(false),
              icon: const Icon(Icons.my_location),
              label: Text(_busy ? 'Đang xử lý...' : 'Gửi vị trí hiện tại'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy || _loading ? null : () => _send(true),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Gửi tọa độ mẫu (demo)'),
            ),
          ],
        ),
      ),
    );
  }
}
