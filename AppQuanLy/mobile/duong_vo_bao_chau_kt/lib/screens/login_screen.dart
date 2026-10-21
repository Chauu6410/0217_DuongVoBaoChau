import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/app_ui.dart';
import 'admin_screen.dart';
import 'staff_dashboard_screen.dart';
import 'home_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authService});
  final AuthService? authService;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  bool _loading = false;
  bool _hidePassword = true;
  bool _gettingOtp = false;
  String? _error;

  Future<void> _generateOtp() async {
    if (_username.text.trim().isEmpty || _password.text.isEmpty) {
      setState(
        () => _error = 'Nhập Username (email) và Password trước khi lấy OTP.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final username = _username.text.trim();
    final password = _password.text;
    setState(() {
      _gettingOtp = true;
      _error = null;
      _otp.clear();
    });
    try {
      final code = await (widget.authService ?? AuthService()).generateOTP(
        username,
        password,
      );
      if (!mounted) return;
      if (_username.text.trim() != username || _password.text != password) {
        return;
      }
      setState(() => _otp.text = code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: cyan,
          content: Text(
            'Mã OTP của bạn là: $code',
            style: const TextStyle(
              color: Color(0xFF083344),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _gettingOtp = false);
    }
  }

  Future<void> _openRegister() async {
    final email = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (!mounted || email == null) return;
    setState(() {
      _username.text = email;
      _password.clear();
      _otp.clear();
      _error = null;
    });
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final role = await (widget.authService ?? AuthService()).login(
        _username.text.trim(),
        _password.text,
        _otp.text.trim(),
      );
      if (!mounted) return;
      final Widget screen = switch (role) {
        'Admin' => const AdminScreen(),
        'Staff' => const StaffDashboardScreen(),
        _ => const HomeScreen(),
      };
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => screen),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const WelcomeBanner(
                  title: 'An tâm kết nối',
                  subtitle: 'Đồng hành cùng con trong thế giới số.',
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Chào mừng trở lại',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Đăng nhập để chăm sóc và quản lý thiết bị.',
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _username,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => _otp.clear(),
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              hintText: 'Email của bạn',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Nhập username'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _password,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => _otp.clear(),
                            obscureText: _hidePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _hidePassword
                                    ? 'Hiện mật khẩu'
                                    : 'Ẩn mật khẩu',
                                onPressed: () => setState(
                                  () => _hidePassword = !_hidePassword,
                                ),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Nhập password' : null,
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _otp,
                            textInputAction: TextInputAction.done,
                            keyboardType: TextInputType.number,
                            onFieldSubmitted: (_) {
                              if (!_loading && !_gettingOtp) _login();
                            },
                            decoration: InputDecoration(
                              labelText: 'OTP',
                              prefixIcon: const Icon(
                                Icons.verified_user_outlined,
                              ),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: TextButton(
                                  onPressed: _loading || _gettingOtp
                                      ? null
                                      : _generateOtp,
                                  child: Text(
                                    _gettingOtp ? 'Đang lấy...' : 'Lấy OTP',
                                  ),
                                ),
                              ),
                            ),
                            validator: (v) =>
                                RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '')
                                ? null
                                : 'OTP phải gồm đúng 6 chữ số',
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Nhập email và mật khẩu, sau đó nhấn Lấy OTP.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: SelectableText(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loading || _gettingOtp ? null : _login,
                            child: Text(
                              _loading ? 'Đang đăng nhập...' : 'Đăng nhập',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loading || _gettingOtp
                                ? null
                                : _openRegister,
                            child: const Text('Chưa có tài khoản? Đăng ký'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'QUẢN LÝ ĐIỆN THOẠI TRẺ EM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
