import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite_db_recipe_app/database/database_helper.dart';
import 'package:sqlite_db_recipe_app/models/recipe_model.dart';
import 'package:sqlite_db_recipe_app/screens/db_viewer_screen.dart';

class ImportDbScreen extends StatefulWidget {
  const ImportDbScreen({super.key});

  @override
  State<ImportDbScreen> createState() => _ImportDbScreenState();
}

class _ImportDbScreenState extends State<ImportDbScreen> {
  bool _isLoading = false;
  String? _message;
  bool _overwrite = false;

  Future<void> _pickAndImportDb() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;

        if (filePath.endsWith('.db')) {
          print('Picked DB file: $filePath');
        } else {
          print('Please select a valid .db file');
        }
      } else {
        print('No file selected');
      }

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        await _importRecipesFromDb(filePath);
      } else {
        setState(() {
          _message = "No file selected.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importRecipesFromDb(String path) async {
    if (_overwrite) {
      await DatabaseHelper.instance.replaceDatabase(path);
      setState(() {
        _message = '✅ Database replaced successfully!';
      });
    } else {
      final tempDb = await openDatabase(path);
      final tableExists = await _checkTableSchema(tempDb);

      if (!tableExists) {
        setState(() {
          _message = 'Invalid DB: Required table/columns not found.';
        });
        await tempDb.close();
        return;
      }

      final List<Map<String, Object?>> maps = await tempDb.query('recipes');
      for (var map in maps) {
        final title = map['title']?.toString() ?? '';
        final description = map['description']?.toString() ?? '';
        if (title.isNotEmpty && description.isNotEmpty) {
          await DatabaseHelper.instance.insertRecipe(
            Recipe(title: title, description: description),
          );
        }
      }

      await tempDb.close();
      setState(() {
        _message = '✅ Recipes imported successfully!';
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DbViewerScreen(dbPath: path),
      ),
    );
  }

  Future<bool> _checkTableSchema(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(recipes);");
      final columns = result.map((row) => row['name']).toList();
      return columns.contains('title') && columns.contains('description');
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Recipes DB'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndImportDb,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select DB File'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _overwrite,
                  onChanged: (bool? value) {
                    setState(() {
                      _overwrite = value ?? false;
                    });
                  },
                ),
                const Text('Overwrite Existing Recipes'),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_message != null)
              Text(
                _message!,
                style: TextStyle(
                  color: _message!.startsWith("✅") ? Colors.green : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
