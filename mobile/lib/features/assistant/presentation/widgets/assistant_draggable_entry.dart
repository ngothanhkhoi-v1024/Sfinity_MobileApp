import 'package:flutter/material.dart';

import '../../../../app.dart';
import 'assistant_context_hint.dart';
import 'assistant_fab.dart';

/// Draggable seal assistant entry (optional hint + FAB) overlay.
class AssistantDraggableEntry extends StatefulWidget {
  const AssistantDraggableEntry({
    super.key,
    required this.showHint,
    required this.onOpenChat,
    required this.onDismissHint,
    required this.bottomReserved,
  });

  final bool showHint;
  final VoidCallback onOpenChat;
  final VoidCallback onDismissHint;
  final double bottomReserved;

  static const _fabSize = 56.0;
  static const _edgePadding = 12.0;
  static const _dragSlop = 6.0;

  @override
  State<AssistantDraggableEntry> createState() => _AssistantDraggableEntryState();
}

class _AssistantDraggableEntryState extends State<AssistantDraggableEntry> {
  Offset? _position;
  bool _loadedPrefs = false;
  bool _didDrag = false;
  double _dragTotal = 0;

  @override
  void initState() {
    super.initState();
    _position = SfinityApp.assistantFabPositionManager.loadPosition();
    _loadedPrefs = true;
  }

  Offset _defaultPosition(Size area, double columnWidth, double columnHeight) {
    return Offset(
      area.width - AssistantDraggableEntry._edgePadding - columnWidth,
      area.height - widget.bottomReserved - columnHeight,
    );
  }

  Offset _clampPosition(Offset pos, Size area, double columnWidth, double columnHeight) {
    final topInset = MediaQuery.paddingOf(context).top;
    final minX = AssistantDraggableEntry._edgePadding;
    final maxX = area.width - columnWidth - AssistantDraggableEntry._edgePadding;
    final minY = topInset + AssistantDraggableEntry._edgePadding;
    final maxY = area.height - columnHeight - widget.bottomReserved;

    return Offset(
      pos.dx.clamp(minX, maxX > minX ? maxX : minX),
      pos.dy.clamp(minY, maxY > minY ? maxY : minY),
    );
  }

  void _onPanStart(DragStartDetails _) {
    _didDrag = false;
    _dragTotal = 0;
  }

  void _onPanUpdate(DragUpdateDetails details, Size area, double columnWidth, double columnHeight) {
    _dragTotal += details.delta.distance;
    if (_dragTotal > AssistantDraggableEntry._dragSlop) {
      _didDrag = true;
    }

    setState(() {
      final current = _position ?? _defaultPosition(area, columnWidth, columnHeight);
      _position = _clampPosition(current + details.delta, area, columnWidth, columnHeight);
    });
  }

  void _onPanEnd(Size area, double columnWidth, double columnHeight) {
    if (_didDrag) {
      final pos = _position ?? _defaultPosition(area, columnWidth, columnHeight);
      SfinityApp.assistantFabPositionManager.savePosition(pos);
    } else {
      widget.onOpenChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedPrefs) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final area = constraints.biggest;
        const hintMaxWidth = 240.0;
        final columnWidth = widget.showHint ? hintMaxWidth : AssistantDraggableEntry._fabSize;
        final columnHeight = (widget.showHint ? 120.0 : 0) + AssistantDraggableEntry._fabSize;
        final pos = _clampPosition(
          _position ?? _defaultPosition(area, columnWidth, columnHeight),
          area,
          columnWidth,
          columnHeight,
        );

        return Stack(
          children: [
            Positioned(
              left: pos.dx,
              top: pos.dy,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: (d) => _onPanUpdate(d, area, columnWidth, columnHeight),
                onPanEnd: (_) => _onPanEnd(area, columnWidth, columnHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.showHint)
                      AssistantContextHint(
                        onOpenChat: widget.onOpenChat,
                        onDismiss: widget.onDismissHint,
                      ),
                    AssistantFab(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
