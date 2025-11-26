import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../constants/global_variables.dart';

class SavedCodesScreen extends StatefulWidget {
  const SavedCodesScreen({super.key});

  @override
  State<SavedCodesScreen> createState() => _SavedCodesScreenState();
}

class _SavedCodesScreenState extends State<SavedCodesScreen> {
  List<FileSystemEntity> fileList = [];

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  Future<void> loadFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final directory = Directory(dir.path);

    if (directory.existsSync()) {
      setState(() {
        fileList = directory
            .listSync()
            .where((f) => f.path.endsWith(".txt"))
            .toList();
      });
    }
  }

  void openFile(File file) {
    String content = file.readAsStringSync();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 350,
          height: 450,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.path.split('/').last,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    content,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Copy Button
                  ElevatedButton.icon(
                    icon: Icon(Icons.copy),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalVariables.btncolor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: content));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Code copied")),
                      );
                    },
                    label: Text("Copy"),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  confirmDelete(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Are you sure you want to delete this file?"),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),

          TextButton(
            child: Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              deleteFile(file);
            },
          ),
        ],
      ),
    );
  }

  void deleteFile(File file) {
    file.deleteSync();
    loadFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalVariables.backgroundColor,
        centerTitle: true,
        title: Text(
          "Saved Codes",
          style: TextStyle(
            fontFamily: "Poppins-Bold",
            letterSpacing: 1.0,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: GlobalVariables.btncolor,
                shape: StadiumBorder(),
                minimumSize: Size(5, 40),
              ),
              onPressed: loadFiles,
              child: Icon(Icons.refresh),
            ),
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: fileList.isEmpty
            ? Center(
                child: Text(
                  "No saved code files found",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: fileList.length,
                itemBuilder: (ctx, index) {
                  File file = fileList[index] as File;

                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.code, color: GlobalVariables.btncolor),
                      title: Text(file.path.split('/').last),
                      subtitle: Text("Tap to view code"),

                      onTap: () {
                        openFile(file);
                      },

                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => confirmDelete(file),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
