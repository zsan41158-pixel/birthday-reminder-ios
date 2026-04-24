// 生日类型
class BirthdayType {
  static const int lunar = 0;   // 仅农历
  static const int solar = 1;   // 仅公历
  static const int both = 2;    // 两者都选
}

// 重复规则
class RepeatRule {
  static const int yearly = 0;  // 每年重复
  static const int once = 1;    // 不重复
}

// 默认设置
class AppDefaults {
  static const String reminderTime = '08:00:00';
  static const int popupDuration = 30;       // 秒
  static const int snoozeInterval = 10;      // 分钟
  static const bool soundEnabled = true;
}

// 数据库
class DbConfig {
  static const String dbName = 'birthday_reminder.db';
  static const int dbVersion = 1;
}

// 通知
class NotificationConfig {
  static const String channelId = 'birthday_reminder_channel';
  static const String channelName = '生日提醒';
  static const String channelDesc = '家人生日定时通知';
  static const int scheduleAheadYears = 2;   // 预注册未来2年的通知
}
