import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class DbViewerScreen extends StatefulWidget {
  final String dbPath;

  const DbViewerScreen({super.key, required this.dbPath});

  @override
  _DbViewerScreenState createState() => _DbViewerScreenState();
}

class _DbViewerScreenState extends State<DbViewerScreen> {
  List<Map<String, dynamic>> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDatabaseData();
  }

  Future<void> _loadDatabaseData() async {
    final db = await openDatabase(widget.dbPath);
    final result = await db.query('recipes');
    setState(() {
      _recipes = result;
      _isLoading = false;
    });
    await db.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SQLite DB Viewer')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.separated(
                itemCount: _recipes.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final recipe = _recipes[index];
                  return ListTile(
                    title: Text(recipe['title']),
                    subtitle: Text(recipe['description']),
                  );
                },
              ),
            ),
    );
  }
}
