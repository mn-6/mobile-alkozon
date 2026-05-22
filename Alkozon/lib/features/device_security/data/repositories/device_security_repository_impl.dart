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
    final isUsbDebuggingEnabled = await SafeDevice.isUsbDebuggingEnabled;

    if (isJailBroken || !isRealDevice || isMockLocation) {
      debugPrint(
        'Security: jailBroken=$isJailBroken realDevice=$isRealDevice mockLocation=$isMockLocation',
      );
      terminateApp(
        'Wykryto naruszenie bezpieczeństwa (root, emulator lub fałszywa lokalizacja).',
      );
    }

    if (isDevelopmentModeEnable && kReleaseMode) {
      terminateApp('Aktywne opcje deweloperskie nie są dozwolone.');
    }

    if (isUsbDebuggingEnabled && kReleaseMode) {
      terminateApp(
        'Wyłącz debugowanie USB w opcjach deweloperskich, aby korzystać z aplikacji.',
      );
    }

    await _verifyApkSigningOrExit();
    await _setupScreenProtection();

    assert(() {
      if (isDevelopmentModeEnable) {
        debugPrint('Opcje deweloperskie włączone (nie blokują w buildzie debug).');
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
      debugPrint('Security: cert SHA-256=$signingCertSha256');
      terminateApp('Nieprawidłowy certyfikat podpisu APK (SHA-256).');
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
