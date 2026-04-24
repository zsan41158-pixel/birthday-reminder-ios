import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../repositories/database_repository.dart';

class AppSettings {
  final int popupDuration;
  final bool soundEnabled;
  final int snoozeInterval;

  AppSettings({
    required this.popupDuration,
    required this.soundEnabled,
    required this.snoozeInterval,
  });

  AppSettings copyWith({
    int? popupDuration,
    bool? soundEnabled,
    int? snoozeInterval,
  }) {
    return AppSettings(
      popupDuration: popupDuration ?? this.popupDuration,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      snoozeInterval: snoozeInterval ?? this.snoozeInterval,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  SettingsNotifier() : super(const AsyncValue.loading()) {
    loadSettings();
  }

  final _dbRepo = DatabaseRepository();

  Future<void> loadSettings() async {
    try {
      final popupDuration = int.tryParse(
            await _dbRepo.getSetting('popup_duration') ?? '${AppDefaults.popupDuration}',
          ) ??
          AppDefaults.popupDuration;
      final soundEnabled = (await _dbRepo.getSetting('sound_enabled') ?? '${AppDefaults.soundEnabled}') == 'true';
      final snoozeInterval = int.tryParse(
            await _dbRepo.getSetting('snooze_interval') ?? '${AppDefaults.snoozeInterval}',
          ) ??
          AppDefaults.snoozeInterval;

      state = AsyncValue.data(AppSettings(
        popupDuration: popupDuration,
        soundEnabled: soundEnabled,
        snoozeInterval: snoozeInterval,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings({
    int? popupDuration,
    bool? soundEnabled,
    int? snoozeInterval,
  }) async {
    final current = state.value;
    if (current == null) return;

    final newSettings = current.copyWith(
      popupDuration: popupDuration,
      soundEnabled: soundEnabled,
      snoozeInterval: snoozeInterval,
    );

    await _dbRepo.setSetting('popup_duration', '${newSettings.popupDuration}');
    await _dbRepo.setSetting('sound_enabled', '${newSettings.soundEnabled}');
    await _dbRepo.setSetting('snooze_interval', '${newSettings.snoozeInterval}');

    state = AsyncValue.data(newSettings);
  }
}
