// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors

import 'package:pictureai/constants/global_variables.dart';
import 'package:flutter/material.dart';
import '../widgets/below_app_bar.dart';
import '../widgets/orders.dart';
import '../widgets/top_buttons.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
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
              Container(
                padding: const EdgeInsets.only(left: 15, right: 15),
                child: const Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 15),
                      child: Icon(Icons.notifications_outlined),
                    ),
                    Icon(
                      Icons.search,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            BelowAppBar(),
            SizedBox(height: 20),
            TopButtons(),
            SizedBox(height: 30),
            Orders(),
          ],
        ),
      ),
    );
  }
}
