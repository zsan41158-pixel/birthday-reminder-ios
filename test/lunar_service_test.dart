import 'package:flutter_test/flutter_test.dart';
import 'package:birthday_reminder_ios/services/lunar_service.dart';

void main() {
  group('LunarService Tests', () {
    late LunarService lunarService;

    setUp(() {
      lunarService = LunarService();
    });

    test('solarToLunar should convert solar date to lunar date', () {
      // 2024年春节是2月10日
      final result = lunarService.solarToLunar(DateTime(2024, 2, 10));
      expect(result['year'], 2024);
      expect(result['month'], 1);
      expect(result['day'], 1);
      expect(result['isLeap'], 0);
    });

    test('solarToLunar should handle leap month', () {
      // 2023年有闰二月
      final result = lunarService.solarToLunar(DateTime(2023, 4, 20));
      expect(result['year'], 2023);
      expect(result['month'], 3);
      expect(result['isLeap'], 0);
    });

    test('lunarToSolar should convert lunar date to solar date', () {
      // 2024年农历正月初一
      final result = lunarService.lunarToSolar(1, 1, year: 2024);
      expect(result, isNotNull);
      expect(result!.year, 2024);
      expect(result.month, 2);
      expect(result.day, 10);
    });

    test('lunarToSolar should return null for invalid date', () {
      // 无效的农历日期
      final result = lunarService.lunarToSolar(13, 1, year: 2024);
      expect(result, isNull);
    });

    test('lunarToSolar should return null for out of range year', () {
      final result = lunarService.lunarToSolar(1, 1, year: 1800);
      expect(result, isNull);
    });

    test('isTodayLunarBirthday should return false for non-birthday', () {
      // 使用一个肯定不是今天的农历生日
      final result = lunarService.isTodayLunarBirthday(1, 1);
      expect(result, false);
    });

    test('isTodaySolarBirthday should return false for non-birthday', () {
      // 使用一个肯定不是今天的公历生日
      final result = lunarService.isTodaySolarBirthday(1, 1);
      expect(result, false);
    });

    test('getNextLunarBirthday should return future date', () {
      final result = lunarService.getNextLunarBirthday(1, 1);
      expect(result, isNotNull);
      expect(result!.isAfter(DateTime.now()), true);
    });

    test('getNextSolarBirthday should return future date', () {
      final result = lunarService.getNextSolarBirthday(12, 31);
      expect(result.isAfter(DateTime.now()), true);
    });

    test('formatLunarDate should format correctly', () {
      final result = lunarService.formatLunarDate(1, 15);
      expect(result, '农历1月15日');
    });

    test('formatSolarDate should format correctly', () {
      final result = lunarService.formatSolarDate(2024, 2, 10);
      expect(result, '2024年2月10日');
    });

    test('solarToLunar should handle boundary dates', () {
      // 测试边界日期
      final result1 = lunarService.solarToLunar(DateTime(1900, 1, 31));
      expect(result1['year'], 1900);
      expect(result1['month'], 1);
      expect(result1['day'], 1);

      final result2 = lunarService.solarToLunar(DateTime(2100, 12, 31));
      expect(result2['year'], 2100);
      expect(result2['month'], 12);
      expect(result2['day'], 30);
    });
  });
}
