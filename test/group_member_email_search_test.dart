import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/group_task_model.dart';
import 'package:tugasku/models/user_profile_model.dart';
import 'package:tugasku/providers/task_provider.dart';
import 'package:tugasku/services/firebase_service.dart';
import 'package:tugasku/services/whatsapp_service.dart';

class MockFirebaseService extends FirebaseService {
  @override
  Future<List<UserProfileModel>> searchProfilesByEmail(String query) async {
    final mockProfiles = [
      UserProfileModel(
        id: 'user-remano',
        email: 'remano@tugasku.app',
        fullName: 'Mochmad Remano Darusatwiko',
        university: 'Politeknik Negeri Jakarta',
        phone: '08123456789',
      ),
      UserProfileModel(
        id: 'user-novan',
        email: 'novansya@tugasku.app',
        fullName: 'Muhammad Novansya',
        university: 'Politeknik Negeri Jakarta',
        phone: '08123456780',
      ),
      UserProfileModel(
        id: 'user-rafa',
        email: 'rafa@tugasku.app',
        fullName: 'Riviera Rafa Andara',
        university: 'Politeknik Negeri Jakarta',
        phone: '08123456781',
      ),
    ];

    return mockProfiles
        .where((p) => p.email.contains(query.toLowerCase()) || p.fullName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

void main() {
  group('WhatsApp Service & Phone Normalization Tests', () {
    test('Normalizes standard 08xx Indonesian phone numbers to 628xx', () {
      expect(WhatsAppService.normalizeIndonesianPhoneNumber('08123456789'), equals('628123456789'));
      expect(WhatsAppService.normalizeIndonesianPhoneNumber('+62 813-1723-3751'), equals('6281317233751'));
      expect(WhatsAppService.normalizeIndonesianPhoneNumber('81234567890'), equals('6281234567890'));
      expect(WhatsAppService.normalizeIndonesianPhoneNumber('628123456780'), equals('628123456780'));
    });
  });

  group('Group Member Model Serialization Tests', () {
    test('GroupMemberModel retains email and memberUserId in toJson and fromJson', () {
      final member = GroupMemberModel(
        id: 'member-123',
        projectId: 'project-abc',
        name: 'Riviera Rafa',
        phone: '6281317233751',
        email: 'riviera.rafa@kampus.ac.id',
        memberUserId: 'uid-456',
        role: 'member',
      );

      final json = member.toJson();
      expect(json['email'], equals('riviera.rafa@kampus.ac.id'));
      expect(json['member_user_id'], equals('uid-456'));

      final fromJson = GroupMemberModel.fromJson(json);
      expect(fromJson.id, equals('member-123'));
      expect(fromJson.name, equals('Riviera Rafa'));
      expect(fromJson.email, equals('riviera.rafa@kampus.ac.id'));
      expect(fromJson.memberUserId, equals('uid-456'));
    });
  });

  group('Search Users by Email in TaskProvider Tests', () {
    late TaskProvider provider;

    setUp(() {
      provider = TaskProvider(firebaseService: MockFirebaseService());
    });

    test('Finds matching demo profiles by email query', () async {
      final results = await provider.searchUsersByEmail('remano@tugasku.app');

      expect(results.isNotEmpty, isTrue);
      expect(results.first.fullName, contains('Remano'));
      expect(results.first.phone, isNotEmpty);
    });

    test('Finds matching demo profiles by partial name query', () async {
      final results = await provider.searchUsersByEmail('rafa');

      expect(results.isNotEmpty, isTrue);
      expect(results.any((u) => u.fullName.toLowerCase().contains('rafa')), isTrue);
    });

    test('Returns empty list when query is empty or whitespace', () async {
      final results = await provider.searchUsersByEmail('   ');

      expect(results.isEmpty, isTrue);
    });
  });
}
