import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_ride.dart';
import '../services/supabase_service.dart';

class GroupRepository {
  final SupabaseClient _supabase = SupabaseService().client;
  
  /// Create a new group ride
  Future<GroupRide> createGroupRide(GroupRide groupRide) async {
    final response = await _supabase
        .from('group_rides')
        .insert(groupRide.toJson())
        .select()
        .single();
    
    return GroupRide.fromJson(response);
  }
  
  /// Get group ride by ID
  Future<GroupRide?> getGroupRide(String groupId) async {
    final response = await _supabase
        .from('group_rides')
        .select()
        .eq('id', groupId)
        .maybeSingle();
    
    if (response == null) return null;
    return GroupRide.fromJson(response);
  }
  
  /// Get all members of a group
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    final response = await _supabase
        .from('group_members')
        .select('*, user:users(id, name, phone)')
        .eq('group_id', groupId);
    
    return response;
  }
  
  /// Add a member to the group
  Future<void> addMember({
    required String groupId,
    required String userId,
    required String joinedVia, // 'invite_link', 'manual_sms', 'creator_add'
  }) async {
    // First check if group is still forming
    final group = await getGroupRide(groupId);
    if (group == null) throw Exception('Group not found');
    
    if (group.status != 'forming') {
      throw Exception('Cannot join – ride already in progress');
    }
    
    if (group.currentPassengers >= group.maxPassengers) {
      throw Exception('Group is full (max ${group.maxPassengers})');
    }
    
    // Check if user already in group
    final existing = await _supabase
        .from('group_members')
        .select()
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();
    
    if (existing != null) {
      throw Exception('User already in group');
    }
    
    // Add member
    await _supabase.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'joined_via': joinedVia,
      'confirmed': true,
      'joined_at': DateTime.now().toIso8601String(),
    });
    
    // Update current passenger count
    final newCount = group.currentPassengers + 1;
    await _supabase
        .from('group_rides')
        .update({'current_passengers': newCount})
        .eq('id', groupId);
    
    // Auto-notify drivers if reached minimum
    if (newCount >= group.minPassengers && group.status == 'forming') {
      await _supabase
          .from('group_rides')
          .update({'status': 'ready'})
          .eq('id', groupId);
    }
  }
  
  /// Add pending invite (manual number entry)
  Future<void> addPendingInvite({
    required String groupId,
    required String phoneNumber,
    required String invitedBy,
  }) async {
    await _supabase.from('pending_invites').insert({
      'group_id': groupId,
      'phone_number': phoneNumber,
      'invited_by': invitedBy,
      'sent_at': DateTime.now().toIso8601String(),
      'status': 'pending',
    });
  }
  
  /// Confirm pending invite (when user replies YES via SMS)
  Future<void> confirmPendingInvite({
    required String phoneNumber,
    required String groupId,
  }) async {
    // Find the pending invite
    final pending = await _supabase
        .from('pending_invites')
        .select()
        .eq('group_id', groupId)
        .eq('phone_number', phoneNumber)
        .eq('status', 'pending')
        .maybeSingle();
    
    if (pending != null) {
      await _supabase
          .from('pending_invites')
          .update({'status': 'confirmed', 'confirmed_at': DateTime.now().toIso8601String()})
          .eq('id', pending['id']);
      
      // Check if user exists, if not create placeholder
      final user = await _supabase
          .from('users')
          .select()
          .eq('phone', phoneNumber)
          .maybeSingle();
      
      String userId;
      if (user == null) {
        // Create temporary user (will complete profile later)
       final newUser = await _supabase.auth.signUp(
          phone: phoneNumber,
          password: DateTime.now().millisecondsSinceEpoch.toString(),
);
        userId = newUser.user!.id;
        await _supabase.from('users').insert({
          'id': userId,
          'phone': phoneNumber,
          'role': 'passenger',
          'name': 'Traveler',
        });
      } else {
        userId = user['id'];
      }
      
      // Add as member
      await addMember(
        groupId: groupId,
        userId: userId,
        joinedVia: 'manual_sms',
      );
    }
  }
  
  /// Get pending invites for a group
  Future<List<Map<String, dynamic>>> getPendingInvites(String groupId) async {
    final response = await _supabase
        .from('pending_invites')
        .select()
        .eq('group_id', groupId)
        .eq('status', 'pending')
        .order('sent_at', ascending: false);
    
    return response;
  }
  
  /// Notify drivers about the group (when min passengers reached)
  Future<void> notifyDrivers(String groupId) async {
    final group = await getGroupRide(groupId);
    if (group == null) throw Exception('Group not found');
    
    if (!group.isReadyToNotify) {
      throw Exception('Minimum ${group.minPassengers} passengers required');
    }
    
    // Update status to 'ready' (awaiting offers)
    await _supabase
        .from('group_rides')
        .update({'status': 'ready'})
        .eq('id', groupId);
    
    // Call edge function to notify nearby drivers
    await _supabase.functions.invoke('notify-drivers', body: {
      'group_id': groupId,
      'origin': group.origin,
      'destination': group.destination,
    });
  }
  
  /// Stream group updates (realtime)
  Stream<GroupRide> streamGroupRide(String groupId) {
    return _supabase
        .from('group_rides')
        .stream(primaryKey: ['id'])
        .eq('id', groupId)
        .map((event) => GroupRide.fromJson(event.first));
  }
  
  /// Stream group members updates
  Stream<List<Map<String, dynamic>>> streamGroupMembers(String groupId) {
    return _supabase
        .from('group_members')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .map((event) => event);
  }
}