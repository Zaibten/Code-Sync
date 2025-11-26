// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api, body_might_complete_normally_nullable

import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData customIcon;
  final bool
      isPasswordField; // Added parameter to determine if it's a password field

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.customIcon,
    this.isPasswordField = false, // Default value is false
  }) : super(key: key);

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPasswordField ? obscureText : false,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(widget.customIcon),
        suffixIcon: widget.isPasswordField
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    obscureText = !obscureText;
                  });
                },
                child: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                ),
              )
            : null, // Show eye icon only for password field
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.black38,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.black38,
          ),
        ),
      ),
      validator: (val) {},
    );
  }
}
