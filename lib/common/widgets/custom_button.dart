import 'package:pictureai/constants/global_variables.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const CustomButton({Key? key, required this.text, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: GlobalVariables.secondaryColor,
        foregroundColor: Colors.white,
        textStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
      child: Text(
        text,
      ),
    );
  }
}
