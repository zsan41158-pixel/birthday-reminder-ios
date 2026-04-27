import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/family_member.dart';
import '../repositories/database_repository.dart';
import '../services/notification_service.dart';

final memberListProvider = StateNotifierProvider<MemberListNotifier, AsyncValue<List<FamilyMember>>>((ref) {
  return MemberListNotifier();
});

final searchKeywordProvider = StateProvider<String>((ref) => '');

class MemberListNotifier extends StateNotifier<AsyncValue<List<FamilyMember>>> {
  MemberListNotifier() : super(const AsyncValue.loading()) {
    loadMembers();
  }

  final _dbRepo = DatabaseRepository();
  final _notifyService = NotificationService();

  Future<void> loadMembers() async {
    try {
      final members = await _dbRepo.getAllMembers();
      state = AsyncValue.data(members);
      // 重新调度所有通知（通知调度失败不应影响列表展示）
      try {
        await _notifyService.scheduleAllMembersNotifications(members);
      } catch (notifyErr) {
        // 通知调度失败静默处理，避免覆盖列表数据状态
        debugPrint('通知调度失败: $notifyErr');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMember(FamilyMember member) async {
    try {
      await _dbRepo.addMember(member);
      await loadMembers();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateMember(FamilyMember member) async {
    try {
      await _dbRepo.updateMember(member);
      await loadMembers();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMember(int id) async {
    try {
      await _dbRepo.deleteMember(id);
      await loadMembers();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await loadMembers();
  }
}
