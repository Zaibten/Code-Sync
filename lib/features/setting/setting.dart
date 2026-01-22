import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/global_variables.dart';
import '../../../providers/user_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/screens/auth_screen.dart';



class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {


Future<void> showProfileDialog(BuildContext context, String email) async {
  try {
    final response = await http.post(
      Uri.parse('https://code-sync-server-kappa.vercel.app/profile'), // Replace with your server IP/localhost
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final data = jsonDecode(response.body);

    if (data['success'] == true) {
      final user = data['user'];
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.black87,
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: GlobalVariables.btncolor,
                  child: const Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(user['name'],
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Text(user['email'],
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7))),
                
                const SizedBox(height: 6),
                Text("Type: ${user['type'] ?? 'N/A'}",
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalVariables.btncolor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                )
              ],
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['error'] ?? "Failed to fetch profile")),
      );
    }
  } catch (e) {
    print(e);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Server error")),
    );
  }
}


Future<void> showLogoutDialog(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout, size: 40, color: Colors.redAccent),
            const SizedBox(height: 15),
            const Text(
              "Logout",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "Are you sure you want to logout?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    // 1️⃣ Clear local storage
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();

                    // 2️⃣ Clear provider state
                    Provider.of<UserProvider>(context, listen: false)
                        .clearUser();

                    // 3️⃣ Navigate to AuthScreen & remove stack
                    Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => const AuthScreen()),
  (route) => false,
);

                  },
                  child: const Text("Yes, Logout"),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

 Future<void> showResetPasswordDialog(BuildContext context, String email) async {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  bool isLoading = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.black87,
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Reset Password",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "New Password",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Confirm Password",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator(color: GlobalVariables.btncolor)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: GlobalVariables.btncolor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: () async {
                            final newPass = passwordController.text.trim();
                            final confirmPass = confirmController.text.trim();
                            if (newPass.isEmpty || confirmPass.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please fill all fields")));
                              return;
                            }
                            if (newPass != confirmPass) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Passwords do not match")));
                              return;
                            }

                            setState(() => isLoading = true);

                            try {
                              final response = await http.post(
                                Uri.parse('https://code-sync-server-kappa.vercel.app/reset-password'),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({'email': email, 'newPassword': newPass}),
                              );

                              final data = jsonDecode(response.body);

                              if (data['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Password updated successfully")));
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(data['error'] ?? "Failed to update password")));
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Server error")));
                            } finally {
                              setState(() => isLoading = false);
                            }
                          },
                          child: const Text("Reset"),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    ),
  );
}
Future<void> showAboutAppDialog(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.black87,
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: GlobalVariables.btncolor,
              child: const Icon(Icons.code, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              "Code Sync App",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              "Version: 1.0.0",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            const Text(
              "Code Sync App helps you detect errors in your code and provides corrected code instantly. Improve your coding workflow and save time with AI-powered suggestions.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalVariables.btncolor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        ),
      ),
    ),
  );
}

 
 
  int _currentIndex = 3;

  void onTabTapped(int index) {
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/art');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/saved');
        break;
      case 3:
        break;
    }
  }

  // ================= SECTION TITLE =================
  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.5,
          color: Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ================= SETTINGS TILE =================
  Widget settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    (iconColor ?? GlobalVariables.btncolor).withOpacity(0.9),
                    (iconColor ?? GlobalVariables.btncolor).withOpacity(0.5),
                  ],
                ),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: Colors.black,

      // ================= HOME STYLE APP BAR =================
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF151F2B), Color(0xFF223447)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Column(
            children: [
              const Text(
                "Settings",
                style: TextStyle(
                  fontFamily: 'Poppins-Bold',
                  letterSpacing: 1.0,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              Text(
                "${user.name} • ${user.email}",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                child: IconButton(
                  icon: const Icon(Icons.settings_backup_restore,
                      color: Colors.white),
                  onPressed: () {
                    // optional refresh/reset logic
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      // ================= BODY =================
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ================= PROFILE CARD =================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  GlobalVariables.btncolor.withOpacity(0.25),
                  Colors.black,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        GlobalVariables.btncolor,
                        GlobalVariables.btncolor.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.person,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ================= ACCOUNT =================
          sectionTitle("Account"),

settingsTile(
  icon: Icons.person_outline,
  title: "Profile",
  subtitle: "Manage personal information",
  onTap: () {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    showProfileDialog(context, user.email);
  },
),


          const SizedBox(height: 12),
    settingsTile(
  icon: Icons.lock_outline,
  title: "Change Password",
  subtitle: "Update your account password",
  onTap: () {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    showResetPasswordDialog(context, user.email);
  },
),


          const SizedBox(height: 30),

          // ================= APPLICATION =================
          sectionTitle("Application"),

       settingsTile(
  icon: Icons.info_outline,
  title: "About App",
  subtitle: "Version, privacy & legal",
  onTap: () {
    showAboutAppDialog(context);
  },
),


          const SizedBox(height: 30),

          // ================= DANGER ZONE =================
          sectionTitle("Danger Zone"),

          settingsTile(
            icon: Icons.logout,
            iconColor: Colors.redAccent,
            title: "Logout",
            subtitle: "Sign out from this device",
            trailing:
                const Icon(Icons.exit_to_app, color: Colors.redAccent),
            onTap: () {
  showLogoutDialog(context);
},

          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
