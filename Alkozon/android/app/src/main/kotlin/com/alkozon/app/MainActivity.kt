package com.alkozon.app

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.alkozon.app/signing",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSigningCertSha256" -> {
                    try {
                        result.success(readSigningCertSha256())
                    } catch (error: Exception) {
                        result.error(
                            "SIGNING_ERROR",
                            error.message,
                            null,
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun readSigningCertSha256(): String {
        val signature =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val packageInfo =
                    packageManager.getPackageInfo(
                        packageName,
                        PackageManager.GET_SIGNING_CERTIFICATES,
                    )
                val signingInfo =
                    packageInfo.signingInfo
                        ?: throw IllegalStateException("Brak informacji o podpisie APK")
                val signers = signingInfo.apkContentsSigners
                if (signers != null && signers.isNotEmpty()) {
                    signers[0]
                } else {
                    val history = signingInfo.signingCertificateHistory
                    history?.lastOrNull()
                        ?: throw IllegalStateException("Brak certyfikatu podpisu APK")
                }
            } else {
                @Suppress("DEPRECATION")
                val packageInfo =
                    packageManager.getPackageInfo(
                        packageName,
                        PackageManager.GET_SIGNATURES,
                    )
                @Suppress("DEPRECATION")
                val signatures = packageInfo.signatures
                signatures?.firstOrNull()
                    ?: throw IllegalStateException("Brak certyfikatu podpisu APK")
            }

        val digest =
            MessageDigest
                .getInstance("SHA-256")
                .digest(signature.toByteArray())

        return digest.joinToString("") { byte -> "%02x".format(byte) }
    }
}
