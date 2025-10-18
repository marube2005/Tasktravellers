/// Maps directly to the 'user_role' ENUM in the Supabase database.
enum UserRole {
  passenger,
  sacco,
  admin,
}

// Extension to easily convert the enum value to the string format used in the database.
extension UserRoleExtension on UserRole {
  String toShortString() {
    return toString().split('.').last;
  }
}

// Helper function to convert a database string back to the enum.
UserRole userRoleFromString(String role) {
  switch (role) {
    case 'passenger':
      return UserRole.passenger;
    case 'sacco':
      return UserRole.sacco;
    case 'admin':
      return UserRole.admin;
    default:
      throw ArgumentError('Invalid user role string: $role');
  }
}