import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../constants/global_variables.dart';
import '../../../providers/user_provider.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  var textcontroller = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  bool isLoaded = false;
  bool isSaving = false;
  bool _isGenerating = false; // guards against double-submits while awaiting API
  bool _justCopied = false;

  String generatedCode = "Generated Output UI\n(Frontend Only - No Backend)";

  // Raw pieces from the API response, kept separately so we can
  // send clean structured data to MongoDB instead of the formatted string.
  String? apiLanguage;
  String? apiErrors;
  String? apiCorrectedCode;

  final String baseUrl = "https://code-sync-server-kappa.vercel.app";

  late final AnimationController _pulseController;
  late final AnimationController _resultController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _inputFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _resultController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> saveCodeToFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File("${dir.path}/code_$timestamp.txt");
      await file.writeAsString(generatedCode);
    } catch (e) {
      debugPrint("Error saving file locally: $e");
    }
  }

  Future<bool> saveCodeToDatabase() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;

    try {
      final url = Uri.parse("$baseUrl/save-code");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": user.email,
          "originalCode": textcontroller.text,
          "correctedCode": apiCorrectedCode ?? "",
          "errors": apiErrors ?? "",
          "language": apiLanguage ?? "",
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error saving code to MongoDB: $e");
      return false;
    }
  }

  Future<void> saveCodeEverywhere() async {
    setState(() => isSaving = true);

    await saveCodeToFile();
    final dbSaved = await saveCodeToDatabase();

    setState(() => isSaving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dbSaved ? const Color(0xFF1F8A5A) : const Color(0xFFB3541E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(dbSaved ? Icons.check_circle : Icons.error_outline,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                dbSaved
                    ? "Code saved locally and to database"
                    : "Code saved locally, but database save failed",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> generateCorrectedCode() async {
    if (textcontroller.text.isEmpty || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      isLoaded = true;
      generatedCode = "Loading...";
    });
    _resultController.forward(from: 0);

    try {
      final url = Uri.parse("$baseUrl/fix-code");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"code": textcontroller.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          apiLanguage = data['language']?.toString();
          apiErrors = data['errors']?.toString();
          apiCorrectedCode = data['correctedCode']?.toString();

          generatedCode =
              "Language: ${data['language']}\n\nErrors:\n${data['errors']}\n\nCorrected Code:\n${data['correctedCode']}";
        });
      } else {
        setState(() => generatedCode = "Error: ${response.body}");
      }
    } catch (e) {
      setState(() => generatedCode = "Error connecting to server: $e");
    } finally {
      if (mounted) setState(() => _isGenerating = false);
      _resultController.forward(from: 0);
    }
  }

  static const Color _panelBg = Color(0xFF0E1622);
  static const Color _accentBlue = Color(0xFF223447);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF151F2B), _accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          centerTitle: true,
          title: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) => Transform.scale(
                      scale: 1 + 0.08 * _pulseController.value,
                      child: const Icon(Icons.auto_awesome,
                          color: Colors.orangeAccent, size: 18),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    GlobalVariables.WelcomeText,
                    style: TextStyle(
                      fontFamily: 'Poppins-Bold',
                      letterSpacing: 1.0,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
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
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildInputCard(),
              const SizedBox(height: 14),
              _buildOutputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    final focused = _inputFocus.hasFocus;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 16), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 260,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: focused ? const Color(0xFFFF8A3D) : Colors.transparent,
                  width: 1.6,
                ),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                radius: const Radius.circular(8),
                child: SingleChildScrollView(
                  child: TextFormField(
                    controller: textcontroller,
                    focusNode: _inputFocus,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                    decoration: const InputDecoration(
                      hintText: 'Write or paste code here...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _GradientButton(
                onPressed: _isGenerating ? null : generateCorrectedCode,
                loading: _isGenerating,
                icon: Icons.auto_fix_high_rounded,
                label: 'Generate',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputArea() {
    return Container(
      constraints: const BoxConstraints(minHeight: 420),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isLoaded ? _buildResultView() : _buildIdleView(),
    );
  }

  Widget _buildIdleView() {
    return SizedBox(
      height: 420,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) => CustomPaint(
                size: const Size(120, 120),
                painter: _PulsingRingPainter(_pulseController.value),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '🤖 Meet Our DR AI',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A3F4B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Paste your code above and tap Generate',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final showLoadingDots = generatedCode == "Loading...";
    return FadeTransition(
      opacity: _resultController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(
            parent: _resultController, curve: Curves.easeOutCubic)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF7F8FB),
              ),
              alignment: Alignment.center,
              child: showLoadingDots
                  ? _buildLoadingDots()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(14),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: SelectableText(
                          generatedCode,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _OutlinedActionButton(
                    icon: _justCopied ? Icons.check_rounded : Icons.copy_rounded,
                    label: _justCopied ? 'Copied!' : 'Copy Code',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: generatedCode));
                      setState(() => _justCopied = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: _accentBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          content: const Text("Code copied!"),
                        ),
                      );
                      await Future.delayed(const Duration(seconds: 2));
                      if (mounted) setState(() => _justCopied = false);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GradientButton(
                    onPressed: isSaving ? null : saveCodeEverywhere,
                    loading: isSaving,
                    icon: Icons.save_rounded,
                    label: 'Save Code',
                    compact: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final t = (_pulseController.value + i * 0.25) % 1.0;
            final scale = 0.6 + 0.4 * (0.5 - (t - 0.5).abs()) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF8A3D),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Gradient, tap-scaling primary button used across the screen.
class _GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final IconData icon;
  final String label;
  final bool compact;

  const _GradientButton({
    required this.onPressed,
    required this.loading,
    required this.icon,
    required this.label,
    this.compact = false,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: disabled ? null : (_) => setState(() => _scale = 0.96),
      onTapUp: disabled ? null : (_) => setState(() => _scale = 1),
      onTapCancel: disabled ? null : () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: widget.compact ? 48 : 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: disabled
                  ? [Colors.grey.shade400, Colors.grey.shade400]
                  : const [Color(0xFFFF8A3D), Color(0xFFEB4D8B)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: disabled
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFFFF8A3D).withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: widget.loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 19),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _OutlinedActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF223447),
          side: const BorderSide(color: Color(0xFF223447), width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(icon, key: ValueKey(icon), size: 18),
        ),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// A custom animated pulsing ring, used as a lightweight replacement for a
/// static loader gif on the idle state.
class _PulsingRingPainter extends CustomPainter {
  final double t;
  _PulsingRingPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (int i = 0; i < 3; i++) {
      final progress = (t + i / 3) % 1.0;
      final radius = 20 + progress * 40;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = const Color(0xFFFF8A3D).withOpacity(opacity * 0.6);
      canvas.drawCircle(center, radius, paint);
    }
    final corePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF8A3D), Color(0xFFEB4D8B)],
      ).createShader(Rect.fromCircle(center: center, radius: 22));
    canvas.drawCircle(center, 20, corePaint);

    final icon = Icons.smart_toy_rounded;
    final textPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 22,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      )
      ..layout();
    textPainter.paint(
        canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PulsingRingPainter oldDelegate) => true;
}