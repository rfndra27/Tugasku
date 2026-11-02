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
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
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
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
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
    final quotaResult = await firebaseService.checkAndIncrementAiQuota();
    if (quotaResult['allowed'] != true) {
      return AiActionResult(
        success: false,
        isQuotaExceeded: true,
        errorMessage: quotaResult['message'] ?? 'Kuota AI Anda telah habis.',
      );
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
Kamu adalah "TugasKu AI", asisten produktivitas dan teman belajar mahasiswa Indonesia yang ramah, solutif, dan suportif.
JAWABANMU HARUS 100% BERDASARKAN DATA TUGAS NYATA MAHASISWA DI BAWAH INI:

=== DAFTAR TUGAS AKTIF MAHASISWA ===
$tasksContext
====================================

Pertanyaan Mahasiswa: "$userQuestion"

Pedoman Menjawab:
1. Berikan rekomendasi konkret tugas mana yang harus dicicil lebih dulu berdasarkan skor prioritas dan bobot nilai.
2. Gunakan gaya bahasa kasual, bersahabat, menyemangati mahasiswa, dan terstruktur rapi dengan bullet points.
3. Jangan mengarang tugas yang tidak tercantum dalam daftar tugas aktif di atas.
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
              'temperature': 0.4,
            }
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final answer = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
          return AiActionResult(success: true, data: answer);
        }
      } catch (_) {
        // Fallback to grounded local response
      }
    }

    // Deterministic Grounded Fallback Response
    if (activeTasks.isEmpty) {
      return AiActionResult(
        success: true,
        data: 'Keren banget! Saat ini kamu tidak memiliki tugas aktif yang menumpuk. Nikmati waktu istirahatmu atau mulai pelajari materi perkuliahan berikutnya! 🚀',
      );
    }

    final topTask = activeTasks.first;
    final topDate = DateFormat('d MMMM yyyy jam HH:mm', 'id_ID').format(topTask.deadline);

    final sb = StringBuffer();
    sb.writeln('Halo! Berdasarkan data tugas aktifmu, ini rekomendasi prioritas yang perlu kamu cicil sekarang:');
    sb.writeln('');
    sb.writeln('🎯 **Fokus Utama**: **${topTask.title}** (${topTask.courseName})');
    sb.writeln('⏰ Deadline: $topDate');
    sb.writeln('📊 Bobot Nilai: ${topTask.weightPercentage}% (Skor Prioritas: ${topTask.priorityScore.toStringAsFixed(1)})');
    sb.writeln('');
    sb.writeln('Tugas ini mendesak karena tenggat waktu yang dekat dan/atau bobot nilainya tinggi. Cicil 1-2 subtask hari ini ya, jangan sampai sistem kebut semalam! Semangat! 💪');

    return AiActionResult(success: true, data: sb.toString());
  }
}
