import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists draggable seal assistant FAB position and visibility.
class AssistantFabPositionManager extends ChangeNotifier {
  static const _xKey = 'assistant_fab_pos_x';
  static const _yKey = 'assistant_fab_pos_y';
  static const _visibleKey = 'assistant_fab_visible';
  static const edgePadding = 12.0;

  late SharedPreferences _prefs;
  bool _initialized = false;
  bool _visible = true;

  bool get visible => _visible;
  bool get initialized => _initialized;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _visible = _prefs.getBool(_visibleKey) ?? true;
    _initialized = true;
    notifyListeners();
  }

  Offset? loadPosition() {
    if (!_initialized) return null;
    if (!_prefs.containsKey(_xKey) || !_prefs.containsKey(_yKey)) {
      return null;
    }
    return Offset(_prefs.getDouble(_xKey)!, _prefs.getDouble(_yKey)!);
  }

  Future<void> savePosition(Offset position) async {
    if (!_initialized) return;
    await _prefs.setDouble(_xKey, position.dx);
    await _prefs.setDouble(_yKey, position.dy);
  }

  Future<void> setVisible(bool visible) async {
    if (_visible == visible) return;
    _visible = visible;
    if (_initialized) {
      await _prefs.setBool(_visibleKey, visible);
    }
    notifyListeners();
  }

  /// Snap FAB column to left or right edge based on horizontal center.
  Offset snapToSide({
    required Offset position,
    required double areaWidth,
    required double columnWidth,
  }) {
    final centerX = position.dx + columnWidth / 2;
    final snapX = centerX < areaWidth / 2
        ? edgePadding
        : areaWidth - columnWidth - edgePadding;
    return Offset(snapX, position.dy);
  }

  bool isOnLeftSide({
    required Offset position,
    required double areaWidth,
    required double columnWidth,
  }) {
    return position.dx + columnWidth / 2 < areaWidth / 2;
  }
}
