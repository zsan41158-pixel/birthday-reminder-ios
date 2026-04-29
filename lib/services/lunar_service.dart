/// 自包含农历转换服务
/// 基于标准农历数据表（1900-2100年），无需外部依赖
class LunarService {
  static final LunarService _instance = LunarService._internal();
  factory LunarService() => _instance;
  LunarService._internal();

  // 1900-2100年农历数据表
  // 每个元素的存储格式（20位）：
  // bit 0-11：农历1-12月的大小（1=30天，0=29天）
  // bit 12-15：闰月月份（0表示无闰月）
  // bit 16：闰月大小（1=30天，0=29天）
  static final List<int> _lunarInfo = [
    0x04bd8,0x04ae0,0x0a570,0x054d5,0x0d260,0x0d950,0x16554,0x056a0,0x09ad0,0x055d2,
    0x04ae0,0x0a5b6,0x0a4d0,0x0d250,0x1d255,0x0b540,0x0d6a0,0x0ada2,0x095b0,0x14977,
    0x04970,0x0a4b0,0x0b4b5,0x06a50,0x06d40,0x1ab54,0x02b60,0x09570,0x052f2,0x04970,
    0x06566,0x0d4a0,0x0ea50,0x06e95,0x05ad0,0x02b60,0x186e3,0x092e0,0x1c8d7,0x0c950,
    0x0d4a0,0x1d8a6,0x0b550,0x056a0,0x1a5b4,0x025d0,0x092d0,0x0d2b2,0x0a950,0x0b557,
    0x06ca0,0x0b550,0x15355,0x04da0,0x0a5d0,0x14573,0x052d0,0x0a9a8,0x0e950,0x06aa0,
    0x0aea6,0x0ab50,0x04b60,0x0aae4,0x0a570,0x05260,0x0f263,0x0d950,0x05b57,0x056a0,
    0x096d0,0x04dd5,0x04ad0,0x0a4d0,0x0d4d4,0x0d250,0x0d558,0x0b540,0x0b5a0,0x195a6,
    0x095b0,0x049b0,0x0a974,0x0a4b0,0x0b27a,0x06a50,0x06d40,0x0af46,0x0ab60,0x09570,
    0x04af5,0x04970,0x064b0,0x074a3,0x0ea50,0x06b58,0x055c0,0x0ab60,0x096d5,0x092e0,
    0x0c960,0x0d954,0x0d4a0,0x0da50,0x07552,0x056a0,0x0abb7,0x025d0,0x092d0,0x0cab5,
    0x0a950,0x0b4a0,0x0baa4,0x0ad50,0x055d9,0x04ba0,0x0a5b0,0x15176,0x052b0,0x0a930,
    0x07954,0x06aa0,0x0ad50,0x05b52,0x04b60,0x0a6e6,0x0a4e0,0x0d260,0x0ea65,0x0d530,
    0x05aa0,0x076a3,0x096d0,0x04bd7,0x04ad0,0x0a4d0,0x1d0b6,0x0d250,0x0d520,0x0dd45,
    0x0b5a0,0x056d0,0x055b2,0x049b0,0x0a577,0x0a4b0,0x0aa50,0x1b255,0x06d20,0x0ada0,
    0x14b63,0x09370,0x049f8,0x04970,0x064b0,0x168a6,0x0ea50,0x06b20,0x1a6c4,0x0aae0,
    0x0a2e0,0x0d2e3,0x0c960,0x0d557,0x0d4a0,0x0da50,0x05d55,0x056a0,0x0a6d0,0x055d4,
    0x052d0,0x0a9b8,0x0a950,0x0b4a0,0x0b6a6,0x0ad50,0x055a0,0x0aba4,0x0a5b0,0x052b0,
    0x0b273,0x06930,0x07337,0x06aa0,0x0ad50,0x14b55,0x04b60,0x0a570,0x054e4,0x0d160,
    0x0e968,0x0d520,0x0daa0,0x16aa6,0x056d0,0x04ae0,0x0a9d4,0x0a2d0,0x0d150,0x0f252,
    0x0d520
  ];

  // 返回农历y年的总天数
  static int _lYearDays(int y) {
    int sum = 348;
    for (int i = 0x8000; i > 0x8; i >>= 1) {
      sum += (_lunarInfo[y - 1900] & i) != 0 ? 1 : 0;
    }
    return sum + _leapDays(y);
  }

  // 返回农历y年闰月的天数
  static int _leapDays(int y) {
    if (_leapMonth(y) != 0) {
      return (_lunarInfo[y - 1900] & 0x10000) != 0 ? 30 : 29;
    }
    return 0;
  }

  // 返回农历y年闰哪个月 1-12，没闰返回 0
  static int _leapMonth(int y) {
    return _lunarInfo[y - 1900] & 0xf;
  }

