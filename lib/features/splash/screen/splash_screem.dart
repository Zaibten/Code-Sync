// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, camel_case_types

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:pictureai/constants/global_variables.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/bottombar.dart';
import '../../../providers/user_provider.dart';
import '../../auth/screens/auth_screen.dart';

class SplashScreen extends StatelessWidget {
  final bool isLoggedIn = true; // Replace with your login check logic

  const SplashScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: GlobalVariables.Companyname,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Center(
        child: AnimatedSplashScreen(
          splash: Image.asset(
            'assets/images/logobg.png',
            height: 300,
            width: 300,
            color: Colors.white,
          ),
          splashIconSize: 400,
          //duration: 40000000000000000,
          duration: 3000,
          splashTransition: SplashTransition.scaleTransition,
          backgroundColor: Colors.deepPurple.shade900,

          nextScreen: AuthScreen(),
          //nextScreen: HomeScreen(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
