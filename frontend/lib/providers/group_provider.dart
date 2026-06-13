import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_ride.dart';
import '../repositories/group_repository.dart';

final groupRepositoryProvider = Provider((ref) => GroupRepository());

final createGroupProvider = FutureProvider.family<GroupRide, GroupRide>(
  (ref, groupRide) async {
    final repo = ref.read(groupRepositoryProvider);
    return await repo.createGroupRide(groupRide);
  },
);

final groupRideProvider = FutureProvider.family<GroupRide?, String>(
  (ref, groupId) async {
    final repo = ref.read(groupRepositoryProvider);
    return await repo.getGroupRide(groupId);
  },
);

final groupMembersProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, groupId) async {
    final repo = ref.read(groupRepositoryProvider);
    return await repo.getGroupMembers(groupId);
  },
);

final pendingInvitesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, groupId) async {
    final repo = ref.read(groupRepositoryProvider);
    return await repo.getPendingInvites(groupId);
  },
);

final addMemberController = Provider((ref) {
  final repo = ref.read(groupRepositoryProvider);
  return (String groupId, String userId, String joinedVia) async {
    await repo.addMember(groupId: groupId, userId: userId, joinedVia: joinedVia);
  };
});

final notifyDriversController = Provider((ref) {
  final repo = ref.read(groupRepositoryProvider);
  return (String groupId) async {
    await repo.notifyDrivers(groupId);
  };
});

// Realtime stream providers
final groupRideStreamProvider = StreamProvider.family<GroupRide, String>(
  (ref, groupId) {
    final repo = ref.read(groupRepositoryProvider);
    return repo.streamGroupRide(groupId);
  },
);

final groupMembersStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, String>(
  (ref, groupId) {
    final repo = ref.read(groupRepositoryProvider);
    return repo.streamGroupMembers(groupId);
  },
);