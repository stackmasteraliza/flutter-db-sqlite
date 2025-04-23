import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:sqlite_db_recipe_app/database/database_helper.dart';
import 'package:sqlite_db_recipe_app/models/recipe_model.dart';
import 'package:sqlite_db_recipe_app/screens/db_file_upload_screen.dart';
import 'package:sqlite_db_recipe_app/screens/export_to_pdf.dart';
import 'package:sqlite_db_recipe_app/screens/recipe_from_screen.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  List<Recipe> recipes = [];
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    printRecipes();
  }

  Future<void> _exportDatabase() async {
    final all = await DatabaseHelper.instance.getRecipes();
    print("📋 Recipes before export: ${all.length}");
    for (var r in all) {
      print("${r.title} - ${r.description}");
    }

    final exportedPath = await DatabaseHelper.instance.exportDatabase();
    if (exportedPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Database exported to Downloads'),
          action: SnackBarAction(
            label: 'OPEN',
            onPressed: () => _openFile(exportedPath),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export database')),
      );
    }
  }

  Future<void> _openFile(String path) async {
    try {
      await OpenFile.open(path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: $e')),
      );
    }
  }

  void printRecipes() async {
    final recipes = await DatabaseHelper.instance.getRecipes();
    for (var recipe in recipes) {
      print(
          'ID: ${recipe.id}, Title: ${recipe.title}, Description: ${recipe.description}');
    }
  }

  Future<void> _loadRecipes() async {
    final loadedRecipes = await dbHelper.getRecipes();
    setState(() {
      recipes = loadedRecipes;
    });
  }

  void _navigateToRecipeForm(Recipe? recipe) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeFormScreen(recipe: recipe),
      ),
    );

    if (result == true) {
      _loadRecipes();
    }
  }

  Future<void> _refreshRecipes() async {
    await _loadRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Recipes'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: RefreshIndicator(
            onRefresh: _refreshRecipes,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'Title',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'Description',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: recipes.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return InkWell(
                        onTap: () => _navigateToRecipeForm(recipe),
                        child: Container(
                          color: index.isEven ? Colors.grey[50] : Colors.white,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(recipe.title),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(recipe.description),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'import',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ImportDbScreen()),
              ),
              mini: true,
              child: const Icon(Icons.upload),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'export',
              onPressed: _exportDatabase,
              mini: true,
              child: const Icon(Icons.save_alt),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              onPressed: () => _navigateToRecipeForm(null),
              child: const Icon(Icons.add),
            ),
          ],
        ));
  }
}
