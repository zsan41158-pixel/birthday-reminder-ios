# 生日提醒 iOS App

基于 Flutter 开发的农历/公历家人生日定时提醒应用，支持 iOS 本地通知、数据加密存储、备份恢复。

## 功能特性

- ✅ 支持农历、公历、两者都选三种生日类型
- ✅ 每年重复 / 不重复提醒设置
- ✅ iOS 本地推送通知（横幅/锁屏/声音）
- ✅ 数据 AES-256 加密存储（密钥保存在 iOS Keychain）
- ✅ 数据备份/恢复（通过 iOS 分享面板导出加密数据库）
- ✅ 家人信息增删改查 + 搜索
- ✅ 通知权限管理
- ✅ 提醒时间、声音、稍后间隔自定义

## 技术栈

| 功能 | 依赖包 |
|------|--------|
| 状态管理 | `flutter_riverpod` |
| 本地数据库 | `sqflite` |
| 数据加密 | `encrypt` + `flutter_secure_storage` |
| 本地通知 | `flutter_local_notifications` + `timezone` |
| 权限管理 | `permission_handler` |
| 文件分享 | `share_plus` + `file_picker` |
| 农历转换 | `chinese_lunar_calendar` |

## 环境要求

- macOS（Xcode 15+）
- Flutter 3.19+
- iOS 12.0+

## 构建与运行

```bash
# 1. 进入项目目录
cd birthday_reminder_ios

# 2. 获取依赖
flutter pub get

# 3. 进入 ios 目录安装 CocoaPods 依赖
cd ios
pod install
cd ..

# 4. 在 iOS 模拟器或真机上运行
flutter run

# 5. 构建 Release 版本
flutter build ios --release
```

## 注意事项

1. **农历库兼容**：如果 `chinese_lunar_calendar` 包 API 变动导致编译失败，请根据实际版本调整 `lib/services/lunar_service.dart` 中的调用方式。
2. **通知权限**：首次使用需在设置页或系统弹窗中授权通知权限，否则无法收到提醒。
3. **农历通知策略**：iOS 本地通知不支持"每年农历 X 月 X 日"的重复规则，App 会在启动时自动计算未来 2 年的农历生日对应公历日期并批量注册通知。建议保持 App 定期前台运行，以便补充未来年份的通知。
4. **真机测试**：通知功能在 iOS 模拟器上可能表现不完整，建议在真机上测试。

## 项目结构

```
lib/
├── main.dart                    # 入口
├── app.dart                     # MaterialApp 主题配置
├── config/
│   └── constants.dart           # 常量（生日类型、重复规则、默认值）
├── models/
│   └── family_member.dart       # 家人数据模型
├── repositories/
│   └── database_repository.dart # sqflite + AES 加密数据库
├── services/
│   ├── lunar_service.dart       # 农历/公历转换
│   ├── notification_service.dart # 本地通知调度引擎
│   └── backup_service.dart      # 备份/恢复
├── providers/
│   ├── member_provider.dart     # 家人列表状态管理
│   └── settings_provider.dart   # 设置状态管理
├── screens/
│   ├── home_screen.dart         # 首页列表
│   ├── member_form_screen.dart  # 添加/编辑家人
│   └── settings_screen.dart     # 设置页
└── widgets/                     # 可复用组件（预留）
```
