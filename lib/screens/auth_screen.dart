import 'package:flutter/material.dart';
import '../core/constants.dart';
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
  final _regUniversityController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regFullNameController.dispose();
    _regUniversityController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Email dan kata sandi wajib diisi.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.firebaseService.signInWithEmailPassword(email, password);
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
    final university = _regUniversityController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Branding Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppConstants.textPrimaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    AppConstants.appTagline,
                    style: TextStyle(fontSize: 14, color: AppConstants.textSecondaryColor),
                  ),
                  const SizedBox(height: 32),

                  // Error Box if any
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E191B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.errorColor.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppConstants.errorColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: 12, color: Color(0xFFFF8B8D)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Tab switcher (Masuk / Daftar)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppConstants.borderSubtleColor),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppConstants.textSecondaryColor,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Masuk'),
                        Tab(text: 'Daftar Akun'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab views
                  SizedBox(
                    height: 380,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // 1. LOGIN TAB
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _loginEmailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: AppConstants.textPrimaryColor),
                              decoration: const InputDecoration(
                                labelText: 'Email Mahasiswa',
                                hintText: 'nama@kampus.ac.id',
                                prefixIcon: Icon(Icons.email_outlined, color: AppConstants.textSecondaryColor),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _loginPasswordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: AppConstants.textPrimaryColor),
                              decoration: InputDecoration(
                                labelText: 'Kata Sandi',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppConstants.textSecondaryColor),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: AppConstants.textSecondaryColor,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('Masuk ke TugasKu'),
                            ),
                          ],
                        ),

                        // 2. REGISTER TAB
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _regFullNameController,
                                style: const TextStyle(color: AppConstants.textPrimaryColor),
                                decoration: const InputDecoration(
                                  labelText: 'Nama Lengkap',
                                  hintText: 'Ahmad Mahasiswa',
                                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppConstants.textSecondaryColor),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _regUniversityController,
                                style: const TextStyle(color: AppConstants.textPrimaryColor),
                                decoration: const InputDecoration(
                                  labelText: 'Nama Kampus / Universitas',
                                  hintText: 'Universitas Indonesia',
                                  prefixIcon: Icon(Icons.school_outlined, color: AppConstants.textSecondaryColor),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _regEmailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: AppConstants.textPrimaryColor),
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'nama@kampus.ac.id',
                                  prefixIcon: Icon(Icons.email_outlined, color: AppConstants.textSecondaryColor),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _regPasswordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: AppConstants.textPrimaryColor),
                                decoration: InputDecoration(
                                  labelText: 'Kata Sandi (min 6 karakter)',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppConstants.textSecondaryColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: AppConstants.textSecondaryColor,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text('Buat Akun Mahasiswa'),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}
