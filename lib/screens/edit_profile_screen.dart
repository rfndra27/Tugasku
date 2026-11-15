import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/image_picker_service.dart';
import '../providers/task_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final bool isEmbedded;

  const EditProfileScreen({super.key, this.isEmbedded = false});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _nimController;
  late final TextEditingController _semesterController;
  late final TextEditingController _universityController;
  late final TextEditingController _majorController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;

  int _selectedAvatarColor = 0xFF6B8E78;
  String? _photoData;
  bool _isSaving = false;

  static const List<int> _avatarColors = [
    0xFF6B8E78, // Sage Green
    0xFF8B5CF6, // Purple
    0xFF2563EB, // Blue
    0xFFF59E0B, // Amber
    0xFFEC4899, // Pink
    0xFF14B8A6, // Teal
  ];

  @override
  void initState() {
    super.initState();
    final profile = context.read<TaskProvider>().profile;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _nimController = TextEditingController(text: profile?.nim ?? '');
    _semesterController = TextEditingController(text: profile?.semester ?? '');
    _universityController = TextEditingController(
      text: (profile?.university.isNotEmpty == true)
          ? profile!.university
          : 'Politeknik Negeri Jakarta',
    );
    _majorController = TextEditingController(text: profile?.major ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _selectedAvatarColor = profile?.avatarColor ?? 0xFF6B8E78;
    _photoData = profile?.photoData;
  }

  Future<void> _pickPhoto() async {
    try {
      final result = await ProfileImageService.pickAndEncodeProfileImage();
      if (result == null) return;
      setState(() => _photoData = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _photoData = null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _semesterController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await context.read<TaskProvider>().updateProfile(
            fullName: _nameController.text.trim(),
            university: _universityController.text.trim(),
            nim: _nimController.text.trim(),
            major: _majorController.text.trim(),
            semester: _semesterController.text.trim(),
            phone: _phoneController.text.trim(),
            bio: _bioController.text.trim(),
            avatarColor: _selectedAvatarColor,
            photoData: _photoData,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui.'),
            backgroundColor: Color(0xFF6B8E78),
          ),
        );
        if (!widget.isEmbedded && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = context.watch<TaskProvider>().profile;

    final cardBg = isDark ? const Color(0xFF1E2623) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E3A34) : const Color(0xFFE5E7EB);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEmbedded ? 'Profil Mahasiswa' : 'Edit Profil Mahasiswa'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 1. Kartu Header Profil & Pemilih Warna Avatar
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    // Avatar Besar dengan Foto atau Inisial
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: Color(_selectedAvatarColor),
                            backgroundImage: ProfileImageService.decodeToProvider(_photoData),
                            child: ProfileImageService.decodeToProvider(_photoData) == null
                                ? Text(
                                    ProfileImageService.initial(
                                      _nameController.text.trim().isNotEmpty
                                          ? _nameController.text.trim()
                                          : profile?.fullName,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 34,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardBg, width: 2),
                            ),
                            child: const Icon(Icons.photo_camera_rounded, size: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tombol ubah/hapus foto
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: Text(_photoData == null ? 'Unggah Foto' : 'Ganti Foto'),
                        ),
                        if (_photoData != null)
                          TextButton.icon(
                            onPressed: _removePhoto,
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: const Text('Hapus'),
                            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Nama Lengkap & Email
                    Text(
                      _nameController.text.trim().isNotEmpty
                          ? _nameController.text.trim()
                          : (profile?.fullName ?? 'Mahasiswa TugasKu'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.email ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Deretan Badge Status (Streak, Status Akun, NIM)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusBadge(
                          icon: Icons.local_fire_department_rounded,
                          label: '🔥 Streak ${profile?.currentStreak ?? 0} Hari',
                          color: const Color(0xFFF97316),
                          isDark: isDark,
                        ),
                        _buildStatusBadge(
                          icon: profile?.isPremium == true
                              ? Icons.workspace_premium_rounded
                              : Icons.person_outline_rounded,
                          label: profile?.isPremium == true ? 'Akun Premium' : 'Akun Gratis',
                          color: profile?.isPremium == true ? const Color(0xFFEAB308) : const Color(0xFF6B8E78),
                          isDark: isDark,
                        ),
                        if (_nimController.text.trim().isNotEmpty || (profile?.nim.isNotEmpty == true))
                          _buildStatusBadge(
                            icon: Icons.badge_outlined,
                            label: 'NIM: ${_nimController.text.trim().isNotEmpty ? _nimController.text.trim() : profile!.nim}',
                            color: const Color(0xFF3B82F6),
                            isDark: isDark,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Pemilih 6 Warna Avatar
                    Text(
                      'Pilih Warna Avatar',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _avatarColors.map((colorVal) {
                        final isSelected = _selectedAvatarColor == colorVal;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAvatarColor = colorVal),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Color(colorVal),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: Color(colorVal).withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Kartu Form Informasi Akademik & Kontak
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Akademik & Kontak',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Email Akun (read-only)
                      TextFormField(
                        initialValue: profile?.email ?? '',
                        readOnly: true,
                        decoration: _inputDecoration(
                          label: 'Email Akun (Read-only)',
                          icon: Icons.email_outlined,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Nama Lengkap (wajib)
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(
                          label: 'Nama Lengkap *',
                          icon: Icons.person_outline_rounded,
                          isDark: isDark,
                          hintText: 'Nama lengkap kamu',
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Nama lengkap wajib diisi.' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),

                      // Baris 2 Kolom: NIM / NPM & Semester
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nimController,
                              decoration: _inputDecoration(
                                label: 'NIM / NPM',
                                icon: Icons.badge_outlined,
                                isDark: isDark,
                                hintText: '2107411001',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _semesterController,
                              decoration: _inputDecoration(
                                label: 'Semester',
                                icon: Icons.timeline_rounded,
                                isDark: isDark,
                                hintText: 'Semester 5',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Universitas / Kampus (wajib)
                      TextFormField(
                        controller: _universityController,
                        decoration: _inputDecoration(
                          label: 'Universitas / Kampus *',
                          icon: Icons.school_outlined,
                          isDark: isDark,
                          hintText: 'Politeknik Negeri Jakarta',
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Kampus wajib diisi.' : null,
                      ),
                      const SizedBox(height: 14),

                      // Program Studi / Kelas
                      TextFormField(
                        controller: _majorController,
                        decoration: _inputDecoration(
                          label: 'Program Studi / Kelas',
                          icon: Icons.class_outlined,
                          isDark: isDark,
                          hintText: 'Broadband Multimedia (BM - 5A)',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Nomor WhatsApp
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          label: 'Nomor WhatsApp (Remind WA)',
                          icon: Icons.chat_outlined,
                          isDark: isDark,
                          hintText: '628123456789',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Bio / Target Semester Ini (multiline 3 baris)
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          label: 'Bio / Target Semester Ini',
                          icon: Icons.edit_note_rounded,
                          isDark: isDark,
                          hintText: 'Contoh: Target IPK 3.8 & lulus tepat waktu!',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Simpan Perubahan
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B8E78),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_rounded, size: 20),
                          label: Text(
                            _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required bool isDark,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, color: const Color(0xFF6B8E78), size: 20),
      filled: true,
      fillColor: isDark ? const Color(0xFF151918).withValues(alpha: 0.5) : const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? const Color(0xFF2E3A34) : const Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? const Color(0xFF2E3A34) : const Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6B8E78), width: 1.5),
      ),
    );
  }
}
