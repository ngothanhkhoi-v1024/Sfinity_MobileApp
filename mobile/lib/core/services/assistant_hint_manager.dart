import 'package:shared_preferences/shared_preferences.dart';

/// Tracks first-visit hints per screen context for the seal assistant.
class AssistantHintManager {
  static const _prefix = 'assistant_hint_seen_';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool hasSeenContext(String contextId) {
    return _prefs.getBool('$_prefix$contextId') ?? false;
  }

  Future<void> markContextSeen(String contextId) async {
    await _prefs.setBool('$_prefix$contextId', true);
  }
}
