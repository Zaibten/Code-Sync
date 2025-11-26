// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:pictureai/constants/global_variables.dart';
import 'package:flutter/material.dart';

void ShowModal(BuildContext context, String text) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.shopping_cart_rounded,
              color: GlobalVariables.secondaryColor,
            ),
            SizedBox(width: 10),
            Text(
              GlobalVariables.Companyname,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (text),
            ),
            SizedBox(height: 10),
            Center(
              child: Image.asset(
                'assets/images/Chart-run-cycle.gif', // Replace with your image asset
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}

// Error Message Function
void showErrorDialog(BuildContext context, String errorMessage) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline_outlined,
              color: Colors.red,
            ),
            SizedBox(width: 10),
            Text(
              'Error',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Image.asset(
                'assets/images/Chart-run-cycle.gif', // Replace with your image asset
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}
