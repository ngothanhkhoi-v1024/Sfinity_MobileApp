import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: color,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
