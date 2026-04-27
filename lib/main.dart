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

  // 启动时请求通知权限（iOS 必须显式请求）
  final hasPermission = await notificationService.requestPermission();
  debugPrint('通知权限状态: $hasPermission');

  // 启动时加载成员并注册通知（防止被杀后台后通知丢失）
  try {
    final members = await DatabaseRepository().getAllMembers();
    await notificationService.scheduleAllMembersNotifications(members);
  } catch (e, st) {
    debugPrint('启动时通知调度失败: $e');
    debugPrint('$st');
  }

  runApp(
    const ProviderScope(
      child: BirthdayReminderApp(),
    ),
  );
}
