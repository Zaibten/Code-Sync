// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:badges/badges.dart';
import 'package:pictureai/constants/global_variables.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:badges/badges.dart' as badges;

import '../features/account/screens/account_screen.dart';
import '../features/home/screens/home_screen.dart';

class AdminBottomBar extends StatefulWidget {
  static const String routeName = 'actual-home';
  const AdminBottomBar({Key? key}) : super(key: key);

  @override
  State<AdminBottomBar> createState() => _AdminBottomBarState();
}

class _AdminBottomBarState extends State<AdminBottomBar> {
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
        icon: Icons.person_outline_outlined,
        text: 'Account',
      ),
      GButton(
        icon: Icons.shopping_cart_outlined,
        leading: badges.Badge(
          position: BadgePosition.topEnd(
            top: -20,
            end: -10,
          ),
          badgeContent: Text(
            cartItemCount.toString(),
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          badgeStyle: const BadgeStyle(
            badgeColor: Colors.pinkAccent,
            padding: EdgeInsets.all(5),
            elevation: 0,
          ),
          child: Icon(
            Icons.shopping_cart_outlined,
            color: page == 2 // Check if the cart tab is selected
                ? GlobalVariables.secondaryColor
                : Colors.grey[800],
          ),
        ),
        text: 'Cart',
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
          const AccountScreen(),
          const Text('This Is Cart Scrren'),
          //const CartScreen(),
        ],
      ),
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
          setState(() {
            page = index;
          });
        },
      ),
    );
  }
}