  // 返回农历y年m月的总天数
  static int _monthDays(int y, int m) {
    return (_lunarInfo[y - 1900] & (0x8000 >> (m - 1))) != 0 ? 30 : 29;
  }

  /// 公历日期转农历日期
  /// 返回 {year, month, day, isLeap}
  Map<String, int> solarToLunar(DateTime solar) {
    // 限制在支持范围内，避免数组越界
    if (solar.isBefore(DateTime(1900, 1, 31))) {
      return {'year': 1900, 'month': 1, 'day': 1, 'isLeap': 0};
    }
    if (solar.isAfter(DateTime(2100, 12, 31))) {
      return {'year': 2100, 'month': 12, 'day': 30, 'isLeap': 0};
    }

    DateTime baseDate = DateTime(1900, 1, 31);
    int offset = solar.difference(baseDate).inDays;

    int iYear = 1900;
    int temp = 0;
    for (iYear = 1900; iYear < 2101 && offset > 0; iYear++) {
      temp = _lYearDays(iYear);
      offset -= temp;
    }

    if (offset < 0) {
      offset += temp;
      iYear--;
    }

    int lunarYear = iYear;
    if (lunarYear > 2100) lunarYear = 2100;
    if (lunarYear < 1900) lunarYear = 1900;

    int leap = _leapMonth(lunarYear);
    bool isLeap = false;

    int iMonth = 1;
    for (iMonth = 1; iMonth < 13 && offset > 0; iMonth++) {
      if (leap > 0 && iMonth == (leap + 1) && !isLeap) {
        --iMonth;
        isLeap = true;
        temp = _leapDays(lunarYear);
      } else {
        temp = _monthDays(lunarYear, iMonth);
      }

      if (isLeap && iMonth == (leap + 1)) isLeap = false;
      offset -= temp;
    }

    if (offset == 0 && leap > 0 && iMonth == leap + 1) {
      if (isLeap) {
        isLeap = false;
      } else {
        isLeap = true;
        --iMonth;
      }
    }

    if (offset < 0) {
      offset += temp;
      --iMonth;
    }

    return {
      'year': lunarYear,
      'month': iMonth,
      'day': offset + 1,
      'isLeap': isLeap ? 1 : 0,
    };
  }

  /// 农历转公历（逐日扫描法，精确可靠）
  DateTime? lunarToSolar(int lunarMonth, int lunarDay, {int? year}) {
    final targetYear = year ?? DateTime.now().year;
    if (targetYear < 1900 || targetYear > 2100) return null;

    // 限制农历月份和日期在合理范围
    if (lunarMonth < 1 || lunarMonth > 12 || lunarDay < 1 || lunarDay > 30) return null;

    // 从当年1月1日开始扫描最多400天（覆盖全年+闰月）
    final start = DateTime(targetYear, 1, 1);
    for (int i = 0; i < 400; i++) {
      final dt = start.add(Duration(days: i));
      // 扫描到下一年3月还没找到，说明该农历日期不存在（如闰月问题）
      if (dt.year > targetYear && dt.month > 2) break;

      final lunar = solarToLunar(dt);
      if (lunar['month'] == lunarMonth && lunar['day'] == lunarDay) {
        return dt;
      }
    }
    return null;
  }

  /// 判断今天是否农历生日
  bool isTodayLunarBirthday(int lunarMonth, int lunarDay) {
    final today = DateTime.now();
    final lunar = solarToLunar(today);
    return lunar['month'] == lunarMonth && lunar['day'] == lunarDay;
  }

  /// 判断今天是否公历生日
  bool isTodaySolarBirthday(int month, int day) {
    final today = DateTime.now();
    return today.month == month && today.day == day;
  }

  /// 获取下一个农历生日对应的公历日期
  DateTime? getNextLunarBirthday(int lunarMonth, int lunarDay) {
    final now = DateTime.now();
    // 先尝试今年
    var result = lunarToSolar(lunarMonth, lunarDay, year: now.year);
    if (result != null && !result.isBefore(DateTime(now.year, now.month, now.day))) {
      return result;
    }
    // 尝试明年（处理闰月等边界情况）
    result = lunarToSolar(lunarMonth, lunarDay, year: now.year + 1);
    return result;
  }

  /// 获取下一个公历生日
  DateTime getNextSolarBirthday(int month, int day) {
    final now = DateTime.now();
    var result = DateTime(now.year, month, day);
    if (result.isBefore(DateTime(now.year, now.month, now.day))) {
      result = DateTime(now.year + 1, month, day);
    }
    return result;
  }

  /// 格式化农历日期显示
  String formatLunarDate(int month, int day) {
    return '农历$month月$day日';
  }

  /// 格式化公历日期显示
  String formatSolarDate(int year, int month, int day) {
    return '$year年${month}月${day}日';
  }
}
