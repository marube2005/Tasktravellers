import 'dart:convert';
import 'dart:io';

class OfflineCacheService {
  static const String _fileName = 'tasktravellers_offline_cache.json';

  File get _cacheFile => File('${Directory.systemTemp.path}/$_fileName');

  Future<Map<String, dynamic>> _readStore() async {
    if (!await _cacheFile.exists()) {
      return {};
    }
    final raw = await _cacheFile.readAsString();
    if (raw.trim().isEmpty) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _writeStore(Map<String, dynamic> store) async {
    await _cacheFile.writeAsString(jsonEncode(store));
  }

  Future<void> saveRideDraft(Map<String, dynamic> draft) async {
    final store = await _readStore();
    store['ride_draft'] = draft;
    await _writeStore(store);
  }

  Future<Map<String, dynamic>?> loadRideDraft() async {
    final store = await _readStore();
    final draft = store['ride_draft'];
    return draft is Map<String, dynamic> ? draft : null;
  }

  Future<void> clearRideDraft() async {
    final store = await _readStore();
    store.remove('ride_draft');
    await _writeStore(store);
  }

  Future<void> queueAction(Map<String, dynamic> action) async {
    final store = await _readStore();
    final queued = (store['queued_actions'] as List<dynamic>?) ?? <dynamic>[];
    queued.add(action);
    store['queued_actions'] = queued;
    await _writeStore(store);
  }

  Future<List<Map<String, dynamic>>> loadQueuedActions() async {
    final store = await _readStore();
    final queued = (store['queued_actions'] as List<dynamic>?) ?? <dynamic>[];
    return queued.cast<Map<String, dynamic>>();
  }

  Future<void> clearQueuedActions() async {
    final store = await _readStore();
    store.remove('queued_actions');
    await _writeStore(store);
  }
}
