import 'package:flutter/material.dart';

import '../../../../app.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/services/assistant_fab_position_manager.dart';
import '../../../../core/theme/app_colors.dart';
import 'assistant_context_hint.dart';
import 'assistant_fab.dart';

/// Draggable seal assistant entry (optional hint + FAB) overlay.
class AssistantDraggableEntry extends StatefulWidget {
  const AssistantDraggableEntry({
    super.key,
    required this.showHint,
    required this.onOpenChat,
    required this.onDismissHint,
    required this.onHideFab,
    required this.bottomReserved,
  });

  final bool showHint;
  final VoidCallback onOpenChat;
  final VoidCallback onDismissHint;
  final VoidCallback onHideFab;
  final double bottomReserved;

  static const fabSize = 56.0;
  static const dragSlop = 6.0;
  static const trashZoneSize = 68.0;

  @override
  State<AssistantDraggableEntry> createState() => _AssistantDraggableEntryState();
}

class _AssistantDraggableEntryState extends State<AssistantDraggableEntry> {
  final _manager = SfinityApp.assistantFabPositionManager;

  Offset? _position;
  bool _loadedPrefs = false;
  bool _didDrag = false;
  bool _isDragging = false;
  bool _overTrash = false;
  double _dragTotal = 0;
  bool _dragHadHint = false;
  double _dragColumnWidth = AssistantDraggableEntry.fabSize;

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onManagerChanged);
    _reloadFromManager();
  }

  @override
  void dispose() {
    _manager.removeListener(_onManagerChanged);
    super.dispose();
  }

  void _onManagerChanged() {
    if (_manager.initialized && !_loadedPrefs) {
      _reloadFromManager();
    }
  }

  void _reloadFromManager() {
    final saved = _manager.loadPosition();
    if (saved != null || _manager.initialized) {
      setState(() {
        _position = saved;
        _loadedPrefs = _manager.initialized;
      });
    }
  }

  Offset _defaultPosition(Size area, double columnWidth, double columnHeight) {
    return Offset(
      area.width - AssistantFabPositionManager.edgePadding - columnWidth,
      area.height - widget.bottomReserved - columnHeight,
    );
  }

  Offset _trashZoneCenter(Size area) {
    return Offset(
      area.width / 2,
      area.height - widget.bottomReserved - AssistantDraggableEntry.trashZoneSize / 2 - 12,
    );
  }

  Rect _trashZoneRect(Size area) {
    final center = _trashZoneCenter(area);
    const half = AssistantDraggableEntry.trashZoneSize / 2;
    return Rect.fromCenter(center: center, width: half * 2, height: half * 2);
  }

  Offset _fabCenter(
    Offset pos,
    double columnWidth, {
    required bool onLeft,
    required bool showHint,
  }) {
    final fabLeft = onLeft
        ? pos.dx
        : pos.dx + columnWidth - AssistantDraggableEntry.fabSize;
    final fabTop = pos.dy + (showHint ? 120.0 : 0);
    return Offset(
      fabLeft + AssistantDraggableEntry.fabSize / 2,
      fabTop + AssistantDraggableEntry.fabSize / 2,
    );
  }

  bool _isFabOverTrash(
    Offset pos,
    Size area,
    double columnWidth, {
    required bool onLeft,
    required bool showHint,
  }) {
    final fabCenter = _fabCenter(pos, columnWidth, onLeft: onLeft, showHint: showHint);
    final trashCenter = _trashZoneCenter(area);
    const hitRadius =
        AssistantDraggableEntry.trashZoneSize / 2 + AssistantDraggableEntry.fabSize / 2 - 6;
    return (fabCenter - trashCenter).distance <= hitRadius;
  }

  Offset _clampPosition(
    Offset pos,
    Size area,
    double columnWidth,
    double columnHeight, {
    bool dragging = false,
  }) {
    final topInset = MediaQuery.paddingOf(context).top;
    final minX = dragging ? 0.0 : AssistantFabPositionManager.edgePadding;
    final maxX = dragging
        ? area.width - columnWidth
        : area.width - columnWidth - AssistantFabPositionManager.edgePadding;
    final minY = topInset + AssistantFabPositionManager.edgePadding;
    final maxY = dragging
        ? area.height - AssistantDraggableEntry.fabSize / 2 - 8
        : area.height - columnHeight - widget.bottomReserved;

    return Offset(
      pos.dx.clamp(minX, maxX > minX ? maxX : minX),
      pos.dy.clamp(minY, maxY > minY ? maxY : minY),
    );
  }

  void _onPanStart(DragStartDetails _) {
    _didDrag = false;
    _dragTotal = 0;
    _dragHadHint = widget.showHint;
    _dragColumnWidth = widget.showHint ? 240.0 : AssistantDraggableEntry.fabSize;
    setState(() {
      _isDragging = true;
      _overTrash = false;
    });
  }

  void _onPanUpdate(
    DragUpdateDetails details,
    Size area,
    double columnWidth,
    double columnHeight, {
    required bool onLeft,
    required bool showHint,
  }) {
    _dragTotal += details.delta.distance;
    if (_dragTotal > AssistantDraggableEntry.dragSlop) {
      _didDrag = true;
    }

    setState(() {
      final current = _position ?? _defaultPosition(area, columnWidth, columnHeight);
      final next = _clampPosition(
        current + details.delta,
        area,
        columnWidth,
        columnHeight,
        dragging: true,
      );
      _position = next;
      _overTrash = _isFabOverTrash(
        next,
        area,
        columnWidth,
        onLeft: onLeft,
        showHint: showHint,
      );
    });
  }

  void _onPanEnd(
    Size area,
    double columnWidth,
    double columnHeight, {
    required bool onLeft,
    required bool showHint,
  }) {
    if (_didDrag) {
      final raw = _position ?? _defaultPosition(area, columnWidth, columnHeight);
      if (_isFabOverTrash(raw, area, columnWidth, onLeft: onLeft, showHint: showHint)) {
        setState(() {
          _isDragging = false;
          _overTrash = false;
        });
        widget.onHideFab();
        return;
      }

      final snapped = _manager.snapToSide(
        position: raw,
        areaWidth: area.width,
        columnWidth: columnWidth,
      );
      final clamped = _clampPosition(snapped, area, columnWidth, columnHeight);
      setState(() {
        _position = clamped;
        _isDragging = false;
        _overTrash = false;
      });
      _manager.savePosition(clamped);
    } else {
      setState(() {
        _isDragging = false;
        _overTrash = false;
      });
      widget.onOpenChat();
    }
  }

  void _onPanCancel() {
    setState(() {
      _isDragging = false;
      _overTrash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedPrefs) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final area = constraints.biggest;
        const hintMaxWidth = 240.0;
        final layoutShowHint = _isDragging ? _dragHadHint : widget.showHint;
        final columnWidth =
            _isDragging ? _dragColumnWidth : (widget.showHint ? hintMaxWidth : AssistantDraggableEntry.fabSize);
        final columnHeight =
            (layoutShowHint ? 120.0 : 0) + AssistantDraggableEntry.fabSize;
        final rawPos = _position ?? _defaultPosition(area, columnWidth, columnHeight);
        final displayPos = _isDragging
            ? rawPos
            : _clampPosition(
                _manager.snapToSide(
                  position: rawPos,
                  areaWidth: area.width,
                  columnWidth: columnWidth,
                ),
                area,
                columnWidth,
                columnHeight,
              );
        final onLeft = _manager.isOnLeftSide(
          position: displayPos,
          areaWidth: area.width,
          columnWidth: columnWidth,
        );
        final trashRect = _trashZoneRect(area);
        final visualShowHint = widget.showHint && !_isDragging;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (_isDragging)
              Positioned(
                left: trashRect.left,
                top: trashRect.top - 18,
                child: IgnorePointer(
                  child: _AssistantTrashZone(
                    active: _overTrash,
                    label: context.l10n.assistantDropToHide,
                  ),
                ),
              ),
            Positioned(
              left: displayPos.dx,
              top: displayPos.dy,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    onLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  if (visualShowHint)
                    AssistantContextHint(
                      onOpenChat: widget.onOpenChat,
                      onDismiss: widget.onDismissHint,
                    ),
                  GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: (d) => _onPanUpdate(
                      d,
                      area,
                      columnWidth,
                      columnHeight,
                      onLeft: onLeft,
                      showHint: layoutShowHint,
                    ),
                    onPanEnd: (_) => _onPanEnd(
                      area,
                      columnWidth,
                      columnHeight,
                      onLeft: onLeft,
                      showHint: layoutShowHint,
                    ),
                    onPanCancel: _onPanCancel,
                    child: const AssistantFab(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AssistantTrashZone extends StatelessWidget {
  const _AssistantTrashZone({
    required this.active,
    required this.label,
  });

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final error = cs.error;

    return AnimatedScale(
      scale: active ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: AssistantDraggableEntry.trashZoneSize,
            height: AssistantDraggableEntry.trashZoneSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? error.withValues(alpha: 0.18)
                  : cs.surface.withValues(alpha: 0.92),
              border: Border.all(
                color: active ? error : AppColors.muted(context).withValues(alpha: 0.55),
                width: active ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.close_rounded,
              size: active ? 32 : 28,
              color: active ? error : AppColors.muted(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? error : AppColors.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}
