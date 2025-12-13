// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:badges/badges.dart';
import 'package:pictureai/constants/global_variables.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:badges/badges.dart' as badges;

import '../features/account/screens/account_screen.dart';
import '../features/art/screens/art_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/setting/setting.dart';

class BottomBar extends StatefulWidget {
  static const String routeName = 'actual-home';
  const BottomBar({Key? key}) : super(key: key);

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int page = 0;
  int cartItemCount = 2; // Replace with the actual count of items in the cart

  late List<GButton> tabs;

  @override
  void initState() {
    super.initState();
    tabs = [
      const GButton(
        icon: Icons.home_outlined,
        text: 'Home',
      ),
      const GButton(
        icon: Icons.picture_in_picture_outlined,
        text: 'Save Code',
      ),
      GButton(
        icon: Icons.settings,
        text: 'Settings',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: page,
        children: [
          const HomeScreen(),
          const SavedCodesScreen(),
          const SettingsScreen(),
          //const CartScreen(),
        ],
      ),
      bottomNavigationBar: GNav(
        gap: 8,
        iconSize: 30,
        color: Colors.grey[800],
        backgroundColor: GlobalVariables.backgroundColor,
        rippleColor: Colors.grey,
        activeColor: GlobalVariables.whitecolor,
        tabBackgroundColor: Color.fromARGB(255, 99, 95, 96),
        haptic: true, // haptic feedback
        hoverColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        tabs: tabs,
        selectedIndex: page,
        onTabChange: (index) {
          setState(() {
            page = index;
          });
        },
      ),
    );
  }
}
