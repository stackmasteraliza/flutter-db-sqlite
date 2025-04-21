import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqlite_db_recipe_app/database/database_helper.dart';
import 'package:flutter/foundation.dart';

Future<void> exportRecipesToPDF() async {
  final pdf = pw.Document();
  final recipes = await DatabaseHelper.instance.getRecipes();

  pdf.addPage(
    pw.MultiPage(
      build: (pw.Context context) => recipes.map((recipe) {
        return pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Title: ${recipe.title}",
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                "Description: ${recipe.description}",
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Divider(),
            ],
          ),
        );
      }).toList(),
    ),
  );

  try {
    final bytes = await pdf.save();

    if (Platform.isAndroid) {
      await _savePdfToDownloadsAndroid(bytes);
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/recipes_export.pdf");
      await file.writeAsBytes(bytes);
      print("✅ PDF saved at: ${file.path}");
    }
  } catch (e) {
    print("❌ Error saving PDF: $e");
  }
}

Future<void> _savePdfToDownloadsAndroid(Uint8List bytes) async {
  try {
    Directory? directory = await getExternalStorageDirectory();
    String downloadsPath = "${directory?.path}/Download";

    if (!await Directory(downloadsPath).exists()) {
      await Directory(downloadsPath).create(recursive: true);
    }

    String fileName =
        "Recipes_Export_${DateTime.now().millisecondsSinceEpoch}.pdf";
    String filePath = "$downloadsPath/$fileName";

    final file = File(filePath);
    await file.writeAsBytes(bytes);
    await _notifyMediaScanner(filePath);

    print("✅ PDF saved at: $filePath");
  } catch (e) {
    print("❌ Failed to save PDF: $e");
    final directory = await getApplicationDocumentsDirectory();
    final file = File("${directory.path}/recipes_export.pdf");
    await file.writeAsBytes(bytes);
    print("⚠️ Saved in app directory: ${file.path}");
  }
}

Future<void> _notifyMediaScanner(String filePath) async {
  if (Platform.isAndroid) {
    try {
      const platform = MethodChannel('your_channel_name');
      await platform.invokeMethod('scanFile', {'path': filePath});
    } catch (e) {
      print("⚠️ Could not notify MediaScanner: $e");
    }
  }
}
