import 'package:chinese_lunar_calendar/chinese_lunar_calendar.dart';

class LunarService {
  static final LunarService _instance = LunarService._internal();
  factory LunarService() => _instance;
  LunarService._internal();

  /// 农历月日转当年的公历日期
  DateTime? lunarToSolar(int lunarMonth, int lunarDay, {int? year}) {
    final targetYear = year ?? DateTime.now().year;
    try {
      // chinese_lunar_calendar 的用法：构建当年农历对象
      final lunarCalendar = LunarCalendar.from(
        utcDateTime: DateTime.utc(targetYear, 1, 1),
      );
      // 注意：该库主要是公历转农历，农历转公历需要查找
      // 这里采用逐日扫描法：从当年1月1日开始扫描365天，找到农历匹配的日期
      for (int i = 0; i < 366; i++) {
        final dt = DateTime(targetYear, 1, 1).add(Duration(days: i));
        if (dt.year != targetYear) break;
        final lc = LunarCalendar.from(utcDateTime: dt.toUtc());
        final lm = lc.lunarDate.month;
        final ld = lc.lunarDate.day;
        if (lm == lunarMonth && ld == lunarDay) {
          return dt;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 判断今天是否农历生日
  bool isTodayLunarBirthday(int lunarMonth, int lunarDay) {
    final today = DateTime.now();
    final lc = LunarCalendar.from(utcDateTime: today.toUtc());
    return lc.lunarDate.month == lunarMonth && lc.lunarDate.day == lunarDay;
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
    if (result != null && result.isAfter(now.subtract(const Duration(days: 1)))) {
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
    if (result.isBefore(now.subtract(const Duration(days: 1)))) {
      result = DateTime(now.year + 1, month, day);
    }
    return result;
  }

  /// 格式化农历日期显示
  String formatLunarDate(int month, int day) {
    return '农历${month}月${day}日';
  }

  /// 格式化公历日期显示
  String formatSolarDate(int year, int month, int day) {
    return '$year年${month}月${day}日';
  }
}
