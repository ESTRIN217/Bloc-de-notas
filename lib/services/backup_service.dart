import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:bloc_de_notas/services/log_service.dart';

// Google Drive & Auth
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class BackupService {
  static const String _backupFileName = 'bloc_notas_backup.json';
  static const String _keyLastCloud = 'last_cloud_sync';
  static const String _keyLastLocal = 'last_local_sync';
  static const String _webClientId = '75724238092-s5b6rpdbltabptna6iuq8o80sac9roj7.apps.googleusercontent.com';
  static const String _androidClientId = '75724238092-ihhufgnfb6snr44v4q4hb8nngco4mkrd.apps.googleusercontent.com';

  final GoogleSignIn googleSignIn = GoogleSignIn.instance;
  GoogleSignInAccount? _currentUser;

  // Getter reactivo de lectura directa
  GoogleSignInAccount? get user => _currentUser;

  // ARQUITECTURA REACTIVA (v7.x): Exponemos el flujo de eventos para que la UI escuche cambios en tiempo real
  Stream<GoogleSignInAuthenticationEvent?> get onCurrentUserChanged =>
      googleSignIn.authenticationEvents;

  Future<void> _updateTimestamp(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString(
      key,
      "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}",
    );
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
    if (kIsWeb) {
      // Configuración estricta para el entorno Web
      await googleSignIn.initialize(
        clientId: _webClientId,
      );
    } else {
      // Configuración óptima para Android / Entornos Móviles
      await googleSignIn.initialize(
        // Pasamos el ID Web como serverClientId para permitir que Android pueda
        // generar un token de autenticación válido para los alcances de Google Drive API
        serverClientId: _webClientId,
      );
    }

    //  Nos suscribimos de manera reactiva para actualizar el estado del usuario automáticamente ante cualquier cambio
    googleSignIn.authenticationEvents.listen((
      GoogleSignInAuthenticationEvent event,
    ) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        // Aquí el analizador sí reconoce "event.user" sin problemas
        _currentUser = event.user;
      } else if (event is GoogleSignInAuthenticationEventSignOut) {
        // El usuario cerró sesión
        _currentUser = null;
      }
    });

    _currentUser = await googleSignIn
        .attemptLightweightAuthentication(); // [cite: 775]
  }

  // --- ALGORITMO RESILIENTE: Exponential Backoff con Jitter ---
  //  Envuelve las peticiones a la API de Drive para mitigar los errores de cuota 403 y 429
  Future<T> _retryWithBackoff<T>(Future<T> Function() operation) async {
    int retries = 0;
    const int maxRetries = 3;
    int baseDelayMs = 2000; // Espera base inicial de 2 segundos
    final random = math.Random();

    while (true) {
      try {
        return await operation();
      } catch (e) {
        final errStr = e.toString();
        // [cite: 1016] Detectamos si el error es debido a límites de tasa de peticiones (Rate Limit o Quota Exceeded)
        final isQuotaError = errStr.contains('403') || errStr.contains('429');

        if (isQuotaError && retries < maxRetries) {
          retries++;
          // [cite: 1018] Fórmula exponencial: (2^retries * baseDelay) + variación aleatoria (Jitter) para no saturar en olas sincronizadas
          int backoffMs = (math.pow(2, retries) * baseDelayMs).toInt();
          int jitter = random.nextInt(
            1000,
          ); // Hasta 1 segundo de desvío aleatorio

          Log.w(
            'Límite de cuota de Google Drive alcanzado. Reintento $retries/$maxRetries en ${backoffMs + jitter}ms...',
          );
          await Future.delayed(Duration(milliseconds: backoffMs + jitter));
        } else {
          // Si no es un error de cuotas, o superó el máximo de reintentos, lanzamos la excepción
          rethrow;
        }
      }
    }
  }

  // --- MITIGACIÓN ANDROID: requestSync para sincronización de índices locales ---
  //  Evita que tras una reinstalación el índice local retorne una lista de archivos vacía
  Future<void> _requestAndroidMetaDataSync() async {
    if (!Platform.isAndroid) return;
    try {
      // Usamos un canal de plataforma por si decides enlazar el requestSync() de Play Services de forma nativa
      const channel = MethodChannel('com.example.bloc_notas/google_drive');
      await channel.invokeMethod('requestSync');
    } catch (e) {
      // Fallback silencioso en desarrollo si el canal nativo no se ha declarado aún
      Log.w(
        'Sincronización de metadatos Play Services omitida/no configurada',
        e,
      );
    }
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
      if (await fileArchived.exists()) {
        archived = await fileArchived.readAsString();
      }
      if (await fileTrashed.exists()) {
        trashed = await fileTrashed.readAsString();
      }
    }

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
        final GoogleSignInAccount account = await googleSignIn
            .authenticate(); // [cite: 937]
        final driveScope = [drive.DriveApi.driveAppdataScope]; // [cite: 950]
        await account.authorizationClient.authorizeScopes(
          driveScope,
        ); // [cite: 937]

        _currentUser = account;
        return account;
      }
      return null;
    } catch (e) {
      Log.e('Error en el inicio de sesión', e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await googleSignIn.signOut();
    _currentUser = null;
  }

  Future<bool> isSignedIn() async {
    final account = await googleSignIn.attemptLightweightAuthentication();
    return account != null;
  }

  Future<void> backupToDrive() async {
    final account = user;
    if (account == null) throw Exception("No hay un usuario autenticado");

    final driveScopes = [drive.DriveApi.driveAppdataScope];
    final authorization = await account.authorizationClient.authorizeScopes(
      driveScopes,
    );
    final client = authorization.authClient(scopes: driveScopes); // [cite: 797]
    final driveApi = drive.DriveApi(client);

    final backupJson = await createBackupJson();
    final List<int> bytes = utf8.encode(backupJson);

    // [cite: 1017] Aplicamos el envoltorio de reintentos a la consulta de Drive
    final fileList = await _retryWithBackoff(
      () => driveApi.files.list(
        spaces: 'appDataFolder', // [cite: 996]
        q: "name = '$_backupFileName'",
      ),
    );

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      final existingFileId = fileList.files!.first.id!;

      // [cite: 1017] Aplicamos reintentos a la subida de actualización
      await _retryWithBackoff(() async {
        final media = drive.Media(
          Stream.fromIterable([bytes]),
          bytes.length,
        ); //  Fresh stream por reintento
        return await driveApi.files.update(
          drive.File(),
          existingFileId,
          uploadMedia: media,
        );
      });
    } else {
      final driveFile = drive.File()
        ..name = _backupFileName
        ..parents = ['appDataFolder']; // [cite: 991]

      // [cite: 1017] Aplicamos reintentos a la creación del nuevo archivo
      await _retryWithBackoff(() async {
        final media = drive.Media(
          Stream.fromIterable([bytes]),
          bytes.length,
        ); //  Fresh stream por reintento
        return await driveApi.files.create(driveFile, uploadMedia: media);
      });
    }
    await _updateTimestamp(_keyLastCloud);
  }

  Future<bool> restoreFromDrive() async {
    final account = user;
    if (account == null) throw Exception("No autenticado");

    final driveScopes = [drive.DriveApi.driveAppdataScope];
    final authorization = await account.authorizationClient.authorizeScopes(
      driveScopes,
    );
    final client = authorization.authClient(scopes: driveScopes);
    final driveApi = drive.DriveApi(client);

    // [cite: 964] Mitigación Android: Forzamos la actualización de metadatos antes del listado
    await _requestAndroidMetaDataSync();

    // [cite: 1017] Aplicamos reintentos a la lectura de la lista
    final fileList = await _retryWithBackoff(
      () => driveApi.files.list(
        spaces: 'appDataFolder', // [cite: 996]
        q: "name = '$_backupFileName'",
      ),
    );

    if (fileList.files == null || fileList.files!.isEmpty) {
      return false; // No hay copia de seguridad
    }

    final fileId = fileList.files!.first.id!;

    // [cite: 1017] Aplicamos reintentos a la descarga del archivo multimedia
    final drive.Media fileMedia =
        await _retryWithBackoff(
              () => driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              ),
            )
            as drive.Media;

    final List<int> dataStore = [];
    await for (var data in fileMedia.stream) {
      //  Consumo del stream de bytes seguro
      dataStore.addAll(data);
    }
    final String jsonString = utf8.decode(dataStore);

    await restoreFromJson(jsonString);
    return true;
  }
}
