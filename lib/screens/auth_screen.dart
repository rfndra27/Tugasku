import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AuthScreen extends StatefulWidget {
  final FirebaseService firebaseService;

  const AuthScreen({super.key, required this.firebaseService});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Register controllers
  final _regFullNameController = TextEditingController();
  final _regNimController = TextEditingController();
  final _regUniversityController = TextEditingController(text: 'Politeknik Negeri Jakarta');
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regPhoneController = TextEditingController();

  bool _rememberMe = false;
  bool _obscureLoginPassword = true;
  bool _obscureRegPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regFullNameController.dispose();
    _regNimController.dispose();
    _regUniversityController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identifier = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Email/Nomor Telepon dan kata sandi wajib diisi.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.firebaseService.signInWithIdentifierPassword(identifier, password);
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal masuk: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    final fullName = _regFullNameController.text.trim();
    final nim = _regNimController.text.trim();
    final university = _regUniversityController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text;
    final phone = _regPhoneController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      setState(() => _errorMessage = 'Mohon lengkapi seluruh field yang wajib diisi.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Kata sandi minimal 6 karakter.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.firebaseService.signUpWithEmailPassword(
        email: email,
        password: password,
        fullName: fullName,
        university: university,
        nim: nim,
        phone: phone,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mendaftar: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await widget.firebaseService.signInWithGoogle();
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal masuk dengan Google: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await widget.firebaseService.signInWithFacebook();
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal masuk dengan Facebook: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _loginEmailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan alamat email terdaftar kamu. Tautan reset kata sandi akan dikirim ke email tersebut.',
              style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                labelText: 'Email Address',
                hintText: 'nama@kampus.ac.id',
                prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF6B8E78)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B8E78),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await widget.firebaseService.sendPasswordResetEmail(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tautan reset kata sandi berhasil dikirim ke email kamu.'),
                      backgroundColor: Color(0xFF6B8E78),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengirim email reset: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  void _showEnterOtpDialog({required String verificationId}) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Masukkan Kode OTP', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kode OTP 6-digit telah dikirim ke nomor telepon Anda.'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFFF9FAFB),
                labelText: 'Kode OTP',
                hintText: '123456',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await widget.firebaseService.confirmPhoneOtp(
                  verificationId: verificationId,
                  smsCode: code,
                );
                if (mounted) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kode OTP salah: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Masuk'),
          ),
        ],
      ),
    );
  }

  void _showPhoneOtpDialog() {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Masukkan Nomor Telepon', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan nomor telepon yang terdaftar di akun kamu (dengan awalan 08 atau +62).',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFF9FAFB),
                  labelText: 'Nomor Telepon',
                  hintText: '081234567890 atau +628123456789',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              if (phone.isEmpty) return;
              Navigator.pop(ctx);
              try {
                if (kIsWeb) {
                  final result = await widget.firebaseService.sendPhoneOtpWeb(phone);
                  if (mounted) {
                    _showEnterOtpDialog(verificationId: result.verificationId);
                  }
                } else {
                  await widget.firebaseService.verifyPhoneOtpMobile(
                    phoneNumber: phone,
                    onCodeSent: (verificationId, resendToken) {
                      if (mounted) {
                        _showEnterOtpDialog(verificationId: verificationId);
                      }
                    },
                    onError: (msg) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal mengirim OTP: $msg'), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
                    onAutoVerified: (cred) {
                      if (mounted) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      }
                    },
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengirim OTP: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Kirim Kode OTP'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF151918),
      body: Stack(
        children: [
          // Radial glow at top right
          Positioned(
            top: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6B8E78).withValues(alpha: 0.38),
                      const Color(0xFF6B8E78).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 600;

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isDesktop ? 460 : double.infinity),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Dark Header Section
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () => Navigator.maybePop(context),
                                      borderRadius: BorderRadius.circular(22),
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_back_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.asset(
                                          'assets/images/logo.png',
                                          width: 46,
                                          height: 46,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                const Text(
                                  'Go ahead and set up\nyour account',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    height: 1.18,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in-up to enjoy the best managing experience',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.62),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // White Rounded Bottom Sheet Card
                          Container(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight > 220
                                  ? constraints.maxHeight - 200
                                  : 300,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: isDesktop
                                  ? BorderRadius.circular(34)
                                  : const BorderRadius.vertical(top: Radius.circular(34)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 28,
                                  offset: const Offset(0, -6),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 30),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Segmented Pill Switcher (Login | Register)
                                Container(
                                  height: 52,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F4F5),
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    indicator: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    labelColor: const Color(0xFF151918),
                                    unselectedLabelColor: const Color(0xFF6B7280),
                                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    dividerColor: Colors.transparent,
                                    tabs: const [
                                      Tab(text: 'Login'),
                                      Tab(text: 'Register'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Error Banner
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFFECACA)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Color(0xFF991B1B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Forms based on selected tab
                                if (_tabController.index == 0)
                                  _buildLoginForm()
                                else
                                  _buildRegisterForm(),

                                const SizedBox(height: 22),

                                // Primary Capsule Pill Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : (_tabController.index == 0 ? _handleLogin : _handleRegister),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6B8E78),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                          )
                                        : Text(
                                            _tabController.index == 0 ? 'Login' : 'Register',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Social Login Separator
                                Row(
                                  children: [
                                    const Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'Or login with',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Google, Telp, and Facebook Capsule Outlined Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(26),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              alignment: Alignment.center,
                                              child: const Text(
                                                'G',
                                                style: TextStyle(
                                                  color: Color(0xFFEA4335),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16,
                                                  fontFamily: 'serif',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Flexible(
                                              child: Text(
                                                'Gmail',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Color(0xFF374151),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _isLoading ? null : _showPhoneOtpDialog,
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(26),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.sms_outlined, color: Color(0xFF6B8E78), size: 18),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'No. Telp',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Color(0xFF6B8E78),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _isLoading ? null : _handleFacebookSignIn,
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(26),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.facebook_rounded, color: Color(0xFF1877F2), size: 18),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'Facebook',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Color(0xFF374151),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login_form'),
      children: [
        _buildStackedField(
          label: 'Email atau Nomor Telepon',
          controller: _loginEmailController,
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.text,
          hintText: 'nama@kampus.ac.id atau 0812xxxx',
        ),
        const SizedBox(height: 14),
        _buildStackedField(
          label: 'Password',
          controller: _loginPasswordController,
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscureText: _obscureLoginPassword,
          onToggleObscure: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
          hintText: '••••••••',
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 12),
        // Options row: Remember me & Forgot Password?
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: const Color(0xFF6B8E78),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    onChanged: (val) => setState(() => _rememberMe = val ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Remember me',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _showForgotPasswordDialog,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B8E78),
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B8E78),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('register_form'),
      children: [
        _buildStackedField(
          label: 'Full Name',
          controller: _regFullNameController,
          icon: Icons.person_outline_rounded,
          hintText: 'Nama lengkap mahasiswa',
        ),
        const SizedBox(height: 12),
        _buildStackedField(
          label: 'NIM / NPM',
          controller: _regNimController,
          icon: Icons.badge_outlined,
          hintText: 'Nomor induk mahasiswa (opsional)',
        ),
        const SizedBox(height: 12),
        _buildStackedField(
          label: 'University / Campus',
          controller: _regUniversityController,
          icon: Icons.school_outlined,
          hintText: 'Nama universitas / politeknik',
        ),
        const SizedBox(height: 12),
        _buildStackedField(
          label: 'Email Address',
          controller: _regEmailController,
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          hintText: 'nama@kampus.ac.id',
        ),
        const SizedBox(height: 12),
        _buildStackedField(
          label: 'Nomor Telepon / WhatsApp',
          controller: _regPhoneController,
          icon: Icons.phone_iphone_rounded,
          keyboardType: TextInputType.phone,
          hintText: '081234567890',
        ),
        const SizedBox(height: 12),
        _buildStackedField(
          label: 'Password',
          controller: _regPasswordController,
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscureText: _obscureRegPassword,
          onToggleObscure: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
          hintText: 'Minimal 6 karakter',
          onSubmitted: (_) => _handleRegister(),
        ),
      ],
    );
  }

  Widget _buildStackedField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
    String? hintText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B8E78), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  obscureText: isPassword && obscureText,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  onSubmitted: onSubmitted,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    fillColor: Colors.transparent,
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.normal,
                    ),
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          if (isPassword)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF9CA3AF),
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
        ],
      ),
    );
  }
}
