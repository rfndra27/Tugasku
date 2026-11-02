import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/class_schedule_model.dart';
import 'package:tugasku/models/group_task_model.dart';
import 'package:tugasku/models/subtask_model.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/models/user_profile_model.dart';

void main() {
  group('Firestore Models Serialization & Deserialization Tests', () {
    test('TaskModel correctly serializes and deserializes Firestore Timestamps', () {
      final now = DateTime.now();
      final task = TaskModel(
        id: 'task-test-id',
        userId: 'user-uid-123',
        courseName: 'Jaringan Komputer',
        title: 'Konfigurasi VLAN & Subnetting',
        description: 'Tugas praktikum lab jaringan',
        deadline: now,
        weightPercentage: 15.0,
        source: 'manual',
        isGroupTask: true,
      );

      final json = task.toJson();
      expect(json['user_id'], equals('user-uid-123'));
      expect(json['deadline'], isA<Timestamp>());
      expect(json['weight_percentage'], equals(15.0));
      expect(json['is_group_task'], isTrue);

      final deserialized = TaskModel.fromJson(json, docId: 'task-test-id');
      expect(deserialized.id, equals('task-test-id'));
      expect(deserialized.courseName, equals('Jaringan Komputer'));
      expect(deserialized.isGroupTask, isTrue);
    });

    test('SubtaskModel handles Indonesian phone numbers and completion timestamps', () {
      final sub = SubtaskModel(
        id: 'sub-1',
        taskId: 'task-test-id',
        title: 'Buat topologi di Cisco Packet Tracer',
        assignedToName: 'Doni',
        assignedToPhone: '628123456789',
        isCompleted: true,
        completedAt: DateTime.now(),
      );

      final json = sub.toJson();
      expect(json['assigned_to_phone'], equals('628123456789'));
      expect(json['is_completed'], isTrue);
      expect(json['completed_at'], isA<Timestamp>());

      final deserialized = SubtaskModel.fromJson(json, docId: 'sub-1');
      expect(deserialized.assignedToName, equals('Doni'));
      expect(deserialized.isCompleted, isTrue);
    });

    test('UserProfileModel calculates remaining quota for Free vs Unlimited Premium', () {
      final freeUser = UserProfileModel(
        id: 'u-free',
        email: 'free@mhs.ac.id',
        fullName: 'Mahasiswa Free',
        isPremium: false,
        aiUsageCount: 3,
      );
      expect(freeUser.remainingAiQuota, equals(2)); // 5 - 3 = 2

      final freeUserExhausted = freeUser.copyWith(aiUsageCount: 5);
      expect(freeUserExhausted.remainingAiQuota, equals(0));

      final premiumUser = UserProfileModel(
        id: 'u-premium',
        email: 'prem@mhs.ac.id',
        fullName: 'Mahasiswa Sultan',
        isPremium: true,
        aiUsageCount: 150,
      );
      expect(premiumUser.remainingAiQuota, equals(-1)); // -1 means Unlimited
    });

    test('ClassScheduleModel computes start and end total minutes accurately', () {
      final schedule = ClassScheduleModel(
        id: 'sch-1',
        userId: 'u-1',
        courseName: 'Sistem Operasi',
        dayOfWeek: 2, // Selasa
        startTime: '08:30',
        endTime: '10:10',
        room: 'Lab 4',
      );

      expect(schedule.dayName, equals('Selasa'));
      expect(schedule.startTotalMinutes, equals(8 * 60 + 30)); // 510
      expect(schedule.endTotalMinutes, equals(10 * 60 + 10)); // 610
    });

    test('GroupProjectModel parses members and roles accurately', () {
      final project = GroupProjectModel(
        id: 'grp-1',
        userId: 'u-1',
        title: 'Sistem Informasi Kampus',
        courseName: 'RPL',
        inviteCode: 'GRP-7788',
        members: [
          GroupMemberModel(id: 'm-1', projectId: 'grp-1', name: 'Ketua', phone: '628111', role: 'leader'),
          GroupMemberModel(id: 'm-2', projectId: 'grp-1', name: 'Anggota 1', phone: '628222', role: 'member'),
        ],
      );

      expect(project.memberCount, equals(2));
      expect(project.members.first.isLeader, isTrue);
      expect(project.members.last.isLeader, isFalse);
    });
  });
}

