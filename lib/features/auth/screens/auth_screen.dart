// ignore_for_file: avoid_print, non_constant_identifier_names

import 'dart:ui';
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

class _LoginSignupScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  final AuthService authService = AuthService();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode userNameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  bool isSignupScreen = true;
  bool isMale = true;
  bool isRememberMe = false;
  bool isPasswordVisible = false;
  bool _isSubmitting = false;

  // ---------------- Animation controllers ----------------
  late final AnimationController _bgController;
  late final AnimationController _entryController;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _entryFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    );

    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));

    for (final node in [userNameFocus, emailFocus, passwordFocus]) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entryController.dispose();
    userNameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  static const Color _navyDeep = Color(0xFF0B1220);
  static const Color _navyMid = Color(0xFF16213E);
  static const Color _accentOrange = Color(0xFFFF8A3D);
  static const Color _accentPink = Color(0xFFEB4D8B);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _navyDeep,
      body: Stack(
        children: [
          // Animated gradient + floating blob backdrop (replaces static image)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) => CustomPaint(
                painter: _BlobBackgroundPainter(_bgController.value),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Header
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: SafeArea(
              child: FadeTransition(
                opacity: _entryFade,
                child: SlideTransition(
                  position: _entrySlide,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 36, left: 24, right: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_accentOrange, _accentPink],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _accentOrange.withOpacity(0.4),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.bolt_rounded,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              GlobalVariables.Companyname,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.25),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            isSignupScreen ? 'Create account' : 'Welcome back',
                            key: ValueKey(isSignupScreen),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isSignupScreen
                              ? 'Sign up to start syncing your code'
                              : 'Sign in to continue where you left off',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Card
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _entryFade,
              child: SlideTransition(
                position: _entrySlide,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                  constraints: BoxConstraints(maxHeight: size.height * 0.72),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 30,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTabSwitcher(),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 380),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SizeTransition(
                              sizeFactor: anim,
                              axisAlignment: -1,
                              child: child,
                            ),
                          ),
                          child: isSignupScreen
                              ? buildSignupSection()
                              : buildSigninSection(),
                        ),
                        const SizedBox(height: 22),
                        _buildSubmitButton(),
                        const SizedBox(height: 22),
                        _buildDivider(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildTextButton(
                                Icons.facebook, 'Facebook', const Color(0xFF3B5999)),
                            buildTextButton(
                                Icons.mail, 'Google', const Color(0xFFDB4437)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Tab switcher with sliding indicator ----------------
  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment:
                !isSignupScreen ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 42,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accentOrange, _accentPink],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _accentOrange.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _tabLabel('LOGIN', !isSignupScreen, () {
                  setState(() => isSignupScreen = false);
                }),
              ),
              Expanded(
                child: _tabLabel('SIGNUP', isSignupScreen, () {
                  setState(() => isSignupScreen = true);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabLabel(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 42,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: active ? Colors.white : const Color(0xFF8A8D98),
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            isSignupScreen ? 'Or Signup with' : 'Or Signin with',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return _PressableScale(
      onTap: _isSubmitting
          ? null
          : () {
              isSignupScreen ? signupAction(context) : loginAction(context);
            },
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_accentOrange, _accentPink],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _accentOrange.withOpacity(0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isSubmitting
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSignupScreen ? 'Create account' : 'Sign in',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  Widget buildSigninSection() {
    return Column(
      key: const ValueKey('signin'),
      children: [
        buildTextField(
          Icons.mail_outline,
          'info@codesync.com',
          false,
          true,
          emailController,
          emailFocus,
        ),
        buildPasswordField(
            Icons.lock_outline, '**********', passwordController, passwordFocus),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _AnimatedCheckbox(
                  value: isRememberMe,
                  onChanged: () => setState(() => isRememberMe = !isRememberMe),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Remember me',
                  style: TextStyle(fontSize: 12.5, color: Colors.black87),
                )
              ],
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Forgot Password?',
                style: TextStyle(fontSize: 12.5, color: Colors.black87),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget buildSignupSection() {
    return Column(
      key: const ValueKey('signup'),
      children: [
        buildTextField(
          Icons.person_outline,
          'User Name',
          false,
          false,
          userNameController,
          userNameFocus,
        ),
        buildTextField(
          Icons.mail_outline,
          'email',
          false,
          true,
          emailController,
          emailFocus,
        ),
        buildPasswordField(
            Icons.lock_outline, 'password', passwordController, passwordFocus),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          child: Row(
            children: [
              _genderOption(
                icon: Icons.man,
                label: 'Male',
                selected: isMale,
                onTap: () {
                  setState(() {
                    isMale = true;
                    printSelectedGender(Gender.male);
                  });
                },
              ),
              const SizedBox(width: 20),
              _genderOption(
                icon: Icons.woman,
                label: 'Female',
                selected: !isMale,
                onTap: () {
                  setState(() {
                    isMale = false;
                    printSelectedGender(Gender.female);
                  });
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: "By pressing 'Submit' you agree to our ",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              children: const [
                TextSpan(
                  text: 'terms & conditions',
                  style: TextStyle(
                      color: _accentOrange, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderOption({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [_accentOrange, _accentPink])
              : null,
          color: selected ? null : const Color(0xFFF3F4F7),
          borderRadius: BorderRadius.circular(30),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _accentOrange.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : Colors.black54),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextButton(IconData icon, String title, Color backgroundColor) {
    return _PressableScale(
      onTap: () {},
      child: Container(
        width: 150,
        height: 46,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(
    IconData icon,
    String hintText,
    bool isPassword,
    bool isEmail,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    final focused = focusNode.hasFocus;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: focused ? _accentOrange : const Color(0xFFE3E4E9),
            width: focused ? 1.6 : 1,
          ),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: _accentOrange.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: isPassword && !isPasswordVisible,
          keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon,
                color: focused ? _accentOrange : Colors.grey[400], size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.black45,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            hintText: hintText,
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }

  Widget buildPasswordField(
    IconData icon,
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    final focused = focusNode.hasFocus;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: focused ? _accentOrange : const Color(0xFFE3E4E9),
            width: focused ? 1.6 : 1,
          ),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: _accentOrange.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: !isPasswordVisible,
          keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            prefixIcon: Icon(icon,
                color: focused ? _accentOrange : Colors.grey[400], size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.black45,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  isPasswordVisible = !isPasswordVisible;
                });
              },
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            hintText: hintText,
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }

  void printSelectedGender(Gender selectedGender) {
    String genderString = selectedGender == Gender.male ? 'Male' : 'Female';
    print('Selected Gender: $genderString');
  }

  // SignupUser
  void SighupUser(Gender selectedGender) async {
    setState(() => _isSubmitting = true);
    try {
      authService.signUpUser(
        context: context,
        email: emailController.text,
        name: userNameController.text,
        password: passwordController.text,
        gender: selectedGender == Gender.male ? 'male' : 'female',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void signInUser() async {
    setState(() => _isSubmitting = true);
    try {
      authService.signInUser(
        context: context,
        email: emailController.text,
        password: passwordController.text,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

/// Paints a soft, slowly-drifting gradient blob backdrop — a lightweight,
/// dependency-free replacement for a static background image.
class _BlobBackgroundPainter extends CustomPainter {
  final double t; // 0..1 animation progress
  _BlobBackgroundPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final basePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0B1220), Color(0xFF16213E), Color(0xFF0B1220)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    void blob(Offset center, double radius, Color color) {
      final paint = Paint()
        ..color = color.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(center, radius, paint);
    }

    final angle = t * 6.28318;
    blob(
      Offset(size.width * 0.2 + 30 * (0.5 + 0.5 * (angle % 2)),
          size.height * 0.15 + 20 * (0.5 - (angle % 1))),
      size.width * 0.35,
      const Color(0xFFFF8A3D),
    );
    blob(
      Offset(size.width * 0.85 - 20 * (angle % 1),
          size.height * 0.3 + 30 * (0.5 + 0.5 * (angle % 2))),
      size.width * 0.3,
      const Color(0xFFEB4D8B),
    );
    blob(
      Offset(size.width * 0.5, size.height * 0.05),
      size.width * 0.25,
      const Color(0xFF3B5999),
    );
  }

  @override
  bool shouldRepaint(covariant _BlobBackgroundPainter oldDelegate) => true;
}

/// A small wrapper that gives any child a satisfying tap-scale animation.
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _scale = 0.96),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _scale = 1),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

/// A custom animated checkbox with a bouncy check-in animation.
class _AnimatedCheckbox extends StatelessWidget {
  final bool value;
  final VoidCallback onChanged;
  const _AnimatedCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: value
              ? const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFEB4D8B)])
              : null,
          color: value ? null : Colors.white,
          border: Border.all(
            color: value ? Colors.transparent : Colors.grey.shade400,
            width: 1.4,
          ),
        ),
        child: value
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
  }
}