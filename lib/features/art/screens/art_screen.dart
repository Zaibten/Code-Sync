import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../constants/global_variables.dart';
import '../../../providers/user_provider.dart';

/// Unified representation of a saved code record,
/// whether it came from the local filesystem or MongoDB.
class CodeRecord {
  final String title;
  final String content;
  final String source; // "Local" or "Database"
  final DateTime? date;
  final File? file; // set only for local records
  final String? id; // set only for database records

  CodeRecord({
    required this.title,
    required this.content,
    required this.source,
    this.date,
    this.file,
    this.id,
  });
}

class SavedCodesScreen extends StatefulWidget {
  const SavedCodesScreen({super.key});

  @override
  State<SavedCodesScreen> createState() => _SavedCodesScreenState();
}

class _SavedCodesScreenState extends State<SavedCodesScreen>
    with TickerProviderStateMixin {
  final String baseUrl = "https://code-sync-server-kappa.vercel.app";

  List<CodeRecord> records = [];
  bool isLoading = false;

  Timer? _autoRefreshTimer;
  static const Duration _refreshInterval = Duration(seconds: 15);

  late final AnimationController _refreshIconController;

  Color get _btnColor => GlobalVariables.btncolor;

  @override
  void initState() {
    super.initState();

    _refreshIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    loadAllRecords();

    // Auto-refresh on an interval since there's no manual refresh button anymore.
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (_) {
      loadAllRecords(silent: true);
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _refreshIconController.dispose();
    super.dispose();
  }

  Future<List<CodeRecord>> loadLocalFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final directory = Directory(dir.path);

    if (!directory.existsSync()) return [];

    final files = directory
        .listSync()
        .where((f) => f.path.endsWith(".txt"))
        .whereType<File>()
        .toList();

    // Sort newest first based on last modified time.
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    return files
        .map(
          (file) => CodeRecord(
            title: file.path.split('/').last,
            content: file.readAsStringSync(),
            source: "Local",
            date: file.lastModifiedSync(),
            file: file,
          ),
        )
        .toList();
  }

  Future<List<CodeRecord>> loadDatabaseRecords() async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      final url =
          Uri.parse("$baseUrl/get-codes?email=${Uri.encodeComponent(user.email)}");
      final response = await http.get(url);

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      final List data = decoded['data'] ?? [];

      return data.map<CodeRecord>((item) {
        final language = item['language'] ?? 'Unknown';
        final createdAt =
            item['createdAt'] != null ? DateTime.tryParse(item['createdAt']) : null;

        final content =
            "Language: $language\n\nOriginal Code:\n${item['originalCode'] ?? ''}\n\n"
            "Errors:\n${item['errors'] ?? ''}\n\n"
            "Corrected Code:\n${item['correctedCode'] ?? ''}";

        return CodeRecord(
          title: "$language • ${_formatDate(createdAt)}",
          content: content,
          source: "Database",
          date: createdAt,
          id: item['_id'],
        );
      }).toList();
    } catch (e) {
      debugPrint("Error loading database codes: $e");
      return [];
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Unknown date";
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Future<void> loadAllRecords({bool silent = false}) async {
    if (!silent) {
      setState(() => isLoading = true);
      _refreshIconController.repeat();
    }

    final local = await loadLocalFiles();
    final remote = await loadDatabaseRecords();

    final combined = [...local, ...remote];
    combined.sort((a, b) {
      final ad = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    if (!mounted) return;
    setState(() {
      records = combined;
      isLoading = false;
    });
    _refreshIconController
      ..stop()
      ..value = 0;
  }

  void openRecord(CodeRecord record) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'record',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return Transform.scale(
          scale: 0.9 + 0.1 * curved.value,
          child: Opacity(
            opacity: anim.value.clamp(0.0, 1.0),
            child: Center(
              child: Dialog(
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  width: 350,
                  height: 450,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              record.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _sourceChip(record.source),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FB),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              record.content,
                              style: const TextStyle(
                                  fontSize: 13.5, color: Colors.black87, height: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.copy, size: 18),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _btnColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: record.content));
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  content: const Text("Code copied"),
                                ),
                              );
                            },
                            label: const Text("Copy"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sourceChip(String source) {
    final isLocal = source == "Local";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLocal ? Colors.blueGrey.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        source,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isLocal ? Colors.blueGrey.shade800 : Colors.green.shade800,
        ),
      ),
    );
  }

  void confirmDelete(CodeRecord record) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'delete',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secAnim, child) {
        return Transform.scale(
          scale: 0.9 + 0.1 * anim.value,
          child: Opacity(
            opacity: anim.value.clamp(0.0, 1.0),
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text("Confirm Delete"),
                ],
              ),
              content: Text(
                record.source == "Local"
                    ? "Are you sure you want to delete this local file?"
                    : "Are you sure you want to delete this record from the database?",
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Delete", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.pop(context);
                    deleteRecord(record);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> deleteRecord(CodeRecord record) async {
    if (record.source == "Local" && record.file != null) {
      record.file!.deleteSync();
      loadAllRecords();
      return;
    }

    if (record.source == "Database" && record.id != null) {
      try {
        final url = Uri.parse("$baseUrl/delete-code/${record.id}");
        final response = await http.delete(url);

        if (response.statusCode == 200) {
          loadAllRecords();
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              content: const Text("Failed to delete from database"),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: const Text("Error deleting from database"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: GlobalVariables.backgroundColor,
        centerTitle: true,
        title: const Text(
          "Saved Codes",
          style: TextStyle(
            fontFamily: "Poppins-Bold",
            letterSpacing: 1.0,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          RotationTransition(
            turns: _refreshIconController,
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: isLoading ? null : () => loadAllRecords(silent: false),
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : records.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () => loadAllRecords(silent: false),
                    color: _btnColor,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      itemCount: records.length,
                      itemBuilder: (ctx, index) {
                        final record = records[index];
                        return _AnimatedListItem(
                          index: index,
                          child: _buildRecordCard(record),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        builder: (context, v, child) => Opacity(
          opacity: v,
          child: Transform.scale(scale: 0.9 + 0.1 * v, child: child),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _btnColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_rounded, size: 52, color: _btnColor.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            const Text(
              "No saved code records found",
              style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              "Generate and save code from the Home tab",
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(CodeRecord record) {
    final isLocal = record.source == "Local";
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => openRecord(record),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isLocal
                          ? [Colors.blueGrey.shade300, Colors.blueGrey.shade500]
                          : [const Color(0xFF34C77B), const Color(0xFF1F8A5A)],
                    ),
                  ),
                  child: Icon(
                    isLocal ? Icons.save_alt_rounded : Icons.cloud_done_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 5),
                      _sourceChip(record.source),
                    ],
                  ),
                ),
                _DeleteButton(onPressed: () => confirmDelete(record)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Staggers each list item's entrance with a fade + slide-up animation
/// based on its index, giving the list a smooth, professional feel.
class _AnimatedListItem extends StatelessWidget {
  final int index;
  final Widget child;
  const _AnimatedListItem({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (index.clamp(0, 8) * 40)),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: child),
      ),
      child: child,
    );
  }
}

class _DeleteButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _DeleteButton({required this.onPressed});

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.85),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
        ),
      ),
    );
  }
}