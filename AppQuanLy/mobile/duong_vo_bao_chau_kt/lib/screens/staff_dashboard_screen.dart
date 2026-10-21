import 'package:flutter/material.dart';

import '../config/config_url.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/app_ui.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  final ApiClient? api;
  final String title;
  const StaffDashboardScreen({
    super.key,
    this.api,
    this.title = 'Dashboard nhân viên',
  });
  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  List<Map<String, dynamic>> _devices = [];
  bool _loading = true;
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
      final result = await (widget.api ?? ApiClient()).get(Config_URL.devices);
      final list = result is Map ? result['data'] : result;
      if (list is! List) throw Exception('API chưa trả về danh sách thiết bị.');
      final devices = list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (mounted) setState(() => _devices = devices);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _manage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen(management: true)),
    );
    if (mounted) await _load();
  }

  int _battery(Map<String, dynamic> device) =>
      (device['batteryLevel'] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final active = _devices
        .where((d) => d['isLocked'] != true && _battery(d) > 0)
        .length;
    final low = _devices.where((d) => _battery(d) <= 20).length;
    final warnings =
        _devices
            .where((d) => d['isLocked'] == true || _battery(d) <= 20)
            .toList()
          ..sort((a, b) => _battery(a).compareTo(_battery(b)));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(onPressed: _load, child: const Text('Thử lại')),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  WelcomeBanner(
                    title: widget.title == 'Báo cáo thống kê'
                        ? 'Tổng quan hệ thống'
                        : 'Xin chào, Nhân viên!',
                    subtitle: 'Chủ động theo dõi, kịp thời hỗ trợ.',
                    icon: Icons.insights_rounded,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _stat(
                          'Tổng thiết bị',
                          _devices.length,
                          Icons.devices_rounded,
                          ocean,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _stat(
                          'Đang hoạt động',
                          active,
                          Icons.check_circle_outline,
                          const Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _stat(
                          'Cảnh báo pin',
                          low,
                          Icons.battery_alert_rounded,
                          const Color(0xFFC2410C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Hoạt động: chưa khóa và còn pin. Cảnh báo pin: ≤ 20%.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _manage,
                    icon: const Icon(Icons.settings_cell),
                    label: const Text('Quản lý danh sách thiết bị'),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Cảnh báo thiết bị hiện tại',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ưu tiên thiết bị có mức pin thấp.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  if (warnings.isEmpty)
                    const Card(
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Icon(
                          Icons.verified_outlined,
                          color: Color(0xFF15803D),
                        ),
                        title: Text('Không có cảnh báo'),
                        subtitle: Text(
                          'Các thiết bị đang ở trạng thái ổn định.',
                        ),
                      ),
                    ),
                  for (final device in warnings.take(10))
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFF7ED),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFC2410C),
                          ),
                        ),
                        title: Text(
                          device['deviceName']?.toString() ?? 'Thiết bị',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          [
                            if (_battery(device) <= 20)
                              'Pin yếu: ${_battery(device)}%',
                            if (device['isLocked'] == true)
                              'Thiết bị đang bị khóa',
                          ].join('\n'),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _manage,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _stat(String label, int value, IconData icon, Color color) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 42,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}
