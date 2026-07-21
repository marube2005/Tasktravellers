import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_cache_service.dart';

class EngagementService {
  EngagementService._internal();
  static final EngagementService _instance = EngagementService._internal();
  factory EngagementService() => _instance;

  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final OfflineCacheService _offlineCacheService = OfflineCacheService();

  String? get _currentUserId => _supabaseClient.auth.currentUser?.id;

  Stream<List<Map<String, dynamic>>> watchRideMessages(String rideId) {
    return _supabaseClient
        .from('ride_messages')
        .stream(primaryKey: ['id'])
        .eq('ride_id', rideId)
        .order('created_at', ascending: true);
  }

  Future<void> sendRideMessage({
    required String rideId,
    required String message,
  }) async {
    final senderId = _currentUserId;
    if (senderId == null) {
      throw Exception('Authentication required. User not logged in.');
    }
    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty.');
    }

    try {
      await _supabaseClient.from('ride_messages').insert({
        'ride_id': rideId,
        'sender_id': senderId,
        'message': message.trim(),
      });
    } catch (_) {
      await _offlineCacheService.queueAction({
        'type': 'ride_message',
        'ride_id': rideId,
        'sender_id': senderId,
        'message': message.trim(),
      });
      throw Exception('No connection. Message queued for sync.');
    }
  }

  Future<void> raiseEmergencyAlert({
    String? rideId,
    required String message,
    String? emergencyContactName,
    String? emergencyContactPhone,
    double? latitude,
    double? longitude,
    String? locationLabel,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Authentication required. User not logged in.');
    }

    try {
      await _supabaseClient.from('emergency_alerts').insert({
        'ride_id': rideId,
        'user_id': userId,
        'message': message,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'latitude': latitude,
        'longitude': longitude,
        'location_label': locationLabel,
        'status': 'sent',
      });
    } catch (_) {
      await _offlineCacheService.queueAction({
        'type': 'emergency_alert',
        'ride_id': rideId,
        'user_id': userId,
        'message': message,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'latitude': latitude,
        'longitude': longitude,
        'location_label': locationLabel,
      });
      throw Exception('No connection. Emergency alert queued for sync.');
    }
  }

  Future<void> syncQueuedActions() async {
    final queued = await _offlineCacheService.loadQueuedActions();
    if (queued.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];

    for (final action in queued) {
      try {
        switch (action['type']) {
          case 'ride_message':
            await _supabaseClient.from('ride_messages').insert({
              'ride_id': action['ride_id'],
              'sender_id': action['sender_id'],
              'message': action['message'],
            });
            break;
          case 'emergency_alert':
            await _supabaseClient.from('emergency_alerts').insert({
              'ride_id': action['ride_id'],
              'user_id': action['user_id'],
              'message': action['message'],
              'emergency_contact_name': action['emergency_contact_name'],
              'emergency_contact_phone': action['emergency_contact_phone'],
              'latitude': action['latitude'],
              'longitude': action['longitude'],
              'location_label': action['location_label'],
              'status': 'sent',
            });
            break;
          default:
            remaining.add(action);
        }
      } catch (_) {
        remaining.add(action);
      }
    }

    await _offlineCacheService.clearQueuedActions();
    for (final action in remaining) {
      await _offlineCacheService.queueAction(action);
    }
  }
}
