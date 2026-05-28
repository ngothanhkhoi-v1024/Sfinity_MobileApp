import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.textInputAction = TextInputAction.done,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String labelText;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.labelText,
        prefixIcon: const Icon(Icons.key_rounded),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          icon: Icon(
            _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          ),
        ),
      ),
      validator: widget.validator,
    );
  }
}
