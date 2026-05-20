import '../../../../core/network/auth_token_provider.dart';
import '../entities/login_result.dart';
import '../entities/user_profile.dart';

abstract class AuthRepository implements AuthTokenProvider {
  Future<LoginResult> login({
    required String email,
    required String password,
    String? verificationCode,
    String? challengeId,
  });

  Future<void> logout();

  Future<String> getOrCreateDeviceId();

  Future<bool> isAuthenticated();

  Future<UserProfile?> getCurrentUserProfile();

  Future<String?> getCurrentUserFullName();

  Future<String?> getCurrentUserEmail();

  Map<String, dynamic>? decodeTokenClaims(String token);
}
