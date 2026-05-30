import 'package:flutter/material.dart';

class PlacesMapZoomControls extends StatelessWidget {
  const PlacesMapZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF242424) : Colors.white;
    final border = isDark ? Colors.white12 : const Color(0xFFE5E7EB);

    return Material(
      color: bg,
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ZoomButton(icon: Icons.add, onPressed: onZoomIn),
            Container(height: 1, width: 36, color: border),
            _ZoomButton(icon: Icons.remove, onPressed: onZoomOut),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, size: 20),
      ),
    );
  }
}
