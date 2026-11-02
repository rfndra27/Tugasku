import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/priority_calculator.dart';
import '../models/task_model.dart';

class ICalSyncResult {
  final int newTasksCount;
  final int updatedTasksCount;
  final int totalEvents;
  final String message;

  ICalSyncResult({
    required this.newTasksCount,
    required this.updatedTasksCount,
    required this.totalEvents,
    required this.message,
  });
}

class ICalEvent {
  final String uid;
  final String summary;
  final String description;
  final DateTime deadline;

  ICalEvent({
    required this.uid,
    required this.summary,
    required this.description,
    required this.deadline,
  });
}

class ICalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches .ics from url and synchronizes tasks into users/{userId}/tasks
  Future<ICalSyncResult> syncElearningCalendar({
    required String userId,
    required String icalUrl,
    String platformName = 'Moodle',
  }) async {
    try {
      final response = await http.get(Uri.parse(icalUrl.trim()));
      if (response.statusCode != 200) {
        throw Exception('Gagal mengunduh kalender iCal (HTTP ${response.statusCode})');
      }

      final icsContent = response.body;
      final events = parseIcsContent(icsContent);

      if (events.isEmpty) {
        return ICalSyncResult(
          newTasksCount: 0,
          updatedTasksCount: 0,
          totalEvents: 0,
          message: 'Tidak ditemukan jadwal/tugas pada file kalender ini.',
        );
      }

      int newTasks = 0;
      int updatedTasks = 0;

      // Query existing tasks for this user to check external_uid
      final existingTasksQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('source', isEqualTo: AppConstants.sourceElearningIcal)
          .get();

      final existingMap = <String, DocumentSnapshot>{};
      for (final doc in existingTasksQuery.docs) {
        final extUid = doc.data()['external_uid']?.toString();
        if (extUid != null && extUid.isNotEmpty) {
          existingMap[extUid] = doc;
        }
      }

      for (final ev in events) {
        if (existingMap.containsKey(ev.uid)) {
          // Task already exists: Check if deadline was changed by lecturer
          final existingDoc = existingMap[ev.uid]!;
          final data = existingDoc.data() as Map<String, dynamic>;
          final oldDeadline = (data['deadline'] as Timestamp?)?.toDate();

          if (oldDeadline != null && oldDeadline.difference(ev.deadline).abs().inMinutes > 5) {
            final newPriority = PriorityCalculator.calculatePriority(
              deadline: ev.deadline,
              weightPercentage: (data['weight_percentage'] is num)
                  ? (data['weight_percentage'] as num).toDouble()
                  : 10.0,
            );

            await existingDoc.reference.update({
              'deadline': Timestamp.fromDate(ev.deadline),
              'priority_score': newPriority,
              'title': ev.summary,
              'description': ev.description,
            });
            updatedTasks++;
          }
        } else {
          // New Task insertion
          final newPriority = PriorityCalculator.calculatePriority(
            deadline: ev.deadline,
            weightPercentage: 10.0,
          );

          final docRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('tasks')
              .doc();

          final newTask = TaskModel(
            id: docRef.id,
            userId: userId,
            courseName: platformName,
            title: ev.summary,
            description: ev.description,
            deadline: ev.deadline,
            weightPercentage: 10.0,
            priorityScore: newPriority,
            source: AppConstants.sourceElearningIcal,
            externalUid: ev.uid,
            isCompleted: false,
          );

          await docRef.set(newTask.toJson());
          newTasks++;
        }
      }

      // Record sync in elearning_configs
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('elearning_configs')
          .doc('default')
          .set({
        'ical_url': icalUrl,
        'platform_name': platformName,
        'last_synced_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return ICalSyncResult(
        newTasksCount: newTasks,
        updatedTasksCount: updatedTasks,
        totalEvents: events.length,
        message: 'Sinkronisasi berhasil! $newTasks tugas baru ditambahkan, $updatedTasks tugas diperbarui.',
      );
    } catch (e) {
      throw Exception('Gagal melakukan sinkronisasi kalender: $e');
    }
  }

  /// Parses raw VCALENDAR ICS text into list of ICalEvents
  List<ICalEvent> parseIcsContent(String icsContent) {
    final List<ICalEvent> events = [];
    final lines = icsContent.split(RegExp(r'\r\n|\r|\n'));

    bool inEvent = false;
    String uid = '';
    String summary = '';
    String description = '';
    DateTime? dtEnd;
    DateTime? dtDue;
    DateTime? dtStart;

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      // Handle folded lines (RFC 5545) starting with space or tab
      while (i + 1 < lines.length && (lines[i + 1].startsWith(' ') || lines[i + 1].startsWith('\t'))) {
        line += lines[i + 1].substring(1);
        i++;
      }

      line = line.trim();

      if (line == 'BEGIN:VEVENT') {
        inEvent = true;
        uid = '';
        summary = '';
        description = '';
        dtEnd = null;
        dtDue = null;
        dtStart = null;
      } else if (line == 'END:VEVENT') {
        if (inEvent) {
          final deadline = dtDue ?? dtEnd ?? dtStart ?? DateTime.now().add(const Duration(days: 3));
          if (summary.isNotEmpty) {
            events.add(ICalEvent(
              uid: uid.isNotEmpty ? uid : 'ics_${summary.hashCode}_${deadline.millisecondsSinceEpoch}',
              summary: _unescapeIcs(summary),
              description: _unescapeIcs(description),
              deadline: deadline,
            ));
          }
        }
        inEvent = false;
      } else if (inEvent) {
        if (line.startsWith('UID:')) {
          uid = line.substring(4).trim();
        } else if (line.startsWith('SUMMARY:')) {
          summary = line.substring(8).trim();
        } else if (line.startsWith('DESCRIPTION:')) {
          description = line.substring(12).trim();
        } else if (line.startsWith('DTEND') || line.startsWith('DUE')) {
          final colonIndex = line.indexOf(':');
          if (colonIndex != -1) {
            final dateStr = line.substring(colonIndex + 1).trim();
            final parsed = _parseIcsDateTime(dateStr);
            if (line.startsWith('DUE')) {
              dtDue = parsed;
            } else {
              dtEnd = parsed;
            }
          }
        } else if (line.startsWith('DTSTART')) {
          final colonIndex = line.indexOf(':');
          if (colonIndex != -1) {
            final dateStr = line.substring(colonIndex + 1).trim();
            dtStart = _parseIcsDateTime(dateStr);
          }
        }
      }
    }

    return events;
  }

  DateTime? _parseIcsDateTime(String str) {
    try {
      // Formats:
      // YYYYMMDDTHHMMSSZ (UTC)
      // YYYYMMDDTHHMMSS (Local)
      // YYYYMMDD
      final clean = str.replaceAll('Z', '');
      if (clean.length == 8) {
        final y = int.parse(clean.substring(0, 4));
        final m = int.parse(clean.substring(4, 6));
        final d = int.parse(clean.substring(6, 8));
        return DateTime(y, m, d, 23, 59);
      } else if (clean.length >= 15) {
        final y = int.parse(clean.substring(0, 4));
        final m = int.parse(clean.substring(4, 6));
        final d = int.parse(clean.substring(6, 8));
        final h = int.parse(clean.substring(9, 11));
        final min = int.parse(clean.substring(11, 13));
        final s = int.parse(clean.substring(13, 15));
        if (str.endsWith('Z')) {
          return DateTime.utc(y, m, d, h, min, s).toLocal();
        }
        return DateTime(y, m, d, h, min, s);
      }
    } catch (_) {}
    return null;
  }

  String _unescapeIcs(String text) {
    return text
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\N', '\n')
        .replaceAll(r'\,', ',')
        .replaceAll(r'\;', ';')
        .replaceAll(r'\\', r'\');
  }
}

