class OfflineCacheService {
  Future<void> saveRideDraft(Map<String, dynamic> draft) async {}

  Future<Map<String, dynamic>?> loadRideDraft() async => null;

  Future<void> clearRideDraft() async {}

  Future<void> queueAction(Map<String, dynamic> action) async {}

  Future<List<Map<String, dynamic>>> loadQueuedActions() async => [];

  Future<void> clearQueuedActions() async {}
}
