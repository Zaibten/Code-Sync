// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'package:pictureai/common/bottombar.dart';
import 'package:pictureai/constants/error_handling.dart';
import 'package:pictureai/constants/global_variables.dart';
import 'package:pictureai/constants/utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/user.dart';
import '../../../providers/user_provider.dart';

class AuthService {
// Signup User
  void signUpUser({
    required BuildContext context,
    required String email,
    required String password,
    required String name,
    required String gender,
  }) async {
    try {
      User user = User(
        id: '',
        name: name,
        password: password,
        email: email,
        gender: gender,
        type: '',
        token: '',
        //cart: [],
      );

      http.Response res = await http.post(
        Uri.parse('$uri/api/signup'),
        body: user.toJson(),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      HttpErrorHandling(
        response: res,
        context: context,
        OnSuccess: () {
          ShowModal(
            context,
            'Account created sucessfully',
          );
        },
      );
    } catch (e) {
      showErrorDialog(context, e.toString());
    }
  }

  // Signin
  // sign in user
  void signInUser({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      http.Response res = await http.post(
        Uri.parse('$uri/api/signin'),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      HttpErrorHandling(
        response: res,
        context: context,
        OnSuccess: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          Provider.of<UserProvider>(context, listen: false).setUser(res.body);
          await prefs.setString('x-auth-token', jsonDecode(res.body)['token']);
          print('Success');
          Navigator.pushNamedAndRemoveUntil(
            context,
            BottomBar.routeName,
            (route) => false,
          );
        },
      );
    } catch (e) {
      showErrorDialog(context, e.toString());
    }
  }

  // get user data
  void getUserData(
    BuildContext context,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('x-auth-token');

      if (token == null) {
        prefs.setString('x-auth-token', '');
      }

      var tokenRes = await http.post(
        Uri.parse('$uri/tokenIsValid'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token!
        },
      );

      var response = jsonDecode(tokenRes.body);

      if (response == true) {
        http.Response userRes = await http.get(
          Uri.parse('$uri/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'x-auth-token': token
          },
        );

        var userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(userRes.body);
      }
    } catch (e) {
      showErrorDialog(context, e.toString());
    }
  }
}
