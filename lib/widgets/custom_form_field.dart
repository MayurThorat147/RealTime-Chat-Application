import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CustomFormField extends StatelessWidget {
  final String hintText;
  final double height;
  final RegExp validationRegExp;
  final bool obscureText;
  final void Function(String?) onSaved;

  const CustomFormField({
    super.key,
    required this.hintText,
    required this.height,
    required this.validationRegExp,
    required this.onSaved,
    this.obscureText = false,
  });

  Icon? _getPrefixIcon() {
    if (hintText.toLowerCase().contains("email")) {
      return const Icon(
        Icons.email,
        color: Colors.red,
      );
    } else if (hintText.toLowerCase().contains("password")) {
      return const Icon(
        Icons.key,
        color: Colors.green,
      );
    } else if (hintText.toLowerCase().contains("name")) {
      return const Icon(
        Icons.person,
        color: Colors.blue,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextFormField(
        onSaved: onSaved,
        obscureText: obscureText,
        validator: (value) {
          if (value != null && validationRegExp.hasMatch(value)) {
            return null;
          }
          return "Enter a valid ${hintText.toLowerCase()}";
        },
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: _getPrefixIcon(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
      ),
    );
  }
}
