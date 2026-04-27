import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服务
  final notificationService = NotificationService();
  await notificationService.init();

  // 启动时请求通知权限（iOS 必须显式请求）
  final hasPermission = await notificationService.requestPermission();
  debugPrint('通知权限状态: $hasPermission');

  runApp(
    const ProviderScope(
      child: BirthdayReminderApp(),
    ),
  );
}
