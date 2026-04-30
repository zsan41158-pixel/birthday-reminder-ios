import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../config/constants.dart';
import '../models/family_member.dart';
import 'lunar_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final LunarService _lunar = LunarService();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // 初始化时区数据并设置本地时区
    tz_data.initializeTimeZones();
    _setupLocalTimezone();

    _initialized = true;
  }

  void _setupLocalTimezone() {
    try {
      // 优先使用中国时区（农历生日应用主要面向中文用户）
      final location = tz.getLocation('Asia/Shanghai');
      tz.setLocalLocation(location);
    } catch (e) {
      debugPrint('设置本地时区失败: $e');
    }
  }

  Future<bool> requestPermission() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final result = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }
    return true;
  }

  Future<bool> get hasPermission async {
    if (Platform.isIOS || Platform.isMacOS) {
      // iOS 没有直接查询通知权限的 API，用 UserDefaults 记录上次请求结果
      // 这里简化处理：尝试请求（如果已授权直接返回 true，已拒绝会返回 false）
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final result = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }
    return true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    // payload 格式: "snooze:memberId:type" 或 "dismiss:memberId:type"
    final parts = payload.split(':');
    if (parts.length < 3) return;
    final action = parts[0];
    final memberId = int.tryParse(parts[1]) ?? 0;
    final type = int.tryParse(parts[2]) ?? 0; // 0=lunar, 1=solar

    if (action == 'snooze') {
      // 稍后提醒由 UI 层或后续调度处理
      // 这里仅做标记，实际重调度由调用方处理
    }
  }

  /// 清空所有生日提醒通知
  Future<void> cancelAllBirthdayNotifications() async {
    await _plugin.cancelAll();
  }

  /// 为单个成员注册未来 N 年的通知，返回成功注册的数量
  Future<int> scheduleMemberNotifications(FamilyMember member) async {
    if (member.id == null) {
      debugPrint('成员 ID 为空，跳过通知注册: ${member.name}');
      return 0;
    }

    final now = DateTime.now();
    final currentYear = now.year;
    int scheduledCount = 0;

    // 农历生日通知
    if ((member.birthdayType == BirthdayType.lunar || member.birthdayType == BirthdayType.both) &&
        member.lunarMonth != null &&
        member.lunarDay != null) {
      for (int y = 0; y < NotificationConfig.scheduleAheadYears; y++) {
        final year = currentYear + y;
        final solarDate = _lunar.lunarToSolar(member.lunarMonth!, member.lunarDay!, year: year);
        if (solarDate != null) {
          try {
            await _scheduleNotification(
              id: _generateNotificationId(member.id!, 0, year),
              title: '生日提醒',
              body: '今天是 ${member.name} 的农历生日（${year}年${_lunar.formatLunarDate(member.lunarMonth!, member.lunarDay!)}）',
              scheduledDate: _combineDateAndTime(solarDate, member.lunarReminderTime ?? AppDefaults.reminderTime),
              payload: 'dismiss:${member.id}:0',
            );
            scheduledCount++;
          } catch (e) {
            debugPrint('农历通知注册失败 (year=$year): $e');
          }
        } else {
          debugPrint('农历转公历失败: ${member.lunarMonth}月${member.lunarDay}日, year=$year');
        }
      }
    }

    // 公历生日通知
    if ((member.birthdayType == BirthdayType.solar || member.birthdayType == BirthdayType.both) &&
        member.solarMonth != null &&
        member.solarDay != null) {
      for (int y = 0; y < NotificationConfig.scheduleAheadYears; y++) {
        final year = currentYear + y;
        final date = DateTime(year, member.solarMonth!, member.solarDay!);
        try {
          await _scheduleNotification(
            id: _generateNotificationId(member.id!, 1, year),
            title: '生日提醒',
            body: '今天是 ${member.name} 的公历生日（${year}年${member.solarMonth}月${member.solarDay}日）',
            scheduledDate: _combineDateAndTime(date, member.solarReminderTime ?? AppDefaults.reminderTime),
            payload: 'dismiss:${member.id}:1',
          );
          scheduledCount++;
        } catch (e) {
          debugPrint('公历通知注册失败 (year=$year): $e');
        }
      }
    }

    debugPrint('成员 ${member.name} 注册了 $scheduledCount 个通知');
    return scheduledCount;
  }

  /// 批量为所有成员注册通知
  Future<void> scheduleAllMembersNotifications(List<FamilyMember> members) async {
    debugPrint('开始批量注册通知，成员数: ${members.length}');
    await cancelAllBirthdayNotifications();
    int scheduledCount = 0;
    for (final member in members) {
      final count = await scheduleMemberNotifications(member);
      scheduledCount += count;
    }
    debugPrint('通知注册完成，共注册 $scheduledCount 个通知');
  }

  /// 创建稍后提醒通知（10分钟后）
  Future<void> scheduleSnoozeNotification({
    required int memberId,
    required int type,
    required String memberName,
    required String birthdayDesc,
    required int minutes,
  }) async {
    final scheduled = DateTime.now().add(Duration(minutes: minutes));
    await _scheduleNotification(
      id: _generateNotificationId(memberId, type, scheduled.millisecond + 100000),
      title: '生日提醒（稍后）',
      body: '今天是 $memberName 的$birthdayDesc',
      scheduledDate: scheduled,
      payload: 'dismiss:$memberId:$type',
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // 不注册过去的时间
    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) {
      debugPrint('跳过过去时间的通知: $scheduledDate (当前: $now)');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      NotificationConfig.channelId,
      NotificationConfig.channelName,
      channelDescription: NotificationConfig.channelDesc,
      importance: Importance.max,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    debugPrint('注册通知: id=$id, title=$title, time=$tzScheduledDate');

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 获取当前已注册的所有待发送通知（调试用）
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  /// 取消某个成员的所有通知
  Future<void> cancelMemberNotifications(int memberId) async {
    // 获取所有待发送的通知
    final pending = await _plugin.pendingNotificationRequests();
    
    // 根据 ID 规则过滤出该成员的通知并取消
    for (final notification in pending) {
      // ID 格式: memberId * 100000 + type * 10000 + seed
      // 判断条件：notification.id / 100000 == memberId
      if (notification.id ~/ 100000 == memberId) {
        await _plugin.cancel(notification.id);
      }
    }
    
    debugPrint('已取消成员 $memberId 的通知');
  }

  DateTime _combineDateAndTime(DateTime date, String timeStr) {
    if (timeStr.isEmpty || !timeStr.contains(':')) {
      return DateTime(date.year, date.month, date.day, 8, 0, 0);
    }
    final parts = timeStr.split(':');
    if (parts.length < 2) {
      return DateTime(date.year, date.month, date.day, 8, 0, 0);
    }
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;
    final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute, second);
  }

  /// 生成唯一通知ID：使用取模运算避免溢出
  /// 格式：(memberId % 1000) * 100000 + type * 10000 + (seed % 10000)
  int _generateNotificationId(int memberId, int type, int seed) {
    return (memberId % 1000) * 100000 + type * 10000 + (seed % 10000);
  }
}
