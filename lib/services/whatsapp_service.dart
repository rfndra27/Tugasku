import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// Normalizes any Indonesian phone number format to standard 628xxx format
  /// Examples:
  /// - "08123456789" -> "628123456789"
  /// - "+62 812-3456-789" -> "628123456789"
  /// - "8123456789" -> "628123456789"
  static String normalizeIndonesianPhoneNumber(String rawPhone) {
    String clean = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');

    if (clean.startsWith('0')) {
      clean = '62${clean.substring(1)}';
    } else if (clean.startsWith('8')) {
      clean = '62$clean';
    } else if (clean.startsWith('62')) {
      // already good
    }

    return clean;
  }

  /// Generates a friendly Indonesian WhatsApp reminder template and opens wa.me
  static Future<bool> sendSubtaskReminder({
    required String memberName,
    required String rawPhoneNumber,
    required String subtaskTitle,
    required String courseName,
    DateTime? deadline,
  }) async {
    final normalizedPhone = normalizeIndonesianPhoneNumber(rawPhoneNumber);
    if (normalizedPhone.length < 10) {
      throw Exception('Nomor WhatsApp tidak valid: $rawPhoneNumber');
    }

    final formattedDeadline = deadline != null
        ? DateFormat('EEEE, d MMMM yyyy HH:mm', 'id_ID').format(deadline)
        : 'Segera (sesuai kesepakatan)';

    final message = '''
Halo *$memberName*! 👋
Pengingat ramah untuk tugas kelompok kita di matkul *$courseName*:
📌 Bagian kamu: "$subtaskTitle"
⏰ Deadline: $formattedDeadline

Semangat yaa, yuk kita selesaikan tepat waktu bareng-bareng! ✨
_(Dikirim via aplikasi TugasKu)_
'''.trim();

    final encodedMessage = Uri.encodeComponent(message);
    final waUrl = Uri.parse('https://wa.me/$normalizedPhone?text=$encodedMessage');

    if (await canLaunchUrl(waUrl)) {
      return await launchUrl(waUrl, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Tidak dapat membuka WhatsApp untuk nomor $normalizedPhone');
    }
  }
}

