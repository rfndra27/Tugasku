import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/subtask_model.dart';
import '../models/task_model.dart';
import 'firebase_service.dart';

class AiActionResult<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  final bool isQuotaExceeded;

  AiActionResult({
    required this.success,
    this.data,
    this.errorMessage,
    this.isQuotaExceeded = false,
  });
}

class AiExtractedTask {
  final String title;
  final String courseName;
  final DateTime deadline;
  final double weightPercentage;
  final String description;

  AiExtractedTask({
    required this.title,
    required this.courseName,
    required this.deadline,
    required this.weightPercentage,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'course_name': courseName,
        'deadline': deadline.toIso8601String(),
        'weight_percentage': weightPercentage,
        'description': description,
      };
}

class AiService {
  final FirebaseService firebaseService;
  String _geminiApiKey;

  AiService({
    required this.firebaseService,
    String? apiKey,
  }) : _geminiApiKey = apiKey ?? AppConstants.defaultGeminiApiKey;

  void updateApiKey(String key) {
    _geminiApiKey = key;
  }

  AiGroupProjectDraft parseGroupProjectMessage(String text) {
    final phoneMatch = RegExp(r'(?:\+?62|0)\s*\d(?:[\d\s-]{7,})').firstMatch(text);
    final phone = phoneMatch?.group(0)?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    String field(String pattern, String fallback) {
      final match = RegExp('$pattern\\s*[:=-]\\s*([^,;\\n]+)', caseSensitive: false).firstMatch(text);
      return match?.group(1)?.trim() ?? fallback;
    }
    final normalizedPhone = phone.startsWith('0') ? '62${phone.substring(1)}' : phone;
    return AiGroupProjectDraft(
      title: field(r'(?:tugas|proyek|project)', text.split(RegExp(r'[,\n]')).first.trim()),
      courseName: field(r'(?:mata kuliah|matkul|kuliah)', 'Mata Kuliah'),
      leaderName: field(r'(?:ketua|dibuat oleh|leader)', ''),
      leaderPhone: normalizedPhone,
    );
  }

  // ----------------------------------------------------
  // 1. SMART TASK INPUT PARSER
  // ----------------------------------------------------
  Future<AiActionResult<AiExtractedTask>> parseLecturerMessage(String rawText) async {
    // 1. Check AI Quota
    final quotaResult = await firebaseService.checkAndIncrementAiQuota();
    if (quotaResult['allowed'] != true) {
      return AiActionResult(
        success: false,
        isQuotaExceeded: true,
        errorMessage: quotaResult['message'] ?? 'Kuota AI Anda telah habis.',
      );
    }

    // 2. Try Gemini API if key is present
    if (_geminiApiKey.isNotEmpty) {
      try {
        final prompt = '''
Kamu adalah asisten ekstraksi tugas mahasiswa di Indonesia. Ekstrak pesan berikut menjadi JSON murni tanpa markdown/backticks.
Pesan dosen/grup WA:
"""$rawText"""

Format JSON yang wajib dihasilkan:
{
  "title": "judul tugas yang ringkas dan jelas",
  "course_name": "nama mata kuliah (jika tidak ada tebak atau isi 'Tugas Kuliah')",
  "deadline": "YYYY-MM-DDTHH:mm:ss (waktu deadline relatif dari sekarang: ${DateTime.now().toIso8601String()})",
  "weight_percentage": 10.0,
  "description": "catatan atau deskripsi tugas yang relevan"
}
''';

        final url = Uri.parse(
            '${AppConstants.geminiEndpoint}/${AppConstants.geminiModel}:generateContent?key=$_geminiApiKey');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'responseMimeType': 'application/json',
              'temperature': 0.1,
            }
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final parts = data['candidates']?[0]?['content']?['parts'] as List? ?? [];
          final content = parts.map((p) => p['text']?.toString() ?? '').where((t) => t.isNotEmpty).join('\n');
          final cleanJson = content.trim().replaceAll('```json', '').replaceAll('```', '');
          final parsed = jsonDecode(cleanJson);

          DateTime deadline;
          try {
            deadline = DateTime.parse(parsed['deadline']);
          } catch (_) {
            deadline = DateTime.now().add(const Duration(days: 3));
          }

          final task = AiExtractedTask(
            title: parsed['title'] ?? 'Tugas Kuliah',
            courseName: parsed['course_name'] ?? 'Mata Kuliah',
            deadline: deadline,
            weightPercentage: (parsed['weight_percentage'] is num)
                ? (parsed['weight_percentage'] as num).toDouble()
                : 10.0,
            description: parsed['description'] ?? rawText,
          );

          return AiActionResult(success: true, data: task);
        }
      } catch (_) {
        // Fallback to local Indonesian regex parser below
      }
    }

