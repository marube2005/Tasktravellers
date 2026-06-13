import 'package:equatable/equatable.dart';

class GroupRide extends Equatable {
  final String? id;
  final String creatorId;
  final String origin;
  final String destination;
  final String scheduleType; // 'Now' or 'Later'
  final DateTime? scheduledTime;
  final int maxPassengers;
  final int minPassengers; // Fixed at 3 for MVP
  final int currentPassengers;
  final String status; // 'forming', 'ready', 'offered', 'confirmed', 'active', 'completed', 'cancelled'
  final String inviteCode;
  final DateTime createdAt;
  
  const GroupRide({
    this.id,
    required this.creatorId,
    required this.origin,
    required this.destination,
    required this.scheduleType,
    this.scheduledTime,
    required this.maxPassengers,
    this.minPassengers = 3,
    this.currentPassengers = 1,
    this.status = 'forming',
    required this.inviteCode,
    required this.createdAt,
  });
  
  factory GroupRide.fromJson(Map<String, dynamic> json) {
    return GroupRide(
      id: json['id'],
      creatorId: json['creator_id'],
      origin: json['origin'],
      destination: json['destination'],
      scheduleType: json['schedule_type'],
      scheduledTime: json['scheduled_time'] != null 
          ? DateTime.parse(json['scheduled_time']) 
          : null,
      maxPassengers: json['max_passengers'],
      minPassengers: json['min_passengers'] ?? 3,
      currentPassengers: json['current_passengers'] ?? 1,
      status: json['status'],
      inviteCode: json['invite_code'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'origin': origin,
      'destination': destination,
      'schedule_type': scheduleType,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'max_passengers': maxPassengers,
      'min_passengers': minPassengers,
      'current_passengers': currentPassengers,
      'status': status,
      'invite_code': inviteCode,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  bool get isReadyToNotify => currentPassengers >= minPassengers;
  bool get isForming => status == 'forming';
  
  @override
  List<Object?> get props => [id, creatorId, origin, destination, status];
}