import 'dart:ui' show ImageFilter;
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
  final _regUniversityController = TextEditingController(text: 'Politeknik Negeri Jakarta');
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
      body: Stack(
        children: [
          // 1. Campus / PUT Building Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_gedung_pnj.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Cinematic & Atmospheric Soft Gradient Tint
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0F172A).withValues(alpha: 0.78),
                    const Color(0xFF0F172A).withValues(alpha: 0.55),
                    const Color(0xFF003E7E).withValues(alpha: 0.45),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // 3. Responsive & Ergonomic Layout
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWide ? 1150 : 440,
                      ),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left Hero Section (Human & Empathetic Student Branding)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 50),
                                    child: _buildLeftHeroSection(),
                                  ),
                                ),

                                // Right Floating Glassmorphic Login Card
                                SizedBox(
                                  width: 420,
                                  child: _buildGlassLoginCard(),
                                ),
                              ],
                            )
                          : _buildGlassLoginCard(),
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

  Widget _buildLeftHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Friendly Campus Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_rounded, color: Color(0xFF93C5FD), size: 18),
              SizedBox(width: 8),
              Text(
                'POLITEKNIK NEGERI JAKARTA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Empathetic Main Headline
        const Text(
          'Kuliah Lebih Rapi & Santai, Bebas Panik Deadline.',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.2,
            letterSpacing: -0.8,
            shadows: [
              Shadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 4)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Friendly Subtitle
        const Text(
          'Satu tempat asisten cerdas untuk merapikan tugas e-learning, jadwal kuliah harian, dan kerja kelompokmu.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFFE2E8F0),
            height: 1.5,
            shadows: [
              Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3 Human Feature Highlights
        _buildHeroFeatureItem(
          icon: Icons.timer_outlined,
          iconColor: const Color(0xFFFBBF24),
          title: 'Prioritas Otomatis Tanpa Pusing',
          subtitle: 'Tugas diurutkan otomatis dari yang paling mendesak dan berbobot nilai tinggi.',
        ),
        const SizedBox(height: 12),
        _buildHeroFeatureItem(
          icon: Icons.auto_awesome_rounded,
          iconColor: const Color(0xFF60A5FA),
          title: 'Input Pintar AI Bahasa Indonesia',
          subtitle: 'Cukup copas pesan tugas dari dosen di WhatsApp, otomatis tercatat rapi.',
        ),
        const SizedBox(height: 12),
        _buildHeroFeatureItem(
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: const Color(0xFF34D399),
          title: 'Pengingat WhatsApp Ramah & Sopan',
          subtitle: 'Ingatkan teman sekelompok langsung ke WA dengan pesan yang santun.',
        ),
      ],
    );
  }

  Widget _buildHeroFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 32,
                offset: const Offset(0, 14),
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Friendly & Clean Branding
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    AppConstants.appTagline,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Friendly Welcoming Message Box
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  children: [
                    Text('👋', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Halo, Mahasiswa! Siap atur tugasmu hari ini?',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Soft Pill-Shaped Segmented Tab Switcher
              Container(
                height: 38,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF0060B6),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0060B6).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF475569),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Masuk'),
                    Tab(text: 'Daftar Akun'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Tab content
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  return _tabController.index == 0
                      ? _buildLoginView()
                      : _buildRegisterView();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email / NIM Field
        const Text(
          'Email Mahasiswa',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: 'nama@kampus.ac.id atau NIM',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF64748B), size: 17),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0060B6), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Password Field
        const Text(
          'Kata Sandi',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _loginPasswordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: 'Masukkan kata sandi',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 17),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF64748B),
                size: 19,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0060B6), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Primary Blue Button
        SizedBox(
          height: 44,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0060B6),
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: const Color(0xFF0060B6).withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Masuk ke TugasKu',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Full Name
        const Text(
          'Nama Lengkap',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _regFullNameController,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
          decoration: _inputDecoration(
            hint: 'Ahmad Mahasiswa',
            icon: Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(height: 8),

        // University Name
        const Text(
          'Nama Kampus / Universitas',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _regUniversityController,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
          decoration: _inputDecoration(
            hint: 'Politeknik Negeri Jakarta',
            icon: Icons.school_outlined,
          ),
        ),
        const SizedBox(height: 8),

        // Email
        const Text(
          'Email Mahasiswa',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _regEmailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
          decoration: _inputDecoration(
            hint: 'nama@stu.pnj.ac.id',
            icon: Icons.alternate_email_rounded,
          ),
        ),
        const SizedBox(height: 8),

        // Password
        const Text(
          'Kata Sandi',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _regPasswordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
          decoration: _inputDecoration(
            hint: 'Minimal 6 karakter',
            icon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF64748B),
                size: 18,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Register Button
        SizedBox(
          height: 42,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0060B6),
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: const Color(0xFF0060B6).withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isLoading ? null : _handleRegister,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Buat Akun Mahasiswa',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.check_circle_outline_rounded, size: 16),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 17),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0060B6), width: 1.5),
      ),
    );
  }
}
