// main.dart

import 'package:pictureai/features/admin/screens/admin_screen.dart';
import 'package:pictureai/features/splash/screen/splash_screem.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'common/bottombar.dart';
import 'constants/global_variables.dart';
import 'features/art/screens/art_screen.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'providers/user_provider.dart';
import 'router.dart';

void main() {
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
    ),
  ], child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    authService.getUserData(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: GlobalVariables.Companyname,
      theme: ThemeData(
        fontFamily: 'poppins',
        scaffoldBackgroundColor: GlobalVariables.backgroundColor,
        colorScheme: const ColorScheme.light(
          primary: GlobalVariables.secondaryColor,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          iconTheme: IconThemeData(
            color: Colors.black,
          ),
        ),
        useMaterial3: true,
      ),
      onGenerateRoute: (settings) => generateRoute(settings),
      home: 
      Provider.of<UserProvider>(context).user.token.isNotEmpty &&
              Provider.of<UserProvider>(context).user.type == 'user'
          ? const BottomBar()
          : const SplashScreen(),

      // Provider.of<UserProvider>(context).user.token.isNotEmpty &&
      //         Provider.of<UserProvider>(context).user.type == 'user'
      //     ? const BottomBar()
      //     : const AuthScreen(),

      // home: Provider.of<UserProvider>(context).user.token.isNotEmpty
      // ? Provider.of<UserProvider>(context).user.type == 'user'
      //     ? const BottomBar()
      //     : const AdminScreen()
      // : const AuthScreen(),
    );
  }
}
