import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/nhat_ky_service.dart';

class DongHanhScreen extends StatefulWidget {
  const DongHanhScreen({super.key});
  @override
  State<DongHanhScreen> createState() => _DongHanhScreenState();
}

class _DongHanhScreenState extends State<DongHanhScreen> {
  static const _camXuc = ['Vui vẻ', 'Bình thường', 'Cần được lắng nghe'];
  static const _hoatDong = [
    'Đọc sách cùng con 15 phút',
    'Đi bộ cùng nhau 20 phút',
    'Một bữa ăn không điện thoại',
    'Trò chuyện với con 10 phút',
  ];
  final _note = TextEditingController();
  NhatKyService? _service;
  Map<String, dynamic> _entries = {};
  String? _mood;
  String _activity = _hoatDong.first;
  bool _done = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _date = NhatKyService.ngay(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = await AuthService().currentUserId();
      final service = NhatKyService(id);
      final data = await service.load();
      if (!mounted) return;
      _date = NhatKyService.ngay(DateTime.now());
      final today = data[_date] is Map ? data[_date] as Map : {};
      setState(() {
        _service = service;
        _entries = data;
        _mood = _camXuc.contains(today['mood'])
            ? today['mood'] as String
            : null;
        _activity = _hoatDong.contains(today['activity'])
            ? today['activity'] as String
            : _hoatDong.first;
        _done = today['done'] == true;
        _note.text = today['note']?.toString() ?? '';
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_mood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn cảm xúc hôm nay.')),
      );
      return;
    }
    if (NhatKyService.ngay(DateTime.now()) != _date) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã sang ngày mới. Hãy nhập nhật ký hôm nay.'),
          ),
        );
      }
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final entry = <String, dynamic>{
      'mood': _mood,
      'activity': _activity,
      'done': _done,
      'note': _note.text.trim(),
    };
    try {
      await _service!.save(_date, entry);
      if (!mounted) return;
      setState(() => _entries[_date] = entry);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu nhật ký hôm nay.')));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = NhatKyService.bayNgay(DateTime.now());
    final completed = NhatKyService.soNgayHoanThanh(_entries, DateTime.now());
    return Scaffold(
      appBar: AppBar(title: const Text('Đồng hành cùng con')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _service == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error ?? 'Chưa tải được nhật ký.'),
                  TextButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Mỗi ngày một khoảng thời gian bên nhau',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Phụ huynh ghi nhận sau khi trò chuyện với con. Nhật ký được lưu riêng cho tài khoản trên thiết bị này.',
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hôm nay • $_date',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        const Text('Con đang cảm thấy thế nào?'),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final mood in _camXuc)
                              ChoiceChip(
                                label: Text(mood),
                                selected: _mood == mood,
                                onSelected: _saving
                                    ? null
                                    : (_) => setState(() => _mood = mood),
                              ),
                          ],
                        ),
                        if (_mood == 'Cần được lắng nghe')
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Gợi ý: dành vài phút nghe con kể chuyện, hỏi điều con mong muốn ở bố mẹ.',
                            ),
                          ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_date),
                          initialValue: _activity,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Thử thách không màn hình',
                          ),
                          items: _hoatDong
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(
                                    a,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() {
                                  _activity = value!;
                                  _done = false;
                                }),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Đã hoàn thành cùng con'),
                          value: _done,
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _done = value),
                        ),
                        TextField(
                          controller: _note,
                          enabled: !_saving,
                          maxLength: 500,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Một điều muốn ghi nhớ',
                            hintText:
                                'Ví dụ: hôm nay con thích buổi đi bộ cùng mẹ.',
                          ),
                        ),
                        if (_error != null)
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: const Icon(Icons.save),
                          label: Text(_saving ? 'Đang lưu...' : 'Lưu hôm nay'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '7 ngày gần nhất • Hoàn thành $completed/7 ngày',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: completed / 7),
                const SizedBox(height: 8),
                for (final date in dates)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        _entries[date]?['done'] == true
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: _entries[date]?['done'] == true
                            ? Colors.teal
                            : Colors.grey,
                      ),
                      title: Text(
                        '$date • ${_entries[date]?['mood'] ?? 'Chưa ghi nhận'}',
                      ),
                      subtitle: Text(
                        _entries[date] == null
                            ? 'Chưa có nhật ký'
                            : '${_entries[date]['activity']}\n${_entries[date]['note'] ?? ''}',
                      ),
                      isThreeLine: _entries[date] != null,
                    ),
                  ),
              ],
            ),
    );
  }
}
