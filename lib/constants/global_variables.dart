import 'package:flutter/material.dart';

// String uri = 'http://192.168.100.37:9000';
String uri = 'https://code-sync-server-kappa.vercel.app';

class GlobalVariables {
  // COLORS
  static const appBarGradient = LinearGradient(
    colors: [
      Color.fromARGB(255, 228, 223, 225),
      Color.fromARGB(255, 170, 170, 170),
    ],
    stops: [0.5, 1.0],
  );

  static const secondaryColor = Color.fromRGBO(255, 153, 0, 1);
  //static const secondaryColor = Colors.white;
  static const backgroundColor = Color(0xff191919);
  static const btncolor = Color(0xff684fd8);
  static const whitecolor = Color.fromRGBO(255, 255, 255, 1);
  static const textcolor = Color.fromARGB(226, 59, 23, 44);
  static const Color greyBackgroundCOlor = Color(0xffebecee);
  static var selectedNavBarColor = Colors.cyan[800]!;
  static const unselectedNavBarColor = Colors.black87;
  static const Color greyTextColor = Color.fromARGB(255, 0, 0, 0);
  static const WelcomeText = ('Code Sync');
  static const Companyname = ('Code Sync');
  static const Developers = ('Code Sync Developments');

  // STATIC IMAGES
  static const List<String> carouselImages = [
    'assets/images/s1.png',
    'assets/images/s2.png',
    'assets/images/s3.png',
    'assets/images/s4.png',
    'assets/images/s5.png',
  ];
}
