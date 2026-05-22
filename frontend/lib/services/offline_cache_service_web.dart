import 'dart:convert';
import 'dart:html' as html;

class OfflineCacheService {
  static const String _rideDraftKey = 'ride_draft';
  static const String _queuedActionsKey = 'queued_actions';

  Future<void> saveRideDraft(Map<String, dynamic> draft) async {
    html.window.localStorage[_rideDraftKey] = jsonEncode(draft);
  }

  Future<Map<String, dynamic>?> loadRideDraft() async {
    final value = html.window.localStorage[_rideDraftKey];
    if (value == null || value.isEmpty) return null;
    return jsonDecode(value) as Map<String, dynamic>;
  }

  Future<void> clearRideDraft() async {
    html.window.localStorage.remove(_rideDraftKey);
  }

  Future<void> queueAction(Map<String, dynamic> action) async {
    final actions = await loadQueuedActions();
    actions.add(action);
    html.window.localStorage[_queuedActionsKey] = jsonEncode(actions);
  }

  Future<List<Map<String, dynamic>>> loadQueuedActions() async {
    final value = html.window.localStorage[_queuedActionsKey];
    if (value == null || value.isEmpty) return [];
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> clearQueuedActions() async {
    html.window.localStorage.remove(_queuedActionsKey);
  }
}
