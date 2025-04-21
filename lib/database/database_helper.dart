import 'dart:io';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqlite_db_recipe_app/models/recipe_model.dart';
import 'package:permission_handler/permission_handler.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('recipes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    print("Creating recipes table...");
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertRecipe(Recipe recipe) async {
    final db = await instance.database;
    return await db.insert('recipes', recipe.toMap());
  }

  Future<List<Recipe>> getRecipes() async {
    final db = await instance.database;
    final maps = await db.query('recipes');
    return maps.map((map) => Recipe.fromMap(map)).toList();
  }

  Future<int> updateRecipe(Recipe recipe) async {
    final db = await instance.database;
    return await db.update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  Future<int> deleteRecipe(int id) async {
    final db = await instance.database;
    return await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<String?> exportDatabase() async {
    try {
      // Request storage permission
      var status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        print("❌ Storage permission denied");
        return null;
      }

      final dbPath = await getDatabasesPath();
      final sourceFile = File('$dbPath/recipes.db');

      if (!await sourceFile.exists()) {
        print("❌ Database file not found");
        return null;
      }

      // Save to public Downloads folder
      final directory = Directory('/storage/emulated/0/Download');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final destPath = '${directory.path}/recipes_backup_$timestamp.db';

      final copiedFile = await sourceFile.copy(destPath);

      print("✅ Database exported to: $destPath");
      return destPath;
    } catch (e) {
      print("❌ Error exporting database: $e");
    }
    return null;
  }
}
