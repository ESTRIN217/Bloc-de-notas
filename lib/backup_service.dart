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
  static const String _keyLastCloud = 'last_cloud_sync';
  static const String _keyLastLocal = 'last_local_sync';
 
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;
  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get user => _currentUser;
  
  Future<void> _updateTimestamp(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    // Formato simple: dd/MM/yyyy HH:mm
    await prefs.setString(key, "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}");
  }
  
  Future<String> getLastCloudSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastCloud) ?? "Nunca";
  }

  Future<String> getLastLocalSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastLocal) ?? "Nunca";
  }
  
  Future<void> initialize() async {
    await googleSignIn.initialize(
      serverClientId: '553663565353-9ngn5cci4abakms72m0s1mmp1u4blr2b.apps.googleusercontent.com',
    );
    _currentUser = await googleSignIn.attemptLightweightAuthentication();
  }

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

    await _updateTimestamp(_keyLastLocal);
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
  try {
    if (googleSignIn.supportsAuthenticate()) {
      // 1. Autenticación básica (Login)
      final GoogleSignInAccount account = await googleSignIn.authenticate();

      // 2. Autorización de Scopes (Permisos de Drive)
      // Definimos el scope que necesitas
      final driveScope = [drive.DriveApi.driveAppdataScope];
      
      // Solicitamos el permiso explícito al usuario
      await account.authorizationClient.authorizeScopes(driveScope);
      
      _currentUser = account;
      return account;
        }
    return null;
  } catch (e) {
    debugPrint('Error en el inicio de sesión: $e');
    rethrow;
  }
  }

  Future<void> signOut() async {
    await googleSignIn.signOut();
    _currentUser = null;
  }

  Future<bool> isSignedIn() async {
    // attemptLightweightAuthentication reemplaza a signInSilently()
    final account = await googleSignIn.attemptLightweightAuthentication();
    return account != null;
  }

  Future<void> backupToDrive() async {
    // 1. Obtenemos el usuario actual (debe estar logueado previamente)
    final account = user;
    if (account == null) throw Exception("No hay un usuario autenticado");

    // 2. Definimos los scopes necesarios
    final driveScopes = [drive.DriveApi.driveAppdataScope];

    // 3. Obtenemos la autorización (esto verifica si el usuario ya dio permiso)
    final authorization = await account.authorizationClient.authorizeScopes(driveScopes);

    // 4. USAMOS LA EXTENSIÓN: El método correcto es .authClient() 
    // Se llama sobre el objeto 'authorization', no sobre GoogleSignIn
    final client = authorization.authClient(scopes: driveScopes);
    

    final driveApi = drive.DriveApi(client);
    final backupJson = await createBackupJson();
    
    final List<int> bytes = utf8.encode(backupJson);
    final media = drive.Media(Stream.fromIterable([bytes]), bytes.length);

    // Búsqueda y subida (tu lógica de Drive se mantiene igual)
    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName'",
    );

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      final existingFileId = fileList.files!.first.id!;
      await driveApi.files.update(
        drive.File(), 
        existingFileId, 
        uploadMedia: media,
      );
    } else {
      final driveFile = drive.File()
        ..name = _backupFileName
        ..parents = ['appDataFolder'];
        
      await driveApi.files.create(
        driveFile, 
        uploadMedia: media,
      );
    }
    await _updateTimestamp(_keyLastCloud);
  }

  Future<bool> restoreFromDrive() async {
  // 1. Obtener el usuario actual
  final account = user;
  if (account == null) throw Exception("No autenticado");

  // 2. Definir scopes y obtener autorización
  final driveScopes = [drive.DriveApi.driveAppdataScope];
  final authorization = await account.authorizationClient.authorizeScopes(driveScopes);

  // 3. Usar el método correcto de la extensión: .authClient()
  final client = authorization.authClient(scopes: driveScopes);

  final driveApi = drive.DriveApi(client);

  final fileList = await driveApi.files.list(
    spaces: 'appDataFolder',
    q: "name = '$_backupFileName'",
  );

  if (fileList.files == null || fileList.files!.isEmpty) {
    return false; // No hay copia de seguridad
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