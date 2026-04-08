import 'dart:io';
import 'package:safe_device/safe_device.dart';
import 'package:screen_protector/screen_protector.dart';

class SecurityService {
  static Future<void> checkSecurity() async {
    bool isJailBroken = await SafeDevice.isJailBroken;
    bool isRealDevice = await SafeDevice.isRealDevice;
    bool isMockLocation = await SafeDevice.isMockLocation;
    bool isDevelopmentModeEnable = await SafeDevice.isDevelopmentModeEnable;

    if (isJailBroken || !isRealDevice || isMockLocation) {
      _killApp("Security violation (Root/Emulator/GPS)");
    }

    /*
    if (isDevelopmentModeEnable) {
      _killApp("Developer mode is active.");
    }
    */

    await _setupScreenProtection();
  }

  static Future<void> _setupScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
    } catch (e) {
      print("Błąd ochrony ekranu: $e");
    }
  }

  static void _killApp(String message) {
    print("SECURITY ALERT: $message");
    exit(0);
  }
}