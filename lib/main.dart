import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'repositories/database_repository.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服务
  final notificationService = NotificationService();
  await notificationService.init();

  // 启动时加载成员并注册通知（防止被杀后台后通知丢失）
  try {
    final members = await DatabaseRepository().getAllMembers();
    await notificationService.scheduleAllMembersNotifications(members);
  } catch (e) {
    debugPrint('Startup notification scheduling failed: $e');
  }

  runApp(
    const ProviderScope(
      child: BirthdayReminderApp(),
    ),
  );
}
