import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:pictureai/features/auth/screens/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import '../../../constants/global_variables.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int page = 0;
  int cartItemCount = 2; // Replace with the actual count of items in the cart

  late List<GButton> tabs;
  double bottomBarWidth = 42;
  double bottomBarBorderWidth = 5;

  @override
  void initState() {
    super.initState();
    tabs = [
      const GButton(
        icon: Icons.home_outlined,
        text: 'Posts',
      ),
      const GButton(
        icon: Icons.analytics_outlined,
        text: 'Analytics',
      ),
      const GButton(
        icon: Icons.all_inbox_outlined,
        text: 'Orders',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: GlobalVariables.appBarGradient,
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                alignment: Alignment.topLeft,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 45,
                  color: Colors.black,
                ),
              ),
              const Text(
                'Admin',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                // Added IconButton here
                onPressed: () {
                  logOut(context);
                },
                icon: Icon(Icons.outbond),
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
      //body: pages[page],
      bottomNavigationBar: GNav(
        gap: 8,
        iconSize: 30,
        color: Colors.grey[800],
        backgroundColor: Colors.white,
        rippleColor: Colors.grey,
        activeColor: GlobalVariables.secondaryColor,
        haptic: true, // haptic feedback
        hoverColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        tabs: tabs,
        selectedIndex: page,
        onTabChange: (index) {
          setState(
            () {
              page = index;
            },
          );
        },
      ),
    );
  }
}

void logOut(BuildContext context) async {
  try {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString('x-auth-token', '');
    Navigator.pushNamedAndRemoveUntil(
      context,
      AuthScreen.routeName,
      (route) => false,
    );
  } catch (e) {
    print(e);
  }
}
