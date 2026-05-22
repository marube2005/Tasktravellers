class Ride {
  Ride({
    required this.id,
    required this.origin,
    required this.destination,
    required this.groupSize,
    required this.status,
    this.estimatedFare,
    this.inviteLink,
    this.acceptanceCode,
    this.groupNote,
    this.creatorId,
    this.providerId,
    this.vehicleId,
  });

  final String id;
  final String origin;
  final String destination;
  final int groupSize;
  final String status;
  final double? estimatedFare;
  final String? inviteLink;
  final String? acceptanceCode;
  final String? groupNote;
  final String? creatorId;
  final String? providerId;
  final String? vehicleId;

  factory Ride.fromMap(Map<String, dynamic> map) {
    return Ride(
      id: map['id'] as String,
      origin: map['origin'] as String? ?? '',
      destination: map['destination'] as String? ?? '',
      groupSize: (map['group_size'] as int?) ?? 1,
      status: map['status'] as String? ?? 'open',
      estimatedFare: (map['estimated_fare'] as num?)?.toDouble(),
      inviteLink: map['invite_link'] as String?,
      acceptanceCode: map['acceptance_code'] as String?,
      groupNote: map['group_note'] as String?,
      creatorId: map['creator_id'] as String?,
      providerId: map['provider_id'] as String?,
      vehicleId: map['vehicle_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'origin': origin,
      'destination': destination,
      'group_size': groupSize,
      'status': status,
      'estimated_fare': estimatedFare,
      'invite_link': inviteLink,
      'acceptance_code': acceptanceCode,
      'group_note': groupNote,
      'creator_id': creatorId,
      'provider_id': providerId,
      'vehicle_id': vehicleId,
    };
  }
}
