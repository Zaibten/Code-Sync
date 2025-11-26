// ignore_for_file: avoid_print, non_constant_identifier_names

import 'package:pictureai/constants/global_variables.dart';
import 'package:pictureai/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../../constants/utils.dart';

class AuthScreen extends StatefulWidget {
  static const String routeName = '/auth_screen';

  const AuthScreen({super.key});
  @override
  _LoginSignupScreenState createState() => _LoginSignupScreenState();
}

enum Gender {
  male,
  female,
}

class _LoginSignupScreenState extends State<AuthScreen> {
  final AuthService authService = AuthService();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isSignupScreen = true;
  bool isMale = true;
  bool isRememberMe = false;
  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: Container(
              height: 300,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/background.jpg"),
                  fit: BoxFit.fill,
                ),
              ),
              child: Container(
                padding: EdgeInsets.only(top: 90, left: 20),
                color: Color(0xFF3b5999).withOpacity(.85),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: "Welcome",
                        style: TextStyle(
                          fontSize: 25,
                          letterSpacing: 2,
                          color: Colors.yellow[700],
                        ),
                        children: [
                          TextSpan(
                            text: isSignupScreen
                                ? ' To ${GlobalVariables.Companyname}'
                                : " Back,",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.yellow[700],
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      isSignupScreen
                          ? "Signup to Continue"
                          : "Signin to Continue",
                      style: TextStyle(
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          buildBottomHalfContainer(true),
          AnimatedPositioned(
            duration: Duration(milliseconds: 700),
            curve: Curves.bounceInOut,
            top: isSignupScreen ? 200 : 230,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 700),
              curve: Curves.bounceInOut,
              height: isSignupScreen ? 380 : 250,
              padding: EdgeInsets.all(20),
              width: MediaQuery.of(context).size.width - 40,
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isSignupScreen = false;
                            });
                          },
                          child: Column(
                            children: [
                              Text(
                                "LOGIN",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: !isSignupScreen
                                      ? Colors.orange
                                      : Colors.black,
                                ),
                              ),
                              if (!isSignupScreen)
                                Container(
                                  margin: EdgeInsets.only(top: 3),
                                  height: 2,
                                  width: 55,
                                  color: Colors.orange,
                                )
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isSignupScreen = true;
                            });
                          },
                          child: Column(
                            children: [
                              Text(
                                "SIGNUP",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSignupScreen
                                      ? Colors.orange
                                      : Colors.black,
                                ),
                              ),
                              if (isSignupScreen)
                                Container(
                                  margin: EdgeInsets.only(top: 3),
                                  height: 2,
                                  width: 55,
                                  color: Colors.orange,
                                )
                            ],
                          ),
                        )
                      ],
                    ),
                    if (isSignupScreen) buildSignupSection(),
                    if (!isSignupScreen) buildSigninSection()
                  ],
                ),
              ),
            ),
          ),
          buildBottomHalfContainer(false),
          Positioned(
            top: MediaQuery.of(context).size.height - 100,
            right: 0,
            left: 0,
            child: Column(
              children: [
                Text(isSignupScreen ? "Or Signup with" : "Or Signin with"),
                Container(
                  margin: EdgeInsets.only(right: 20, left: 20, top: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildTextButton(Icons.facebook, "Facebook", Colors.blue),
                      buildTextButton(Icons.mail, "Google", Colors.red),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Container buildSigninSection() {
    return Container(
      margin: EdgeInsets.only(top: 20),
      child: Column(
        children: [
          buildTextField(
            Icons.mail_outline,
            "info@pictureai.com",
            false,
            true,
            emailController,
          ),
          buildPasswordField(
              Icons.lock_outline, "**********", passwordController),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isRememberMe,
                    activeColor: Colors.orange,
                    onChanged: (value) {
                      setState(() {
                        isRememberMe = !isRememberMe;
                      });
                    },
                  ),
                  Text(
                    "Remember me",
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  )
                ],
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(fontSize: 12, color: Colors.black),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Container buildSignupSection() {
    return Container(
      margin: EdgeInsets.only(top: 20),
      child: Column(
        children: [
          buildTextField(
            Icons.person,
            "User Name",
            false,
            false,
            userNameController,
          ),
          buildTextField(
            Icons.mail_outline,
            "email",
            false,
            true,
            emailController,
          ),
          buildPasswordField(
              Icons.lock_outline, "password", passwordController),
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isMale = true;
                      printSelectedGender(Gender.male);
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isMale ? Colors.orange : Colors.transparent,
                          border: Border.all(
                            width: 1,
                            color: isMale ? Colors.transparent : Colors.black,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.man,
                          color: isMale ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        "Male",
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 30,
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isMale = false;
                      printSelectedGender(Gender.female);
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isMale ? Colors.transparent : Colors.orange,
                          border: Border.all(
                            width: 1,
                            color: isMale ? Colors.black : Colors.transparent,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.woman,
                          color: isMale ? Colors.black : Colors.white,
                        ),
                      ),
                      Text(
                        "Female",
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 200,
            margin: EdgeInsets.only(top: 20),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: "By pressing 'Submit' you agree to our ",
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: "terms & conditions",
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextButton buildTextButton(
      IconData icon, String title, Color backgroundColor) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: Colors.white, side: BorderSide(width: 1, color: Colors.grey),
        minimumSize: Size(145, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: backgroundColor,
      ),
      child: Row(
        children: [
          Icon(
            icon,
          ),
          SizedBox(
            width: 5,
          ),
          Text(
            title,
          ),
        ],
      ),
    );
  }

  Widget buildBottomHalfContainer(bool showShadow) {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 700),
      curve: Curves.bounceInOut,
      top: isSignupScreen ? 535 : 430,
      right: 0,
      left: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            isSignupScreen ? signupAction(context) : loginAction(context);
          },
          child: Container(
            height: 90,
            width: 90,
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                if (showShadow)
                  BoxShadow(
                    color: Colors.black.withOpacity(.3),
                    spreadRadius: 1.5,
                    blurRadius: 10,
                  )
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange[200]!,
                    Colors.red[400]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.3),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  )
                ],
              ),
              child: Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(IconData icon, String hintText, bool isPassword,
      bool isEmail, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Colors.grey[400], // Icon color
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                )
              : null,
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey), // Border color
            borderRadius: BorderRadius.all(Radius.circular(35.0)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey), // Border color
            borderRadius: BorderRadius.all(Radius.circular(35.0)),
          ),
          contentPadding: EdgeInsets.all(10),
          hintText: hintText,
          hintStyle:
              TextStyle(fontSize: 14, color: Colors.grey[400]), // Text color
        ),
      ),
    );
  }

  Widget buildPasswordField(
      IconData icon, String hintText, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        obscureText: !isPasswordVisible,
        keyboardType: TextInputType.visiblePassword,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Colors.grey[400], // Icon color
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                isPasswordVisible = !isPasswordVisible;
              });
            },
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey), // Border color
            borderRadius: BorderRadius.all(Radius.circular(35.0)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey), // Border color
            borderRadius: BorderRadius.all(Radius.circular(35.0)),
          ),
          contentPadding: const EdgeInsets.all(10),
          hintText: hintText,
          hintStyle:
              TextStyle(fontSize: 14, color: Colors.grey[400]), // Text color
        ),
      ),
    );
  }

  void printSelectedGender(Gender selectedGender) {
    String genderString = selectedGender == Gender.male ? "Male" : "Female";
    print('Selected Gender: $genderString');
  }

