import 'package:flutter_test/flutter_test.dart';
import 'package:birthday_reminder_ios/models/family_member.dart';

void main() {
  group('FamilyMember Tests', () {
    test('toMap should create correct map', () {
      final member = FamilyMember(
        id: 1,
        name: '张三',
        birthdayType: 0,
        lunarMonth: 1,
        lunarDay: 15,
        solarYear: 1990,
        solarMonth: 3,
        solarDay: 10,
        lunarReminderTime: '08:00:00',
        solarReminderTime: '09:00:00',
        repeatRule: 0,
        createdAt: '2024-01-01T00:00:00',
      );

      final map = member.toMap();
      expect(map['id'], 1);
      expect(map['name'], '张三');
      expect(map['birthday_type'], 0);
      expect(map['lunar_month'], 1);
      expect(map['lunar_day'], 15);
      expect(map['solar_year'], 1990);
      expect(map['solar_month'], 3);
      expect(map['solar_day'], 10);
      expect(map['lunar_reminder_time'], '08:00:00');
      expect(map['solar_reminder_time'], '09:00:00');
      expect(map['repeat_rule'], 0);
      expect(map['created_at'], '2024-01-01T00:00:00');
    });

    test('fromMap should create FamilyMember from map', () {
      final map = {
        'id': 1,
        'name': '张三',
        'birthday_type': 0,
        'lunar_month': 1,
        'lunar_day': 15,
        'solar_year': 1990,
        'solar_month': 3,
        'solar_day': 10,
        'lunar_reminder_time': '08:00:00',
        'solar_reminder_time': '09:00:00',
        'repeat_rule': 0,
        'created_at': '2024-01-01T00:00:00',
      };

      final member = FamilyMember.fromMap(map);
      expect(member.id, 1);
      expect(member.name, '张三');
      expect(member.birthdayType, 0);
      expect(member.lunarMonth, 1);
      expect(member.lunarDay, 15);
      expect(member.solarYear, 1990);
      expect(member.solarMonth, 3);
      expect(member.solarDay, 10);
      expect(member.lunarReminderTime, '08:00:00');
      expect(member.solarReminderTime, '09:00:00');
      expect(member.repeatRule, 0);
      expect(member.createdAt, '2024-01-01T00:00:00');
    });

    test('copyWith should create new instance with updated values', () {
      final member = FamilyMember(
        id: 1,
        name: '张三',
        birthdayType: 0,
        lunarMonth: 1,
        lunarDay: 15,
        repeatRule: 0,
        createdAt: '2024-01-01T00:00:00',
      );

      final newMember = member.copyWith(name: '李四', lunarMonth: 2);
      expect(newMember.id, 1);
      expect(newMember.name, '李四');
      expect(newMember.lunarMonth, 2);
      expect(newMember.lunarDay, 15);
      expect(newMember.birthdayType, 0);
    });

    test('birthdayTypeText should return correct text', () {
      final member1 = FamilyMember(
        name: '张三',
        birthdayType: 0,
        repeatRule: 0,
        createdAt: '2024-01-01T00:00:00',
      );
      expect(member1.birthdayTypeText, '农历');

      final member2 = FamilyMember(
        name: '李四',
        birthdayType: 1,
        repeatRule: 0,
        createdAt: '2024-01-01T00:00:00',
      );
      expect(member2.birthdayTypeText, '公历');

      final member3 = FamilyMember(
        name: '王五',
        birthdayType: 2,
        repeatRule: 0,
        createdAt: '2024-01-01T00:00:00',
      );
      expect(member3.birthdayTypeText, '农历+公历');
    });

    test('lunarBirthdayText should format correctly', () {
      final member = FamilyMember(
        name: '张三',
        birthdayType: 0,
        lunarMonth: 1,
        lunarDay: 15,
        repeatRule: 0,
        createdAt: '2024-01-01T00:00:00',
      );
      expect(member.lunarBirthdayText, '农历1月15日');

      final member2 = FamilyMember(
        name: '李四',
        birthdayType: 0,
        repeatRule: 0,
        createdAt: '2024-01-01T00:00:00',
      );
      expect(member2.lunarBirthdayText, '-');
    });

    test('solarBirthdayText should format correctly', () {
      final member = FamilyMember(
        name: '张三',
        birthdayType: 1,
        solarYear: 1990,
        solarMonth: 3,
        solarDay: 10,
        repeatRule: 0,
        createdAt: '2024-01-01T00:00:00',
      );
      expect(member.solarBirthdayText, '1990年3月10日');

      final member2 = FamilyMember(
        name: '李四',
        birthdayType: 1,
        repeatRule: 0,
        createdAt: '2024-01-01T00:00:00',
      );
      expect(member2.solarBirthdayText, '-');
    });

    test('reminderTimeText should format correctly', () {
      final member1 = FamilyMember(
        name: '张三',
        birthdayType: 0,
        lunarReminderTime: '08:00:00',
        repeatRule: 0,
        createdAt: '2024-01-01T00:00:00',
      );
      expect(member1.reminderTimeText, '农历 08:00:00');

      final member2 = FamilyMember(
        name: '李四',
        birthdayType: 1,
        solarReminderTime: '09:00:00',
        repeatRule: 0,
        createdAt: '2024-01-01T00:00:00',
      );
      expect(member2.reminderTimeText, '公历 09:00:00');

      final member3 = FamilyMember(
        name: '王五',
        birthdayType: 2,
        lunarReminderTime: '08:00:00',
        solarReminderTime: '09:00:00',
        repeatRule: 0,
        createdAt: '2024-01-01T00:00:00',
      );
      expect(member3.reminderTimeText, '农历 08:00:00 / 公历 09:00:00');
    });
  });
}
