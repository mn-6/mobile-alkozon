import '../../domain/entities/user_profile.dart';

class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.courier,
    required this.active,
  });

  final int id;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;
  final bool courier;
  final bool active;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      courier: json['courier'] as bool? ?? false,
      active: json['active'] as bool? ?? false,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      email: email,
      role: role,
      firstName: firstName,
      lastName: lastName,
      courier: courier,
      active: active,
    );
  }
}
