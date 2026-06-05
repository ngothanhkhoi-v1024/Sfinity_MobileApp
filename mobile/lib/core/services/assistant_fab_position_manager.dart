import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists draggable seal assistant FAB position on screen.
class AssistantFabPositionManager {
  static const _xKey = 'assistant_fab_pos_x';
  static const _yKey = 'assistant_fab_pos_y';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Offset? loadPosition() {
    if (!_prefs.containsKey(_xKey) || !_prefs.containsKey(_yKey)) {
      return null;
    }
    return Offset(_prefs.getDouble(_xKey)!, _prefs.getDouble(_yKey)!);
  }

  Future<void> savePosition(Offset position) async {
    await _prefs.setDouble(_xKey, position.dx);
    await _prefs.setDouble(_yKey, position.dy);
  }
}