// SignupUser
  void SighupUser(Gender selectedGender) {
    authService.signUpUser(
      context: context,
      email: emailController.text,
      name: userNameController.text,
      password: passwordController.text,
      gender: selectedGender == Gender.male ? 'male' : 'female',
    );
  }

  void signInUser() {
    authService.signInUser(
      context: context,
      email: emailController.text,
      password: passwordController.text,
    );
  }

  void loginAction(BuildContext context) {
    // Check if login fields are filled
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      // Show error dialog for login
      showErrorDialog(context, 'Please fill all login fields.');
    } else {
      // Login logic
      // Signin Function
      signInUser();

      print('Email: ${emailController.text}');
      print('Password: ${passwordController.text}');
    }
  }

  void signupAction(BuildContext context) {
    // Check if signup fields are filled
    if (userNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      // Show error dialog for signup
      showErrorDialog(context, 'Please fill all signup fields.');
    } else if (!isNameValid(userNameController.text)) {
      // Show error dialog for invalid name format
      showErrorDialog(context,
          'Invalid name format. Remove numbers or special characters.');
    } else if (passwordController.text.length < 8) {
      // Show error dialog for short password
      showErrorDialog(context, 'Password must be at least 8 characters.');
    } else if (!isEmailValid(emailController.text)) {
      // Show error dialog for invalid email format
      showErrorDialog(context, 'Invalid email format.');
    } else {
      // Signup logic
      print('Username: ${userNameController.text}');
      print('Email: ${emailController.text}');
      print('Password: ${passwordController.text}');
      printSelectedGender(isMale ? Gender.male : Gender.female);

      // Signup Function
      SighupUser(isMale ? Gender.male : Gender.female);
    }
  }

  bool isNameValid(String name) {
    // Simple name validation check (no numbers or special characters)
    return RegExp(r'^[a-zA-Z\s]+$').hasMatch(name);
  }

  bool isEmailValid(String email) {
    // Simple email validation check
    return RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
        .hasMatch(email);
  }
}
