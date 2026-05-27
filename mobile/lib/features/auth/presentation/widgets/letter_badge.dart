import 'package:flutter/material.dart';

class LetterBadge extends StatelessWidget {
  const LetterBadge({
    required this.letter,
    required this.background,
  });

  final String letter;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: background,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}