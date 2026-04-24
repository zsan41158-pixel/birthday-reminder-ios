import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _exporting = false;
  bool _importing = false;

  Future<void> _requestNotificationPermission() async {
    final granted = await NotificationService().requestPermission();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted ? '通知权限已获取' : '通知权限被拒绝，请前往系统设置开启'),
        ),
      );
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      await BackupService().exportData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    } finally {
      setState(() => _exporting = false);
    }
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      await BackupService().importData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导入成功，请重启App')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    } finally {
      setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            // 通知权限
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('通知权限'),
              subtitle: const Text('开启后才能收到生日提醒'),
              trailing: FilledButton.tonal(
                onPressed: _requestNotificationPermission,
                child: const Text('去开启'),
              ),
            ),
            const Divider(),

            // 弹窗持续时间
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('通知横幅停留时间'),
              subtitle: Text('${settings.popupDuration} 秒'),
              trailing: SizedBox(
                width: 120,
                child: Slider(
                  value: settings.popupDuration.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  label: '${settings.popupDuration}秒',
                  onChanged: (v) {
                    ref.read(settingsProvider.notifier).updateSettings(
                      popupDuration: v.round(),
                    );
                  },
                ),
              ),
            ),

            // 稍后提醒间隔
            ListTile(
              leading: const Icon(Icons.snooze_outlined),
              title: const Text('稍后提醒间隔'),
              subtitle: Text('${settings.snoozeInterval} 分钟'),
              trailing: SizedBox(
                width: 120,
                child: Slider(
                  value: settings.snoozeInterval.toDouble(),
                  min: 1,
                  max: 60,
                  divisions: 59,
                  label: '${settings.snoozeInterval}分',
                  onChanged: (v) {
                    ref.read(settingsProvider.notifier).updateSettings(
                      snoozeInterval: v.round(),
                    );
                  },
                ),
              ),
            ),

            // 声音开关
            SwitchListTile(
              secondary: const Icon(Icons.volume_up_outlined),
              title: const Text('提醒声音'),
              subtitle: const Text('通知时播放提示音'),
              value: settings.soundEnabled,
              onChanged: (v) {
                ref.read(settingsProvider.notifier).updateSettings(
                  soundEnabled: v,
                );
              },
            ),
            const Divider(),

            // 数据备份
            ListTile(
              leading: _exporting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_outlined),
              title: const Text('备份数据'),
              subtitle: const Text('导出加密数据库到其他应用'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _exporting ? null : _export,
            ),

            // 数据恢复
            ListTile(
              leading: _importing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_outlined),
              title: const Text('恢复数据'),
              subtitle: const Text('从备份文件导入（会覆盖现有数据）'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _importing ? null : _import,
            ),
            const Divider(),

            // 关于
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('关于'),
              subtitle: Text('生日提醒 v1.0.0'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }
}
