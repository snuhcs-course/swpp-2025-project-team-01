import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';

/// FlutterBackground 플러그인을 위한 서비스 클래스
///
/// 테스트 시 이 클래스를 상속하거나 Fake 객체로 대체하여 사용
class BackgroundService {
  final FlutterBackgroundAndroidConfig _androidConfig =
      const FlutterBackgroundAndroidConfig(
        notificationTitle: 'Generating Lecture',
        notificationText: 'Processing lecture...',
        notificationImportance: AndroidNotificationImportance.high,
        enableWifiLock: true,
      );

  Future<bool> initialize() async {
    try {
      return await FlutterBackground.initialize(androidConfig: _androidConfig);
    } catch (e) {
      debugPrint('Failed to initialize background service: $e');
      return false;
    }
  }

  Future<void> enableBackgroundExecution() async {
    try {
      final isEnabled = FlutterBackground.isBackgroundExecutionEnabled;
      if (isEnabled) {
        return;
      }
      await FlutterBackground.enableBackgroundExecution();
    } catch (e) {
      debugPrint('Failed to enable background execution: $e');
    }
  }

  Future<void> disableBackgroundExecution() async {
    try {
      final isEnabled = FlutterBackground.isBackgroundExecutionEnabled;
      if (isEnabled) {
        await FlutterBackground.disableBackgroundExecution();
      }
    } catch (e) {
      debugPrint('Failed to disable background execution: $e');
    }
  }
}
