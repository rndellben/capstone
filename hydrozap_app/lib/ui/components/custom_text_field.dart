import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final String? prefixText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final TextInputType keyboardType;
  final bool filled;
  final Color? fillColor;
  final int? maxLines;
  final int? minLines;
  final TextCapitalization textCapitalization;
  final bool enableBorder;
  final bool readOnly;
  final String? helperText;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.keyboardType = TextInputType.text,
    this.filled = true,
    this.fillColor,
    this.maxLines = 1,
    this.minLines,
    this.textCapitalization = TextCapitalization.none,
    this.enableBorder = false,
    this.readOnly = false,
    this.helperText,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: widget.obscureText ? _obscureText : false,
          keyboardType: widget.keyboardType,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          textCapitalization: widget.textCapitalization,
          readOnly: widget.readOnly,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 14,
            ),
            helperText: widget.helperText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    size: 20,
                  )
                : null,
            prefixText: widget.prefixText,
            prefixStyle: widget.prefixText != null
                ? TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  )
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : widget.suffixIcon != null
                    ? IconButton(
                        icon: Icon(
                          widget.suffixIcon,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          size: 20,
                        ),
                        onPressed: widget.onSuffixIconPressed,
                      )
                    : null,
            filled: widget.filled,
            fillColor: widget.fillColor ?? Theme.of(context).colorScheme.surface,
            border: widget.enableBorder
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  )
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
            enabledBorder: widget.enableBorder
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  )
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}