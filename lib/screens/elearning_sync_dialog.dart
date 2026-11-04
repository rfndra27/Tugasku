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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ics'],
        withData: true,
      );
      if (result == null) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) throw Exception('File .ics tidak dapat dibaca.');
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
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppConstants.borderSubtleColor),
      ),
      title: Row(
        children: const [
          Icon(Icons.sync_rounded, color: AppConstants.primaryColor),
          SizedBox(width: 8),
          Text('Sinkron E-Learning', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Impor semua tugas kuliah secara otomatis dari Moodle, Canvas, atau Classroom menggunakan link kalender iCal (.ics).',
              style: TextStyle(fontSize: 12, color: AppConstants.textSecondaryColor),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedPlatform,
              dropdownColor: AppConstants.cardColor,
              style: const TextStyle(color: AppConstants.textPrimaryColor),
              decoration: const InputDecoration(labelText: 'Platform E-Learning Kampus'),
              items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: AppConstants.textPrimaryColor)))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedPlatform = val);
              },
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _urlController,
              style: const TextStyle(color: AppConstants.textPrimaryColor),
              decoration: const InputDecoration(
                labelText: 'URL Ekspor iCal (.ics)',
                hintText: 'https://elearning.kampus.ac.id/calendar/export_execute.php?...',
                prefixIcon: Icon(Icons.link_rounded, color: AppConstants.textSecondaryColor),
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
                color: AppConstants.inputColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppConstants.borderSubtleColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('💡 Cara mendapatkan link iCal Moodle:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor)),
                  SizedBox(height: 4),
                  Text(
                    '1. Buka Kalender di e-learning kampus.\n2. Klik tombol "Export Calendar" di bagian bawah.\n3. Pilih "All events" & "Recent and next 60 days".\n4. Klik "Get calendar URL" lalu salin ke sini.',
                    style: TextStyle(fontSize: 11, color: AppConstants.textSecondaryColor),
                  ),
                ],
              ),
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isSuccess ? const Color(0xFF123022) : const Color(0xFF35191D),
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
                          color: _isSuccess ? const Color(0xFF8CF4AF) : const Color(0xFFFF8B8D),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup', style: TextStyle(color: AppConstants.textSecondaryColor))),
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
