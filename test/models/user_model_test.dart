import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/models/user.dart';

void main() {
  test('AppUser maps from/to Supabase payload', () {
    final map = <String, dynamic>{
      'id': 'user-1',
      'name': 'Valentino',
      'email': 'valentino@example.com',
      'phone': '0712345678',
      'role': 'passenger',
      'is_verified': true,
      'home_area': 'Nairobi',
      'preferred_routes': 'CBD -> Westlands',
      'emergency_contact_name': 'Jane',
      'emergency_contact_phone': '0700000000',
      'avatar_url': 'https://example.com/avatar.png',
    };

    final user = AppUser.fromMap(map);

    expect(user.id, 'user-1');
    expect(user.name, 'Valentino');
    expect(user.isVerified, true);

    final encoded = user.toMap();
    expect(encoded['role'], 'passenger');
    expect(encoded['emergency_contact_name'], 'Jane');
  });
}
