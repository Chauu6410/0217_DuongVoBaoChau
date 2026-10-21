import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/app_ui.dart';
import '../config/config_url.dart';
import 'staff_dashboard_screen.dart';
import 'login_screen.dart';
import 'tai_khoan_screen.dart';
import 'home_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService().logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final features = <(IconData, String, String, Color, VoidCallback)>[
      (
        Icons.people_outline,
        'Quản lý người dùng',
        'Tài khoản & phân quyền',
        ocean,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TaiKhoanScreen()),
        ),
      ),
      (
        Icons.badge_outlined,
        'Quản lý nhân viên',
        'Đội ngũ hỗ trợ',
        const Color(0xFF0891B2),
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TaiKhoanScreen(role: 'Staff'),
          ),
        ),
      ),
      (
        Icons.devices_rounded,
        'Quản lý danh mục thiết bị',
        'Danh sách & trạng thái',
        const Color(0xFF7C3AED),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen(management: true)),
        ),
      ),
      (
        Icons.tune_rounded,
        'Cấu hình hệ thống',
        'Thông tin kết nối',
        const Color(0xFFB45309),
        () => showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cấu hình hệ thống'),
            content: SelectableText(
              'API: ${Config_URL.baseUrl}\n\nGiao diện: Material Design 3\nPin yếu: từ 20% trở xuống\n\nĐịa chỉ API được cấu hình trong .env.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      ),
      (
        Icons.bar_chart_rounded,
        'Báo cáo Thống kê',
        'Tổng quan thiết bị',
        const Color(0xFF15803D),
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const StaffDashboardScreen(title: 'Báo cáo thống kê'),
          ),
        ),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Quản trị hệ thống')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const WelcomeBanner(
            title: 'Xin chào, Admin',
            subtitle: 'Một nơi để kết nối, quản lý và bảo vệ.',
            icon: Icons.admin_panel_settings_outlined,
          ),
          const SizedBox(height: 24),
          Text(
            'Không gian quản trị',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, size) {
              final width = size.maxWidth < 300
                  ? size.maxWidth
                  : (size.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final feature in features)
                    SizedBox(
                      width: width,
                      child: Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: feature.$5,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: feature.$4.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Icon(feature.$1, color: feature.$4),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  feature.$2,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  feature.$3,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: feature.$4,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
