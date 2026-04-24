import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/family_member.dart';
import '../providers/member_provider.dart';

class MemberFormScreen extends ConsumerStatefulWidget {
  final FamilyMember? member;
  const MemberFormScreen({super.key, this.member});

  @override
  ConsumerState<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends ConsumerState<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  int _birthdayType = BirthdayType.lunar;
  int _repeatRule = RepeatRule.yearly;

  int? _lunarMonth;
  int? _lunarDay;
  TimeOfDay _lunarTime = const TimeOfDay(hour: 8, minute: 0);

  int? _solarYear;
  int? _solarMonth;
  int? _solarDay;
  TimeOfDay _solarTime = const TimeOfDay(hour: 8, minute: 0);

  bool get _isEdit => widget.member != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final m = widget.member!;
      _nameController.text = m.name;
      _birthdayType = m.birthdayType;
      _repeatRule = m.repeatRule;
      _lunarMonth = m.lunarMonth;
      _lunarDay = m.lunarDay;
      if (m.lunarReminderTime != null) {
        final parts = m.lunarReminderTime!.split(':');
        _lunarTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
      _solarYear = m.solarYear;
      _solarMonth = m.solarMonth;
      _solarDay = m.solarDay;
      if (m.solarReminderTime != null) {
        final parts = m.solarReminderTime!.split(':');
        _solarTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    } else {
      _solarYear = DateTime.now().year - 30;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isLunar) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isLunar ? _lunarTime : _solarTime,
    );
    if (picked != null) {
      setState(() {
        if (isLunar) {
          _lunarTime = picked;
        } else {
          _solarTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_birthdayType == BirthdayType.lunar || _birthdayType == BirthdayType.both) {
      if (_lunarMonth == null || _lunarDay == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择农历生日')),
        );
        return;
      }
    }
    if (_birthdayType == BirthdayType.solar || _birthdayType == BirthdayType.both) {
      if (_solarYear == null || _solarMonth == null || _solarDay == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择公历生日')),
        );
        return;
      }
    }

    final member = FamilyMember(
      id: widget.member?.id,
      name: _nameController.text.trim(),
      birthdayType: _birthdayType,
      lunarMonth: (_birthdayType == BirthdayType.lunar || _birthdayType == BirthdayType.both) ? _lunarMonth : null,
      lunarDay: (_birthdayType == BirthdayType.lunar || _birthdayType == BirthdayType.both) ? _lunarDay : null,
      lunarReminderTime: (_birthdayType == BirthdayType.lunar || _birthdayType == BirthdayType.both)
          ? _formatTime(_lunarTime)
          : null,
      solarYear: (_birthdayType == BirthdayType.solar || _birthdayType == BirthdayType.both) ? _solarYear : null,
      solarMonth: (_birthdayType == BirthdayType.solar || _birthdayType == BirthdayType.both) ? _solarMonth : null,
      solarDay: (_birthdayType == BirthdayType.solar || _birthdayType == BirthdayType.both) ? _solarDay : null,
      solarReminderTime: (_birthdayType == BirthdayType.solar || _birthdayType == BirthdayType.both)
          ? _formatTime(_solarTime)
          : null,
      repeatRule: _repeatRule,
      createdAt: widget.member?.createdAt ?? DateTime.now().toIso8601String(),
    );

    if (_isEdit) {
      ref.read(memberListProvider.notifier).updateMember(member);
    } else {
      ref.read(memberListProvider.notifier).addMember(member);
    }

    Navigator.pop(context);
  }

  Widget _buildLunarSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('农历生日', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _lunarMonth,
                    decoration: const InputDecoration(labelText: '农历月'),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m月')))
                        .toList(),
                    onChanged: (v) => setState(() => _lunarMonth = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _lunarDay,
                    decoration: const InputDecoration(labelText: '农历日'),
                    items: List.generate(30, (i) => i + 1)
                        .map((d) => DropdownMenuItem(value: d, child: Text('$d日')))
                        .toList(),
                    onChanged: (v) => setState(() => _lunarDay = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('提醒时间'),
              subtitle: Text(_formatTime(_lunarTime)),
              trailing: const Icon(Icons.access_time),
              onTap: () => _pickTime(true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolarSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('公历生日', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    value: _solarYear,
                    decoration: const InputDecoration(labelText: '年'),
                    items: List.generate(121, (i) => 1900 + i)
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y年')))
                        .toList(),
                    onChanged: (v) => setState(() => _solarYear = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _solarMonth,
                    decoration: const InputDecoration(labelText: '月'),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                        .toList(),
                    onChanged: (v) => setState(() => _solarMonth = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _solarDay,
                    decoration: const InputDecoration(labelText: '日'),
                    items: List.generate(31, (i) => i + 1)
                        .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                        .toList(),
                    onChanged: (v) => setState(() => _solarDay = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('提醒时间'),
              subtitle: Text(_formatTime(_solarTime)),
              trailing: const Icon(Icons.access_time),
              onTap: () => _pickTime(false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showLunar = _birthdayType == BirthdayType.lunar || _birthdayType == BirthdayType.both;
    final showSolar = _birthdayType == BirthdayType.solar || _birthdayType == BirthdayType.both;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑家人' : '添加家人'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 姓名
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '家人姓名',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? '请输入姓名' : null,
            ),
            const SizedBox(height: 20),

            // 生日类型
            const Text('生日类型', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: BirthdayType.lunar, label: Text('仅农历')),
                ButtonSegment(value: BirthdayType.solar, label: Text('仅公历')),
                ButtonSegment(value: BirthdayType.both, label: Text('两者都选')),
              ],
              selected: {_birthdayType},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  setState(() => _birthdayType = set.first);
                }
              },
            ),
            const SizedBox(height: 20),

            // 农历部分
            if (showLunar) _buildLunarSection(),
            if (showLunar && showSolar) const SizedBox(height: 12),

            // 公历部分
            if (showSolar) _buildSolarSection(),
            const SizedBox(height: 20),

            // 重复规则
            const Text('重复规则', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: RepeatRule.yearly, label: Text('每年重复')),
                ButtonSegment(value: RepeatRule.once, label: Text('不重复')),
              ],
              selected: {_repeatRule},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  setState(() => _repeatRule = set.first);
                }
              },
            ),
            const SizedBox(height: 32),

            // 保存按钮
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(_isEdit ? '保存修改' : '添加家人'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
