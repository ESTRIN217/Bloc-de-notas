import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class UpdaterProvider with ChangeNotifier {
  bool _autoUpdate = false;
  bool _notifications = false;
  String _currentVersion = 'Cargando...';
  bool _isChecking = false;

  String? _latestVersion;
  String? _latestChangelog;
  String? _downloadUrl;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // --- Getters ---
  bool get autoUpdate => _autoUpdate;
  bool get notifications => _notifications;
  String get currentVersion => _currentVersion;
  bool get isChecking => _isChecking;
  
  bool get hasUpdate => !kIsWeb && _latestVersion != null && _latestVersion != _currentVersion;
  String? get latestVersion => _latestVersion;
  String? get latestChangelog => _latestChangelog;
  String? get downloadUrl => _downloadUrl;

  UpdaterProvider() {
    _initProvider();
  }

  Future<void> _initProvider() async {
    // 1. Inicializar Notificaciones
    await _initNotifications();

    // 2. Obtener versión real de la app
    final packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version;

    // 3. Cargar ajustes y caché de actualización
    final prefs = await SharedPreferences.getInstance();
    _autoUpdate = prefs.getBool('auto_update') ?? true;
    _notifications = prefs.getBool('update_notifications') ?? true;
    
    _latestVersion = prefs.getString('cached_latest_version');
    _latestChangelog = prefs.getString('cached_latest_changelog');
    _downloadUrl = prefs.getString('cached_download_url');

    notifyListeners();

    // 4. Lógica: Si ya estamos actualizados (o no hay datos), preguntar a GitHub
    if (_latestVersion == null || _latestVersion == _currentVersion) {
      if (_autoUpdate) checkUpdateOnStartup();
    }
  }

  Future<void> _initNotifications() async {
    if (kIsWeb) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    // Combinar ambas
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    // Corregido: Usamos el parámetro posicional para las configuraciones
    await _notificationsPlugin.initialize(
      // DEBES poner el nombre 'initializationSettings:' antes de la variable
      settings: initializationSettings,

      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          final Uri uri = Uri.parse(response.payload!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
    );

    // Permisos para Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> _saveUpdateToCache(String version, String? changelog, String? url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_latest_version', version);
    await prefs.setString('cached_latest_changelog', changelog ?? '');
    await prefs.setString('cached_download_url', url ?? '');
  }

  // --- Ajustes ---
  void toggleAutoUpdate(bool value) async {
    _autoUpdate = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_update', value);
    notifyListeners();
  }

  void toggleNotifications(bool value) async {
    _notifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('update_notifications', value);
    notifyListeners();
  }

  Future<void> launchDownloadUrl() async {
    if (_downloadUrl == null) return;
    final Uri uri = Uri.parse(_downloadUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // --- Lógica de Búsqueda ---
  Future<void> checkForUpdates(BuildContext context) async {
    if (kIsWeb) return;
    _isChecking = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/ESTRIN217/Bloc-de-notas/releases/latest'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _latestVersion = data['tag_name'].toString().replaceAll('v', '');
        _downloadUrl = data['html_url'];
        _latestChangelog = data['body'];
        
        await _saveUpdateToCache(_latestVersion!, _latestChangelog, _downloadUrl);

        if (context.mounted) {
          if (hasUpdate) {
            _showNativeNotification();
          } else {
            _showSnackBar(context, 'Ya tienes la última versión');
          }
        }
      }
    } catch (e) {
      if (context.mounted) _showSnackBar(context, 'Error de conexión');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> checkUpdateOnStartup() async {
    if (kIsWeb) return;
    try {
      final response = await http.get(Uri.parse('https://api.github.com/repos/ESTRIN217/Bloc-de-notas/releases/latest'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newVersion = data['tag_name'].toString().replaceAll('v', '');

        if (newVersion != _latestVersion) {
          _latestVersion = newVersion;
          _downloadUrl = data['html_url'];
          _latestChangelog = data['body'];
          await _saveUpdateToCache(_latestVersion!, _latestChangelog, _downloadUrl);
          
          if (hasUpdate && _notifications) {
            _showNativeNotification();
          }
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error silencioso: $e');
    }
  }

  // --- Ejecución de la Notificación ---
  Future<void> _showNativeNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'updater_channel_id',
          'Actualizaciones de la app',
          channelDescription:
              'Notifica cuando hay una nueva versión disponible',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher', // Asegura que use tu icono de app
          color: Colors.blue, // Puedes cambiar esto al color primario de tu app
        );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // Corregido: Parámetros posicionales para id, title, body y notificationDetails
    await _notificationsPlugin.show(
      id: 0, // ID de la notificación
      title: 'Actualización disponible',
      body: 'Versión $_latestVersion',
      notificationDetails: platformDetails,
      payload: _downloadUrl, // Pasamos la URL al payload para abrirla al tocar
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}