class UserProfile {
  const UserProfile({
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

  String get displayName {
    final first = (firstName ?? '').trim();
    final last = (lastName ?? '').trim();
    final combined = '$first $last'.trim();
    return combined.isEmpty ? email : combined;
  }
}
