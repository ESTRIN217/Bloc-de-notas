import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

// Google Drive & Auth
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class BackupService {
  static const String _backupFileName = 'bloc_notas_backup.json';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  // --- 1. RECOPILAR Y EMPAQUETAR DATOS (LOCAL -> JSON) ---
  Future<String> createBackupJson() async {
    final prefs = await SharedPreferences.getInstance();
    
    String notes = '[]';
    String archived = '[]';
    String trashed = '[]';
    List<String> tags = prefs.getStringList('available_tags') ?? [];

    if (kIsWeb) {
      notes = prefs.getString('notes') ?? '[]';
      archived = prefs.getString('archived_notes') ?? '[]';
      trashed = prefs.getString('trashed_notes') ?? '[]';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final fileNotes = File('${dir.path}/notes.json');
      final fileArchived = File('${dir.path}/archived_notes.json');
      final fileTrashed = File('${dir.path}/trashed_notes.json');

      if (await fileNotes.exists()) notes = await fileNotes.readAsString();
      if (await fileArchived.exists()) archived = await fileArchived.readAsString();
      if (await fileTrashed.exists()) trashed = await fileTrashed.readAsString();
    }

    // Empaquetamos todo en un solo mapa
    final backupData = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'notes': jsonDecode(notes),
      'archived': jsonDecode(archived),
      'trashed': jsonDecode(trashed),
      'tags': tags,
    };

    return jsonEncode(backupData);
  }

  // --- 2. RESTAURAR DATOS (JSON -> LOCAL) ---
  Future<void> restoreFromJson(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final prefs = await SharedPreferences.getInstance();

    final notesStr = jsonEncode(data['notes'] ?? []);
    final archivedStr = jsonEncode(data['archived'] ?? []);
    final trashedStr = jsonEncode(data['trashed'] ?? []);
    final List<String> tags = List<String>.from(data['tags'] ?? []);

    await prefs.setStringList('available_tags', tags);

    if (kIsWeb) {
      await prefs.setString('notes', notesStr);
      await prefs.setString('archived_notes', archivedStr);
      await prefs.setString('trashed_notes', trashedStr);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      await File('${dir.path}/notes.json').writeAsString(notesStr);
      await File('${dir.path}/archived_notes.json').writeAsString(archivedStr);
      await File('${dir.path}/trashed_notes.json').writeAsString(trashedStr);
    }
  }

  // --- 3. LÓGICA DE GOOGLE DRIVE ---
  
  Future<GoogleSignInAccount?> signIn() async {
    return await _googleSignIn.signIn();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  Future<void> backupToDrive() async {
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) throw Exception("No autenticado");

    final driveApi = drive.DriveApi(client);
    final backupJson = await createBackupJson();
    
    // Convertimos el string JSON a un stream de bytes para subirlo
    final List<int> bytes = utf8.encode(backupJson);
    final media = drive.Media(Stream.value(bytes), bytes.length);

    // 1. Buscar si ya existe un backup previo en appDataFolder
    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName'",
    );

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      // 2. Si existe, lo actualizamos (sobrescribimos)
      final existingFileId = fileList.files!.first.id!;
      await driveApi.files.update(
        drive.File(), 
        existingFileId, 
        uploadMedia: media,
      );
    } else {
      // 3. Si no existe, creamos uno nuevo dentro de appDataFolder
      final driveFile = drive.File()
        ..name = _backupFileName
        ..parents = ['appDataFolder'];
        
      await driveApi.files.create(
        driveFile, 
        uploadMedia: media,
      );
    }
  }

  Future<bool> restoreFromDrive() async {
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) throw Exception("No autenticado");

    final driveApi = drive.DriveApi(client);

    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName'",
    );

    if (fileList.files == null || fileList.files!.isEmpty) {
      return false; // No hay copia de seguridad en la nube
    }

    final fileId = fileList.files!.first.id!;
    
    // Descargamos el archivo
    final drive.Media fileMedia = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    // Convertimos los bytes descargados a String
    final List<int> dataStore = [];
    await for (var data in fileMedia.stream) {
      dataStore.addAll(data);
    }
    final String jsonString = utf8.decode(dataStore);

    // Restauramos
    await restoreFromJson(jsonString);
    return true;
  }
}