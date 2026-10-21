import 'package:flutter/material.dart';

import 'dart:async';

import '../config/config_url.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/app_ui.dart';
import 'login_screen.dart';
import 'dong_hanh_screen.dart';
import 'vi_tri_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.management = false, this.api});
  final ApiClient? api;
  final bool management;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final ApiClient _api = widget.api ?? ApiClient();
  List<Map<String, dynamic>> _devices = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Timer? _syncTimer;
  bool _fetching = false;
  bool _dialogOpen = false;
  List<Map<String, dynamic>> _parents = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDevices();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_saving &&
          !_dialogOpen &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          ModalRoute.of(context)?.isCurrent == true) {
        _loadDevices(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_saving && !_dialogOpen) {
      _loadDevices(silent: true);
    }
  }

  Future<void> _loadDevices({bool silent = false}) async {
    if (_fetching) return;
    _fetching = true;
    setState(() {
      if (!silent) _loading = true;
      _error = null;
    });
    try {
      final result = await _api.get(Config_URL.devices);
      final list = result is Map ? result['data'] : result;
      if (list is! List) throw Exception('API phải trả về danh sách Device.');
      final devices = list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (mounted) setState(() => _devices = devices);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      _fetching = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _editDevice([Map<String, dynamic>? device]) async {
    if (_dialogOpen || _saving) return;
    if (widget.management) {
      setState(() => _saving = true);
      try {
        final result = await _api.get('${Config_URL.devices}/parents');
        if (result is! List) {
          throw Exception('Không tải được danh sách phụ huynh.');
        }
        _parents = result
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (e) {
        _message('$e');
        return;
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      if (!mounted) return;
    }
    _dialogOpen = true;
    String? ownerId = device?['userId']?.toString();
    final form = GlobalKey<FormState>();
    // Dùng initialValue/onSaved để không cần quản lý controller của dialog.
    String name = device?['deviceName']?.toString() ?? '';
    bool locked = device?['isLocked'] == true;
    int battery = (device?['batteryLevel'] as num?)?.toInt() ?? 100;
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(device == null ? 'Thêm thiết bị' : 'Sửa thiết bị'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.management) ...[
                  DropdownButtonFormField<String>(
                    initialValue: ownerId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Phụ huynh sở hữu',
                      prefixIcon: Icon(Icons.family_restroom),
                    ),
                    items: [
                      if (ownerId != null &&
                          !_parents.any((p) => p['id'] == ownerId))
                        DropdownMenuItem(
                          value: ownerId,
                          child: const Text('Chưa gán phụ huynh'),
                        ),
                      for (final parent in _parents)
                        DropdownMenuItem<String>(
                          value: parent['id']?.toString(),
                          child: Text(
                            '${parent['email']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => ownerId = value,
                    validator: (value) => value == null
                        ? 'Hãy chọn phụ huynh sở hữu thiết bị'
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
                StatefulBuilder(
                  builder: (context, updateSwitch) => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Khóa thiết bị'),
                    value: locked,
                    onChanged: (value) => updateSwitch(() => locked = value),
                  ),
                ),
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(
                    labelText: 'Tên thiết bị',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nhập tên thiết bị'
                      : null,
                  onSaved: (v) => name = v!.trim(),
                ),
                TextFormField(
                  initialValue: '$battery',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Mức pin (%)',
                    prefixIcon: Icon(Icons.battery_charging_full),
                  ),
                  validator: (v) {
                    final number = int.tryParse(v ?? '');
                    return number == null || number < 0 || number > 100
                        ? 'Nhập số từ 0 đến 100'
                        : null;
                  },
                  onSaved: (v) => battery = int.parse(v!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              form.currentState!.save();
              Navigator.pop(dialogContext, <String, dynamic>{
                if (device != null) 'id': device['id'],
                'deviceName': name,

                'batteryLevel': battery,
                'isLocked': locked,
              });
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
    if (data == null || !mounted) return;
    setState(() => _saving = true);
    try {
      data['userId'] = widget.management
          ? ownerId!
          : await AuthService().currentUserId();
      if (device == null) {
        await _api.post(Config_URL.devices, data);
      } else {
        await _api.put(_devicePath(device), data);
      }
      _message('Đã lưu thiết bị.');
      if (mounted) await _loadDevices();
    } catch (e) {
      _message('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _devicePath(Map<String, dynamic> device) {
    final id = device['id'];
    if (id == null) throw Exception('Thiết bị thiếu id.');
    return '${Config_URL.devices}/${Uri.encodeComponent(id.toString())}';
  }

  Future<void> _deleteDevice(Map<String, dynamic> device) async {
    _dialogOpen = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa thiết bị'),
        content: Text('Xóa thiết bị "${device['deviceName']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _api.delete(_devicePath(device));
      _message('Đã xóa thiết bị.');
      if (mounted) await _loadDevices();
    } catch (e) {
      _message('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
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
      _message('$e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.management ? 'Quản lý thiết bị' : 'Gia đình an tâm'),
      actions: [
        IconButton(
          onPressed: _loading || _saving ? null : _loadDevices,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Tải lại',
        ),
        IconButton(
          onPressed: _saving ? null : _logout,
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
                  const Icon(Icons.cloud_off_outlined, size: 48, color: ocean),
                  const SizedBox(height: 16),
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _loadDevices,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          )
        : RefreshIndicator(
            onRefresh: () async {
              if (!_saving) await _loadDevices();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                WelcomeBanner(
                  title: widget.management
                      ? 'Không gian quản lý'
                      : 'Xin chào, Phụ huynh!',
                  subtitle: widget.management
                      ? 'Theo dõi và chăm sóc mọi thiết bị.'
                      : 'An toàn của con, bình yên của cả nhà.',
                  icon: widget.management
                      ? Icons.devices_rounded
                      : Icons.person_outline,
                ),
                const SizedBox(height: 24),
                if (!widget.management)
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFCFFAFE),
                        child: Icon(Icons.favorite_outline, color: ocean),
                      ),
                      title: const Text(
                        'Đồng hành cùng con',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Cảm xúc • Thử thách • Nhật ký 7 ngày',
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_rounded,
                        color: ocean,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DongHanhScreen(),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Danh sách thiết bị',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    StatusBadge('${_devices.length} thiết bị', color: ocean),
                  ],
                ),
                const SizedBox(height: 16),
                if (_saving) const LinearProgressIndicator(),
                if (_devices.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.add_to_home_screen, size: 48, color: cyan),
                          SizedBox(height: 16),
                          Text(
                            'Chưa có thiết bị',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Thêm thiết bị đầu tiên để bắt đầu đồng hành.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                for (final device in _devices) _deviceCard(device),
              ],
            ),
          ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _saving || _loading ? null : () => _editDevice(),
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Thêm thiết bị',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );

  Widget _deviceCard(Map<String, dynamic> device) {
    final battery = (device['batteryLevel'] as num?)?.toInt() ?? 0;
    final locked = device['isLocked'] == true;
    final offline = device['isOnline'] == false;
    final status = offline
        ? 'Ngoại tuyến'
        : locked
        ? 'Đang khóa'
        : 'Hoạt động';
    final color = offline
        ? const Color(0xFF64748B)
        : locked
        ? const Color(0xFFC2410C)
        : const Color(0xFF15803D);
    final batteryColor = battery <= 20
        ? const Color(0xFFDC2626)
        : const Color(0xFF15803D);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFEFF6FF),
              child: Icon(Icons.phone_android, color: ocean),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${device['deviceName'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: _saving
                        ? null
                        : () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            constraints: const BoxConstraints(maxWidth: 600),
                            builder: (_) => ViTriSheet(
                              deviceId: (device['id'] as num).toInt(),
                              deviceName:
                                  device['deviceName']?.toString() ??
                                  'Thiết bị',
                            ),
                          ),
                    icon: const Icon(Icons.location_on, size: 18),
                    label: const Text('Xem vị trí'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        battery <= 20
                            ? Icons.battery_alert_rounded
                            : Icons.battery_full_rounded,
                        size: 18,
                        color: batteryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$battery%',
                        style: TextStyle(
                          color: batteryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: battery.clamp(0, 100) / 100,
                      minHeight: 4,
                      color: batteryColor,
                      backgroundColor: const Color(0xFFE2E8F0),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status, color: color),
                PopupMenuButton<String>(
                  enabled: !_saving,
                  tooltip: 'Thao tác thiết bị',
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editDevice(device);
                    } else {
                      _deleteDevice(device);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Sửa'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Xóa'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
