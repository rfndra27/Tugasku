import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/task_provider.dart';

class ElearningSyncDialog extends StatefulWidget {
  const ElearningSyncDialog({super.key});

  @override
  State<ElearningSyncDialog> createState() => _ElearningSyncDialogState();
}

class _ElearningSyncDialogState extends State<ElearningSyncDialog> {
  final _urlController = TextEditingController();
  String _selectedPlatform = 'Moodle LMS';
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  final List<String> _platforms = ['Moodle LMS', 'Canvas LMS', 'Google Classroom', 'Lainnya'];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleFileImport() async {
    try {
      final provider = context.read<TaskProvider>();
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ics'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) throw Exception('File .ics tidak dapat dibaca atau kosong.');
      setState(() {
        _isLoading = true;
        _statusMessage = null;
      });
      await provider.importIcalContent(String.fromCharCodes(bytes), platform: _selectedPlatform);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _statusMessage = 'File ${file.name} berhasil diimpor ke daftar tugas.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleSync() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _statusMessage = 'URL kalender iCal (.ics) tidak boleh kosong.');
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() => _statusMessage = 'URL harus diawali dengan http:// atau https://');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final provider = context.read<TaskProvider>();
      final result = await provider.syncElearning(url, platform: _selectedPlatform);

      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _statusMessage = result.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF475569);
    final borderColor = isDark ? AppConstants.borderSubtleColor : const Color(0xFFD8E4F2);
    final infoBg = isDark ? AppConstants.inputColor : const Color(0xFFF1F5F9);

    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      title: Row(
        children: [
          const Icon(Icons.sync_rounded, color: AppConstants.primaryColor),
          const SizedBox(width: 8),
          Text('Sinkron E-Learning', style: TextStyle(fontWeight: FontWeight.bold, color: onSurface)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Impor semua tugas kuliah secara otomatis dari Moodle, Canvas, atau Classroom menggunakan link kalender iCal (.ics).',
              style: TextStyle(fontSize: 12, color: onSurfaceSecondary),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedPlatform,
              dropdownColor: Theme.of(context).cardColor,
              style: TextStyle(color: onSurface),
              decoration: const InputDecoration(labelText: 'Platform E-Learning Kampus'),
              items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: onSurface)))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedPlatform = val);
              },
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _urlController,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: 'URL Ekspor iCal (.ics)',
                hintText: 'https://elearning.kampus.ac.id/calendar/export_execute.php?...',
                prefixIcon: Icon(Icons.link_rounded, color: onSurfaceSecondary),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleFileImport,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Pilih file .ics dari perangkat'),
              ),
            ),
            const SizedBox(height: 12),

            // Tip on how to find iCal link
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: infoBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 Cara mendapatkan link iCal Moodle:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurface)),
                  const SizedBox(height: 4),
                  Text(
                    '1. Buka Kalender di e-learning kampus.\n2. Klik tombol "Export Calendar" di bagian bawah.\n3. Pilih "All events" & "Recent and next 60 days".\n4. Klik "Get calendar URL" lalu salin ke sini.',
                    style: TextStyle(fontSize: 11, color: onSurfaceSecondary),
                  ),
                ],
              ),
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? (isDark ? const Color(0xFF123022) : const Color(0xFFDCFCE7))
                      : (isDark ? const Color(0xFF35191D) : const Color(0xFFFEE2E2)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess ? AppConstants.successColor.withValues(alpha: 0.5) : AppConstants.errorColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                      color: _isSuccess ? AppConstants.successColor : AppConstants.errorColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isSuccess
                              ? (isDark ? const Color(0xFF8CF4AF) : const Color(0xFF15803D))
                              : (isDark ? const Color(0xFFFF8B8D) : const Color(0xFFB91C1C)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Tutup', style: TextStyle(color: onSurfaceSecondary))),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSync,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Mulai Sinkronisasi'),
        ),
      ],
    );
  }
}
