import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/security/app_termination.dart';
import '../../../../core/security/signing_cert_verifier.dart';

class AppCheckRemoteDataSource {
  AppCheckRemoteDataSource()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  static const MethodChannel _signingChannel = MethodChannel(
    'com.alkozon.app/signing',
  );

  final Dio _dio;

  Future<void> submitAppCheck() async {
    if (!Platform.isAndroid) {
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final signingCertSha256 = await readSigningCertSha256();

    final versionCode = int.tryParse(packageInfo.buildNumber);
    if (versionCode == null || versionCode < 1) {
      throw StateError('Nieprawidłowy numer wersji aplikacji (versionCode).');
    }

    final response = await _dio.post(
      '/security/app-check',
      data: {
        'platform': 'android',
        'packageName': packageInfo.packageName,
        'versionName': packageInfo.version,
        'versionCode': versionCode,
        'signingCertSha256': signingCertSha256,
      },
      options: Options(validateStatus: (_) => true),
    );

    if (response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 403) {
      terminateApp(
        'Aplikacja nie przeszła weryfikacji bezpieczeństwa (certyfikat APK).',
      );
    }

    if (response.statusCode == 400) {
      throw StateError(
        _errorMessageFromBody(response.data) ??
            'Nieprawidłowe dane weryfikacji aplikacji.',
      );
    }

    throw StateError(
      'Weryfikacja aplikacji nie powiodła się (HTTP ${response.statusCode}).',
    );
  }

  String? _errorMessageFromBody(dynamic data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }

  Future<String> readSigningCertSha256() async {
    try {
      final raw = await _signingChannel.invokeMethod<String>(
        'getSigningCertSha256',
      );
      if (raw == null || raw.isEmpty) {
        throw StateError('Nie można odczytać podpisu aplikacji.');
      }
      return SigningCertVerifier.normalizeSha256(raw);
    } on PlatformException catch (error) {
      throw StateError(
        'Nie można odczytać podpisu aplikacji: ${error.message ?? error.code}',
      );
    }
  }
}
