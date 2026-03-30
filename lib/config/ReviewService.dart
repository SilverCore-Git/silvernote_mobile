import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../config/app_constants.dart';

class ReviewService {
  static const String _fileName = 'review_settings.json';

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<Map<String, dynamic>> readSettings() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        if (kDebugMode) {
          print("Fichier JSON inexistant. Création des valeurs par défaut.");
        }
        return {'counter': 3, 'neverShowAgain': false};
      }

      final contents = await file.readAsString();

      if (kDebugMode) {
        print("----------------------------------");
      }
      if (kDebugMode) {
        print("DEBUG REVIEW SERVICE :");
      }
      if (kDebugMode) {
        print("Contenu brut : $contents");
      }

      return json.decode(contents);
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la lecture du JSON : $e");
      }
      return {'counter': 3, 'neverShowAgain': false};
    }
  }

  Future<void> saveSettings(int counter, bool neverShowAgain) async {
    final file = await _localFile;
    final data = json.encode({
      'counter': counter,
      'neverShowAgain': neverShowAgain,
    });

    if (kDebugMode) {
      print("Sauvegarde des réglages review : $data");
    }

    await file.writeAsString(data);
  }
}