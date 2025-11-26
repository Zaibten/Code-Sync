// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'utils.dart';

void HttpErrorHandling({
  required http.Response response,
  required BuildContext context,
  required VoidCallback OnSuccess,
}) {
  switch (response.statusCode) {
    case 200:
      OnSuccess();
      break;
    case 400:
      showErrorDialog(context, jsonDecode(response.body)['msg']);
      break;

    case 500:
      showErrorDialog(context, jsonDecode(response.body)['error']);
      break;
    default:
      showErrorDialog(context, (response.body));
  }
}
