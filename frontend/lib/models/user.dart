class AppUser {
	const AppUser({
		required this.id,
		this.name,
		this.email,
		this.phone,
		this.role = 'passenger',
		this.isVerified = false,
		this.homeArea,
		this.preferredRoutes,
		this.emergencyContactName,
		this.emergencyContactPhone,
		this.avatarUrl,
	});

	final String id;
	final String? name;
	final String? email;
	final String? phone;
	final String role;
	final bool isVerified;
	final String? homeArea;
	final String? preferredRoutes;
	final String? emergencyContactName;
	final String? emergencyContactPhone;
	final String? avatarUrl;

	factory AppUser.fromMap(Map<String, dynamic> map) {
		return AppUser(
			id: map['id'] as String,
			name: map['name'] as String?,
			email: map['email'] as String?,
			phone: map['phone'] as String?,
			role: (map['role'] as String?) ?? 'passenger',
			isVerified: (map['is_verified'] as bool?) ?? false,
			homeArea: map['home_area'] as String?,
			preferredRoutes: map['preferred_routes'] as String?,
			emergencyContactName: map['emergency_contact_name'] as String?,
			emergencyContactPhone: map['emergency_contact_phone'] as String?,
			avatarUrl: map['avatar_url'] as String?,
		);
	}

	Map<String, dynamic> toMap() {
		return {
			'id': id,
			'name': name,
			'email': email,
			'phone': phone,
			'role': role,
			'is_verified': isVerified,
			'home_area': homeArea,
			'preferred_routes': preferredRoutes,
			'emergency_contact_name': emergencyContactName,
			'emergency_contact_phone': emergencyContactPhone,
			'avatar_url': avatarUrl,
		};
	}
}
