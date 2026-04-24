import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../repositories/database_repository.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final _dbRepo = DatabaseRepository();

  /// 导出数据库到分享面板
  Future<void> exportData() async {
    final dbPath = await _dbRepo.getDatabasePath();
    final file = File(dbPath);
    if (!await file.exists()) {
      throw Exception('数据库文件不存在');
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupFile = File('${tempDir.path}/birthday_reminder_backup_$timestamp.db');
    await file.copy(backupFile.path);

    await Share.shareXFiles(
      [XFile(backupFile.path)],
      text: '生日提醒数据备份',
    );
  }

  /// 从文件导入数据库
  Future<void> importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final pickPath = result.files.single.path;
    if (pickPath == null) return;

    final sourceFile = File(pickPath);
    if (!await sourceFile.exists()) {
      throw Exception('选择的文件不存在');
    }

    // 关闭当前数据库连接
    await _dbRepo.close();

    final dbPath = await _dbRepo.getDatabasePath();
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    await sourceFile.copy(dbPath);

    // 重新打开数据库
    await _dbRepo.database;
  }
}