    // 3. Deterministic Local Indonesian NLP / Regex Fallback Parser
    final localResult = _parseWithIndonesianRegex(rawText);
    return AiActionResult(success: true, data: localResult);
  }

  AiExtractedTask _parseWithIndonesianRegex(String text) {
    final lower = text.toLowerCase();
    final now = DateTime.now();

    // 1. Extract Weight Percentage (e.g., "bobot 20%", "25%", "15 persen")
    double weight = 10.0;
    final weightRegex = RegExp(r'(?:bobot|nilai|presentase)?\s*(\d{1,2})\s*(?:%|persen)', caseSensitive: false);
    final weightMatch = weightRegex.firstMatch(lower);
    if (weightMatch != null) {
      weight = double.tryParse(weightMatch.group(1) ?? '10') ?? 10.0;
    }

    // 2. Extract Deadline (Day & Time)
    int dayOffset = 3; // Default 3 days from now
    final days = {
      'senin': DateTime.monday,
      'selasa': DateTime.tuesday,
      'rabu': DateTime.wednesday,
      'kamis': DateTime.thursday,
      'jumat': DateTime.friday,
      'sabtu': DateTime.saturday,
      'minggu': DateTime.sunday,
    };

    if (lower.contains('hari ini')) {
      dayOffset = 0;
    } else if (lower.contains('besok')) {
      dayOffset = 1;
    } else if (lower.contains('lusa')) {
      dayOffset = 2;
    } else {
      for (final entry in days.entries) {
        if (lower.contains(entry.key)) {
          int diff = entry.value - now.weekday;
          if (diff <= 0) diff += 7; // Next occurrence
          dayOffset = diff;
          break;
        }
      }
    }

    // Extract hour: e.g. "jam 10", "pukul 23.59", "jam 14:00", "jam 10 malam"
    int hour = 23;
    int minute = 59;
    final timeRegex = RegExp(r'(?:jam|pukul)\s*(\d{1,2})(?:[:.](\d{2}))?', caseSensitive: false);
    final timeMatch = timeRegex.firstMatch(lower);
    if (timeMatch != null) {
      hour = int.tryParse(timeMatch.group(1) ?? '23') ?? 23;
      minute = int.tryParse(timeMatch.group(2) ?? '00') ?? 0;
      if ((lower.contains('malam') || lower.contains('sore') || lower.contains('pm')) && hour < 12) {
        hour += 12;
      }
    }

    final targetDate = now.add(Duration(days: dayOffset));
    final calculatedDeadline = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);

    // 3. Extract Course Name
    String courseName = 'Mata Kuliah';
    final courseRegex = RegExp(r'(?:matkul|kuliah|mata kuliah)\s+([a-zA-Z0-9\s]{3,25})', caseSensitive: false);
    final courseMatch = courseRegex.firstMatch(text);
    if (courseMatch != null) {
      courseName = courseMatch.group(1)?.trim() ?? 'Mata Kuliah';
    } else if (lower.contains('praktikum')) {
      courseName = 'Praktikum';
    } else if (lower.contains('skripsi')) {
      courseName = 'Tugas Akhir / Skripsi';
    }

    // 4. Extract Title
    String title = text.trim();
    if (title.length > 50) {
      final firstLine = title.split('\n').first;
      title = firstLine.length > 50 ? '${firstLine.substring(0, 47)}...' : firstLine;
    }
    if (title.isEmpty) title = 'Tugas Kuliah Baru';

    return AiExtractedTask(
      title: title,
      courseName: courseName,
      deadline: calculatedDeadline,
      weightPercentage: weight,
      description: text,
    );
  }

  // ----------------------------------------------------
  // 2. PECAH TUGAS (TASK BREAKDOWN TO SUBTASKS)
  // ----------------------------------------------------
  Future<AiActionResult<List<SubtaskModel>>> breakdownTask({
    required String taskId,
    required String taskTitle,
    required String courseName,
    required DateTime deadline,
  }) async {
    // Check AI Quota
    final quotaResult = await firebaseService.checkAndIncrementAiQuota();
    if (quotaResult['allowed'] != true) {
      return AiActionResult(
        success: false,
        isQuotaExceeded: true,
        errorMessage: quotaResult['message'] ?? 'Kuota AI Anda telah habis.',
      );
    }

    if (_geminiApiKey.isNotEmpty) {
      try {
        final prompt = '''
Kamu adalah perencana tugas mahasiswa. Pecah tugas kuliah berikut menjadi 4 sampai 5 subtask yang konkret, terukur, dan berurutan untuk dikerjakan mahasiswa.
Tugas: "$taskTitle"
Mata Kuliah: "$courseName"
Deadline: ${DateFormat('yyyy-MM-dd HH:mm').format(deadline)}

Keluarkan HANYA JSON array tanpa markdown:
[
  {"title": "Langkah 1: ...", "order_index": 0},
  {"title": "Langkah 2: ...", "order_index": 1},
  {"title": "Langkah 3: ...", "order_index": 2},
  {"title": "Langkah 4: ...", "order_index": 3}
]
''';

        final url = Uri.parse(
            '${AppConstants.geminiEndpoint}/${AppConstants.geminiModel}:generateContent?key=$_geminiApiKey');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'responseMimeType': 'application/json',
              'temperature': 0.2,
            }
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final parts = data['candidates']?[0]?['content']?['parts'] as List? ?? [];
          final content = parts.map((p) => p['text']?.toString() ?? '').where((t) => t.isNotEmpty).join('\n');
          final cleanJson = content.trim().replaceAll('```json', '').replaceAll('```', '');
          final List list = jsonDecode(cleanJson);

          final subtasks = list.asMap().entries.map((entry) {
            final item = entry.value;
            return SubtaskModel(
              id: '',
              taskId: taskId,
              title: item['title'] ?? 'Langkah ${entry.key + 1}',
              orderIndex: entry.key,
              isCompleted: false,
            );
          }).toList();

          return AiActionResult(success: true, data: subtasks);
        }
      } catch (_) {
        // Fall through to deterministic fallback
      }
    }

    // Deterministic Indonesian Breakdown Fallback
    final fallbackSubtasks = [
      SubtaskModel(
        id: '',
        taskId: taskId,
        title: 'Mencari literatur, materi & referensi untuk $taskTitle',
        orderIndex: 0,
        isCompleted: false,
      ),
      SubtaskModel(
        id: '',
        taskId: taskId,
        title: 'Menyusun kerangka & pembagian bab / soal latihan',
        orderIndex: 1,
        isCompleted: false,
      ),
      SubtaskModel(
        id: '',
        taskId: taskId,
        title: 'Menulis draf utama dan pengerjaan substansi',
        orderIndex: 2,
        isCompleted: false,
      ),
      SubtaskModel(
        id: '',
        taskId: taskId,
        title: 'Review format, sitasi, dan pengecekan plagiarisme',
        orderIndex: 3,
        isCompleted: false,
      ),
      SubtaskModel(
        id: '',
        taskId: taskId,
        title: 'Finalisasi berkas PDF dan pengumpulan ke portal e-learning',
        orderIndex: 4,
        isCompleted: false,
      ),
    ];

    return AiActionResult(success: true, data: fallbackSubtasks);
  }

  // ----------------------------------------------------
  // 3. ASISTEN AI CHAT (GROUNDED IN USER'S REAL TASKS)
  // ----------------------------------------------------
  Future<AiActionResult<String>> askAssistant({
    required String userQuestion,
    required List<TaskModel> activeTasks,
  }) async {
    // Check AI Quota
    // If the quota service is temporarily unavailable, continue with the
    // grounded local fallback instead of leaving the user without an answer.
    try {
      final quotaResult = await firebaseService
          .checkAndIncrementAiQuota()
          .timeout(const Duration(seconds: 4));
      if (quotaResult['allowed'] != true && quotaResult['is_quota_exceeded'] == true) {
        return AiActionResult(
          success: false,
          isQuotaExceeded: true,
          errorMessage: quotaResult['message'] ?? 'Kuota AI Anda telah habis.',
        );
      }
    } catch (_) {
      // Continue to Gemini or local fallback if quota check is unreachable
    }

    final tasksContext = activeTasks.isEmpty
        ? 'Saat ini kamu tidak memiliki tugas aktif.'
        : activeTasks.map((t) {
            final formattedDate = DateFormat('EEEE, d MMM yyyy HH:mm', 'id_ID').format(t.deadline);
            return '- [${t.courseName}] "${t.title}" | Deadline: $formattedDate | Bobot: ${t.weightPercentage}% | Skor Prioritas: ${t.priorityScore.toStringAsFixed(1)} | Subtask: ${t.completedSubtasks}/${t.totalSubtasks}';
          }).join('\n');

    if (_geminiApiKey.isNotEmpty) {
      try {
        final prompt = '''
Kamu adalah "TugasKu AI", asisten produktivitas dan teman belajar mahasiswa Indonesia yang ramah, solutif, cerdas, dan suportif.

DAFTAR TUGAS AKTIF MAHASISWA:
$tasksContext

Pertanyaan / Obrolan Mahasiswa: "$userQuestion"

Panduan Menjawab:
1. Jawab mahasiswa dengan gaya bahasa ramah, kasual (seperti sesama mahasiswa atau mentor santai), dan gunakan emoji yang relevan.
2. Jika ada tugas aktif, berikan rekomendasi konkret tugas mana yang harus dicicil lebih dulu berdasarkan skor prioritas dan bobot nilai. Jangan mengarang tugas yang tidak tercantum dalam daftar tugas aktif di atas.
3. Jika daftar tugas masih kosong atau belum ada tugas aktif:
   - Jika mahasiswa bertanya soal tugas, beri tahu dengan santai bahwa belum ada tugas yang terdaftar dan ajak mereka menambahkan tugas di halaman Tugas agar bisa dibantu atur jadwal dan prioritasnya.
   - Jika mahasiswa bertanya santai, menyapa (halo), minta tips, atau topik obrolan bebas (hobi, analogi belajar, dll.), jawab dengan cerdas, ramah, dan tetap selipkan motivasi belajar/produktivitas.
4. Jawab secara ringkas, jelas, dan rapi dengan bullet points bila perlu.
''';

        final url = Uri.parse(
            '${AppConstants.geminiEndpoint}/${AppConstants.geminiModel}:generateContent?key=$_geminiApiKey');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
            }
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final parts = data['candidates']?[0]?['content']?['parts'] as List? ?? [];
          final answer = parts.map((p) => p['text']?.toString() ?? '').where((t) => t.isNotEmpty).join('\n');
          if (answer.trim().isNotEmpty) {
            return AiActionResult(success: true, data: answer.trim());
          }
        }
      } catch (_) {
        // Fallback to grounded local response
      }
    }

    // Deterministic Grounded Fallback Response
    return AiActionResult(
      success: true,
      data: buildLocalAssistantResponse(userQuestion, activeTasks),
    );
  }

  /// Provides a useful answer when Firebase or Gemini is unavailable.
  /// This is intentionally grounded only in the tasks already loaded locally.
  String buildLocalAssistantResponse(String userQuestion, List<TaskModel> activeTasks) {
    final question = userQuestion.toLowerCase();
    if (activeTasks.isEmpty) {
      if (question.contains('hari ini') ||
          question.contains('sekarang') ||
          question.contains('mendesak') ||
          question.contains('prioritas')) {
        return 'Hari ini belum ada tugas aktif yang tercatat. Kamu bisa memakai waktu ini untuk mengecek pengumuman kelas atau menyiapkan tugas berikutnya. 🚀';
      }
      if (question.contains('tips') ||
          question.contains('waktu') ||
          question.contains('minggu')) {
        return 'Karena belum ada tugas aktif, gunakan minggu ini untuk merapikan catatan, mengecek kalender kuliah, dan menyiapkan daftar target belajar. Sisihkan 25 menit per sesi agar tetap konsisten. 📚';
      }
      if (question.contains('cicil') ||
          question.contains('pecah') ||
          question.contains('mulai')) {
        return 'Belum ada tugas aktif yang bisa dicicil. Coba tambahkan tugas dari halaman Tugas, lalu aku bantu memecahnya menjadi langkah-langkah kecil. ✅';
      }
      if (question.contains('hai') ||
          question.contains('halo') ||
          question.contains('apa kabar')) {
        return 'Hai! Aku siap membantu mengatur tugasmu. Saat ini belum ada tugas aktif yang terbaca. 👋';
      }
      return 'Keren banget! Saat ini kamu tidak memiliki tugas aktif yang menumpuk. Nikmati waktu istirahatmu atau mulai pelajari materi perkuliahan berikutnya! 🚀';
    }

    final topTask = activeTasks.first;
    final topDate = DateFormat('d MMMM yyyy jam HH:mm', 'id_ID').format(topTask.deadline);

    if (question.contains('hari ini') || question.contains('sekarang')) {
      final today = DateTime.now();
      final todayTasks = activeTasks.where((task) {
        final deadline = task.deadline;
        return deadline.year == today.year &&
            deadline.month == today.month &&
            deadline.day == today.day;
      }).toList();

      if (todayTasks.isEmpty) {
        return 'Tidak ada deadline yang jatuh tepat hari ini. Prioritas terdekatmu adalah **${topTask.title}** dari ${topTask.courseName}, dengan deadline $topDate. Kalau sempat, cicil bagian kecilnya hari ini supaya tidak menumpuk. ✅';
      }

      final lines = todayTasks.take(3).map((task) {
        return '• **${task.title}** (${task.courseName}) — ${DateFormat('HH:mm').format(task.deadline)}';
      }).join('\n');
      return 'Ini tugas yang deadline-nya hari ini:\n\n$lines\n\nKerjakan yang skornya paling tinggi lebih dulu dan sisakan waktu untuk mengecek hasil sebelum dikumpulkan. ⏰';
    }

    if (question.contains('mendesak') || question.contains('prioritas') || question.contains('penting')) {
      final lines = activeTasks.take(3).map((task) {
        final deadline = DateFormat('d MMM, HH:mm', 'id_ID').format(task.deadline);
        return '• **${task.title}** — ${task.courseName}\n  Deadline: $deadline | Skor: ${task.priorityScore.toStringAsFixed(1)}';
      }).join('\n');
      return 'Berikut urutan tugas yang paling perlu kamu perhatikan berdasarkan skor prioritas:\n\n$lines\n\nMulai dari **${topTask.title}**, lalu kerjakan minimal satu subtask sebelum pindah ke tugas berikutnya. 🎯';
    }

    if (question.contains('cicil') || question.contains('pecah') || question.contains('mulai')) {
      return 'Untuk mencicil **${topTask.title}** dari mata kuliah **${topTask.courseName}**, coba pola ini:\n\n1. Buka instruksi dan kumpulkan bahan yang diperlukan.\n2. Kerjakan satu bagian kecil selama 25 menit.\n3. Istirahat 5 menit, lalu lanjutkan bagian berikutnya.\n4. Simpan hasil sementara dan catat langkah selanjutnya.\n\nDeadline tugas ini $topDate, jadi mulai dari langkah pertama sekarang ya. 💪';
    }

    if (question.contains('tips') || question.contains('waktu') || question.contains('minggu')) {
      return 'Tips mengatur waktu kuliah berdasarkan tugasmu:\n\n• Jadikan **${topTask.title}** sebagai fokus pertama karena skor prioritasnya ${topTask.priorityScore.toStringAsFixed(1)}.\n• Gunakan sesi fokus 25–30 menit, lalu istirahat 5 menit.\n• Sisakan waktu khusus untuk revisi sebelum deadline $topDate.\n• Jangan membuka lebih dari satu tugas dalam satu sesi agar fokus tidak terpecah.\n\nTarget kecil yang konsisten lebih aman daripada sistem kebut semalam. 📚';
    }

    final sb = StringBuffer();
    sb.writeln('Halo! Berdasarkan data tugas aktifmu, ini rekomendasi prioritas yang perlu kamu cicil sekarang:');
    sb.writeln('');
    sb.writeln('🎯 **Fokus Utama**: **${topTask.title}** (${topTask.courseName})');
    sb.writeln('⏰ Deadline: $topDate');
    sb.writeln('📊 Bobot Nilai: ${topTask.weightPercentage}% (Skor Prioritas: ${topTask.priorityScore.toStringAsFixed(1)})');
    sb.writeln('');
    sb.writeln('Tugas ini mendesak karena tenggat waktu yang dekat dan/atau bobot nilainya tinggi. Cicil 1-2 subtask hari ini ya, jangan sampai sistem kebut semalam! Semangat! 💪');

    return sb.toString();
  }
}

class AiGroupProjectDraft {
  final String title;
  final String courseName;
  final String leaderName;
  final String leaderPhone;

  const AiGroupProjectDraft({
    required this.title,
    required this.courseName,
    required this.leaderName,
    required this.leaderPhone,
  });
}
