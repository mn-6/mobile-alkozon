import 'package:alkozon/features/auth/data/models/user_profile_model.dart';
import 'package:alkozon/features/auth/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile.displayName', () {
    test('uses full name when first and last are present', () {
      const profile = UserProfile(
        id: 1,
        email: 'jan@alkozon.test',
        role: 'STAFF',
        firstName: 'Jan',
        lastName: 'Kowalski',
        courier: false,
        active: true,
      );

      expect(profile.displayName, 'Jan Kowalski');
    });

    test('falls back to email when name parts are empty', () {
      const profile = UserProfile(
        id: 2,
        email: 'staff@alkozon.test',
        role: 'STAFF',
        firstName: '  ',
        lastName: null,
        courier: false,
        active: true,
      );

      expect(profile.displayName, 'staff@alkozon.test');
    });
  });

  group('UserProfileModel.fromJson', () {
    test('maps API payload and applies defaults', () {
      final entity = UserProfileModel.fromJson({
        'id': 7,
        'email': 'kurierski@alkozon.test',
        'role': 'COURIER',
        'firstName': 'Adam',
        'lastName': 'Nowak',
        'courier': true,
        'active': true,
      }).toEntity();

      expect(entity.id, 7);
      expect(entity.email, 'kurierski@alkozon.test');
      expect(entity.role, 'COURIER');
      expect(entity.courier, isTrue);
      expect(entity.displayName, 'Adam Nowak');
    });

    test('fills missing fields with safe defaults', () {
      final entity = UserProfileModel.fromJson({}).toEntity();

      expect(entity.id, 0);
      expect(entity.email, '');
      expect(entity.role, '');
      expect(entity.courier, isFalse);
      expect(entity.active, isFalse);
      expect(entity.displayName, '');
    });
  });
}
