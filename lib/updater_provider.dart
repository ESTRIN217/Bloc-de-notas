import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class UpdaterProvider with ChangeNotifier {
  bool _autoUpdate = false;
  bool _notifications = false;
  String _currentVersion = 'Cargando...';
  bool _isChecking = false;

  bool get autoUpdate => _autoUpdate;
  bool get notifications => _notifications;
  String get currentVersion => _currentVersion;
  bool get isChecking => _isChecking;

  UpdaterProvider() {
    _loadSettings();
    _loadCurrentVersion();
  }

  // Cargar preferencias guardadas
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoUpdate = prefs.getBool('auto_update') ?? true;
    _notifications = prefs.getBool('update_notifications') ?? true;
    notifyListeners();
  }

  // Obtener la versión real de la app (desde pubspec.yaml)
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
  
Future<void> _launchUrl(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('No se pudo abrir el enlace $url');
  }
}

Future<void> checkForUpdates(BuildContext context) async {
  _isChecking = true;
  notifyListeners();

  try {
    final response = await http.get(Uri.parse('https://api.github.com/repos/ESTRIN217/Bloc-de-notas/releases/latest'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final latestVersion = data['tag_name'].toString().replaceAll('v', '');
      final downloadUrl = data['html_url']; // Esta es la URL del release en GitHub

      if (context.mounted) {
        if (latestVersion != _currentVersion) {
          // Mostramos un SnackBar con un botón de "Descargar"
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nueva versión $latestVersion disponible'),
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'DESCARGAR',
                onPressed: () => _launchUrl(downloadUrl),
              ),
            ),
          );
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

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  // Método para buscar actualizaciones silenciosamente al iniciar la app
  Future<void> checkUpdateOnStartup(BuildContext context) async {
    // 1. Si es web, cancelamos la ejecución inmediatamente
    if (kIsWeb) return;

    // 2. Si el usuario desactivó la búsqueda automática, cancelamos
    if (!_autoUpdate) return;

    _isChecking = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('https://api.github.com/repos/ESTRIN217/Bloc-de-notas/releases/latest'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['tag_name'].toString().replaceAll('v', '');
        final downloadUrl = data['html_url']; 

        // 3. Verificamos si hay una nueva versión
        if (context.mounted && latestVersion != _currentVersion) {
          
          // 4. Respetamos si el usuario quiere recibir la notificación (SnackBar)
          if (_notifications) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Nueva versión $latestVersion disponible'),
                duration: const Duration(seconds: 10),
                action: SnackBarAction(
                  label: 'DESCARGAR',
                  onPressed: () => _launchUrl(downloadUrl), // Asumo que tienes este método
                ),
              ),
            );
          }
        }
        // Nota: Si YA tienes la última versión, NO mostramos nada para no ser molestos al inicio.
      }
    } catch (e) {
      // Como es un proceso en segundo plano al inicio, fallar silenciosamente es la mejor opción.
      if (kDebugMode) {
        print('Error silencioso al buscar actualizaciones en el inicio: $e');
      }
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }
}