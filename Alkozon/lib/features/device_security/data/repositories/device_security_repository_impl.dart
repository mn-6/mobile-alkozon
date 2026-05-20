import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:safe_device/safe_device.dart';
import 'package:screen_protector/screen_protector.dart';

import '../../../../core/security/app_termination.dart';
import '../../../../core/security/signing_cert_verifier.dart';
import '../../../../core/security/signing_config.dart';
import '../../domain/repositories/device_security_repository.dart';
import '../datasources/app_check_remote_data_source.dart';

class DeviceSecurityRepositoryImpl implements DeviceSecurityRepository {
  DeviceSecurityRepositoryImpl({AppCheckRemoteDataSource? appCheckDataSource})
    : _appCheckDataSource = appCheckDataSource ?? AppCheckRemoteDataSource();

  final AppCheckRemoteDataSource _appCheckDataSource;

  @override
  Future<void> checkDeviceSecurity() async {
    final isJailBroken = await SafeDevice.isJailBroken;
    final isRealDevice = await SafeDevice.isRealDevice;
    final isMockLocation = await SafeDevice.isMockLocation;
    final isDevelopmentModeEnable = await SafeDevice.isDevelopmentModeEnable;

    if (isJailBroken || !isRealDevice || isMockLocation) {
      terminateApp('Security violation (Root/Emulator/GPS)');
    }

    /*
    if (isDevelopmentModeEnable) {
      killApp('Developer mode is active.');
    }
    */

    await _verifyApkSigningOrExit();
    await _setupScreenProtection();

    assert(() {
      if (isDevelopmentModeEnable) {
        debugPrint('Developer mode is active (not blocked in debug builds).');
      }
      return true;
    }());
  }

  Future<void> _verifyApkSigningOrExit() async {
    if (!Platform.isAndroid) {
      return;
    }

    final signingCertSha256 = await _appCheckDataSource.readSigningCertSha256();
    if (!SigningCertVerifier.isAllowed(
      signingCertSha256,
      SigningConfig.allowedSigningCertSha256,
    )) {
      terminateApp('Invalid APK signing certificate (SHA-256).');
    }
  }

  Future<void> _setupScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
    } catch (e) {
      debugPrint('Screen protection error: $e');
    }
  }
}
