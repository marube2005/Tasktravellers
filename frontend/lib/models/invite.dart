class PendingInvite {
  final String phoneNumber;
  final DateTime sentAt;
  final bool isConfirmed;
  final String? userName;
  
  PendingInvite({
    required this.phoneNumber,
    required this.sentAt,
    this.isConfirmed = false,
    this.userName,
  });
  
  factory PendingInvite.fromJson(Map<String, dynamic> json) {
    return PendingInvite(
      phoneNumber: json['phone_number'],
      sentAt: DateTime.parse(json['sent_at']),
      isConfirmed: json['is_confirmed'] ?? false,
      userName: json['user_name'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'sent_at': sentAt.toIso8601String(),
      'is_confirmed': isConfirmed,
      'user_name': userName,
    };
  }
}