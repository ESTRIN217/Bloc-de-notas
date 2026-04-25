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

  // Instancia del plugin de notificaciones
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool get autoUpdate => _autoUpdate;
  bool get notifications => _notifications;
  String get currentVersion => _currentVersion;
  bool get isChecking => _isChecking;
  
  bool get hasUpdate => !kIsWeb && _latestVersion != null && _latestVersion != _currentVersion;
  String? get latestVersion => _latestVersion;
  String? get latestChangelog => _latestChangelog;
  String? get downloadUrl => _downloadUrl;

  UpdaterProvider() {
    _initNotifications();
    _loadSettings();
    _loadCurrentVersion();
  }

  // --- Inicialización de Notificaciones ---
  Future<void> _initNotifications() async {
    if (kIsWeb) return;

    // Usamos el icono por defecto de la app
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Al tocar la notificación, abre el enlace si existe un payload
        if (response.payload != null) {
          final Uri uri = Uri.parse(response.payload!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
    );

    // Solicitar permisos en Android 13+
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // --- Lógica del Provider ---
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoUpdate = prefs.getBool('auto_update') ?? true;
    _notifications = prefs.getBool('update_notifications') ?? true;
    notifyListeners();
  }

  Future<void> _loadCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version;
    notifyListeners();
  }

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
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir el enlace $_downloadUrl');
    }
  }

  Future<void> checkForUpdates(BuildContext context) async {
    if (kIsWeb) return;
    _isChecking = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('https://api.github.com/repos/ESTRIN217/Bloc-de-notas/releases/latest'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _latestVersion = data['tag_name'].toString().replaceAll('v', '');
        _downloadUrl = data['html_url'];
        _latestChangelog = data['body'];

        if (context.mounted) {
          if (hasUpdate) {
            _showNativeNotification();
          } else {
            _showSnackBar(context, 'Ya tienes la última versión');
          }
        }
      } else {
        if (context.mounted) _showSnackBar(context, 'Error al buscar actualizaciones');
      }
    } catch (e) {
      if (context.mounted) _showSnackBar(context, 'Error de conexión');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> checkUpdateOnStartup() async {
    if (kIsWeb || !_autoUpdate) return;

    _isChecking = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('https://api.github.com/repos/ESTRIN217/Bloc-de-notas/releases/latest'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _latestVersion = data['tag_name'].toString().replaceAll('v', '');
        _downloadUrl = data['html_url'];
        _latestChangelog = data['body'];

        // Solo mostramos la notificación si está habilitada en los ajustes
        if (hasUpdate && _notifications) {
          _showNativeNotification();
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error silencioso al buscar actualizaciones: $e');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  // --- Ejecución de la Notificación Local ---
  Future<void> _showNativeNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'updater_channel_id',
      'Actualizaciones de la app',
      channelDescription: 'Notifica cuando hay una nueva versión disponible',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher', // Asegura que use tu icono de app
      color: Colors.blue, // Puedes cambiar esto al color primario de tu app
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      0, // ID de la notificación
      'Actualización disponible',
      'Versión $_latestVersion',
      platformDetails,
      payload: _downloadUrl, // Pasamos la URL al payload para abrirla al tocar
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}