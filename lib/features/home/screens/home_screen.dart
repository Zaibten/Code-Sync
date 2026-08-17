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

class _HomeScreenState extends State<HomeScreen> {
  var textcontroller = TextEditingController();
  bool isLoaded = false;
  bool isSaving = false;

  String generatedCode = "Generated Output UI\n(Frontend Only - No Backend)";

  // Raw pieces from the API response, kept separately so we can
  // send clean structured data to MongoDB instead of the formatted string.
  String? apiLanguage;
  String? apiErrors;
  String? apiCorrectedCode;

  final String baseUrl = "https://code-sync-server-kappa.vercel.app";

  Future<void> saveCodeToFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/generated_code.txt");
      await file.writeAsString(generatedCode);
    } catch (e) {
      // Silently ignore here - the combined save handler below will
      // show one consolidated message to the user.
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
        content: Text(
          dbSaved
              ? "Code saved locally and to database"
              : "Code saved locally, but database save failed",
        ),
      ),
    );
  }

  Future<void> generateCorrectedCode() async {
    if (textcontroller.text.isEmpty) return;

    setState(() {
      isLoaded = true;
      generatedCode = "Loading...";
    });

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF151F2B), Color(0xFF223447)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          centerTitle: true,
          title: Column(
            children: [
              const Text(
                GlobalVariables.WelcomeText,
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
          // Refresh icon removed from actions.
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 350,
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          radius: const Radius.circular(8),
                          child: SingleChildScrollView(
                            child: TextFormField(
                              controller: textcontroller,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              decoration: const InputDecoration(
                                hintText: 'Write or paste code here...',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 300,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: GlobalVariables.whitecolor,
                          backgroundColor: GlobalVariables.btncolor,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: generateCorrectedCode,
                        child: const Text("Generate"),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 490,
                child: isLoaded
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              height: 300,
                              width: double.infinity,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  generatedCode,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 180,
                                height: 50,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.copy),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: GlobalVariables.btncolor,
                                    foregroundColor: GlobalVariables.whitecolor,
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: generatedCode),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Code copied!")),
                                    );
                                  },
                                  label: const Text('Copy Code'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 150,
                                height: 50,
                                child: ElevatedButton.icon(
                                  icon: isSaving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: GlobalVariables.btncolor,
                                    foregroundColor: GlobalVariables.whitecolor,
                                  ),
                                  onPressed: isSaving ? null : saveCodeEverywhere,
                                  label: const Text('Save Code'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: GlobalVariables.whitecolor,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset("assets/images/loader.gif"),
                            const Text(
                              '🤖 Meet Our DR AI',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 139, 139, 139),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}