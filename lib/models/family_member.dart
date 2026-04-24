class FamilyMember {
  final int? id;
  final String name;
  final int birthdayType;      // 0=农历, 1=公历, 2=两者
  final int? lunarMonth;
  final int? lunarDay;
  final int? solarYear;
  final int? solarMonth;
  final int? solarDay;
  final String? lunarReminderTime;  // HH:mm:ss
  final String? solarReminderTime;  // HH:mm:ss
  final int repeatRule;        // 0=每年重复, 1=不重复
  final int? customIntervalDays;
  final String createdAt;

  FamilyMember({
    this.id,
    required this.name,
    required this.birthdayType,
    this.lunarMonth,
    this.lunarDay,
    this.solarYear,
    this.solarMonth,
    this.solarDay,
    this.lunarReminderTime,
    this.solarReminderTime,
    required this.repeatRule,
    this.customIntervalDays,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birthday_type': birthdayType,
      'lunar_month': lunarMonth,
      'lunar_day': lunarDay,
      'solar_year': solarYear,
      'solar_month': solarMonth,
      'solar_day': solarDay,
      'lunar_reminder_time': lunarReminderTime,
      'solar_reminder_time': solarReminderTime,
      'repeat_rule': repeatRule,
      'custom_interval_days': customIntervalDays,
      'created_at': createdAt,
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'] as int?,
      name: map['name'] as String,
      birthdayType: map['birthday_type'] as int,
      lunarMonth: map['lunar_month'] as int?,
      lunarDay: map['lunar_day'] as int?,
      solarYear: map['solar_year'] as int?,
      solarMonth: map['solar_month'] as int?,
      solarDay: map['solar_day'] as int?,
      lunarReminderTime: map['lunar_reminder_time'] as String?,
      solarReminderTime: map['solar_reminder_time'] as String?,
      repeatRule: map['repeat_rule'] as int,
      customIntervalDays: map['custom_interval_days'] as int?,
      createdAt: map['created_at'] as String,
    );
  }

  FamilyMember copyWith({
    int? id,
    String? name,
    int? birthdayType,
    int? lunarMonth,
    int? lunarDay,
    int? solarYear,
    int? solarMonth,
    int? solarDay,
    String? lunarReminderTime,
    String? solarReminderTime,
    int? repeatRule,
    int? customIntervalDays,
    String? createdAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      birthdayType: birthdayType ?? this.birthdayType,
      lunarMonth: lunarMonth ?? this.lunarMonth,
      lunarDay: lunarDay ?? this.lunarDay,
      solarYear: solarYear ?? this.solarYear,
      solarMonth: solarMonth ?? this.solarMonth,
      solarDay: solarDay ?? this.solarDay,
      lunarReminderTime: lunarReminderTime ?? this.lunarReminderTime,
      solarReminderTime: solarReminderTime ?? this.solarReminderTime,
      repeatRule: repeatRule ?? this.repeatRule,
      customIntervalDays: customIntervalDays ?? this.customIntervalDays,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get birthdayTypeText {
    switch (birthdayType) {
      case 0: return '农历';
      case 1: return '公历';
      case 2: return '农历+公历';
      default: return '未知';
    }
  }

  String get lunarBirthdayText {
    if (lunarMonth == null || lunarDay == null) return '-';
    return '农历${lunarMonth}月${lunarDay}日';
  }

  String get solarBirthdayText {
    if (solarYear == null || solarMonth == null || solarDay == null) return '-';
    return '$solarYear年$solarMonth月$solarDay日';
  }

  String get reminderTimeText {
    final List<String> parts = [];
    if (birthdayType == 0 || birthdayType == 2) {
      if (lunarReminderTime != null) parts.add('农历 $lunarReminderTime');
    }
    if (birthdayType == 1 || birthdayType == 2) {
      if (solarReminderTime != null) parts.add('公历 $solarReminderTime');
    }
    return parts.join(' / ');
  }
}
