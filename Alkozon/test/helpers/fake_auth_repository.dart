import 'package:alkozon/features/auth/domain/entities/login_result.dart';
import 'package:alkozon/features/auth/domain/entities/user_profile.dart';
import 'package:alkozon/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  LoginResult loginResult = const LoginFailure('Nie skonfigurowano wyniku logowania');
  bool isAuthenticatedValue = false;
  String? accessToken;
  String? fullName;
  UserProfile? profile;
  String deviceId = 'test-device-1';

  @override
  Map<String, dynamic>? decodeTokenClaims(String token) => null;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getCurrentUserEmail() async => profile?.email;

  @override
  Future<String?> getCurrentUserFullName() async => fullName ?? profile?.displayName;

  @override
  Future<UserProfile?> getCurrentUserProfile() async => profile;

  @override
  Future<String> getOrCreateDeviceId() async => deviceId;

  @override
  Future<bool> isAuthenticated() async => isAuthenticatedValue;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
    String? verificationCode,
    String? challengeId,
  }) async {
    return loginResult;
  }

  @override
  Future<void> logout() async {
    isAuthenticatedValue = false;
    accessToken = null;
  }

  @override
  Future<bool> refreshSession() async => false;
}
