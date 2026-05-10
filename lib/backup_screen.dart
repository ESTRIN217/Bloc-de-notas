import 'dart:convert' show utf8;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html; // Para la descarga en Web
import 'backup_service.dart';
import 'l10n/app_localizations.dart';

class BackupSyncScreen extends StatefulWidget {
  const BackupSyncScreen({super.key});

  @override
  State<BackupSyncScreen> createState() => _BackupSyncScreenState();
}

class _BackupSyncScreenState extends State<BackupSyncScreen> {
  final BackupService _backupService = BackupService();
  bool _isGoogleSignIn = false;
  bool _isLoading = false;

  String _lastCloudSync = "Cargando...";
  String _lastLocalSync = "Cargando...";

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
    _loadSyncDates();
  }
  Future<void> _loadSyncDates() async {
    final cloud = await _backupService.getLastCloudSync();
    final local = await _backupService.getLastLocalSync();
    if (mounted) {
      setState(() {
        _lastCloudSync = cloud;
        _lastLocalSync = local;
      });
    }
  }

  Future<void> _checkSignInStatus() async {
    final signedIn = await _backupService.isSignedIn();
    setState(() => _isGoogleSignIn = signedIn);
  }

  // --- LÓGICA DE DRIVE ---
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final account = await _backupService.signIn();
      if (!mounted) return;
      setState(() => _isGoogleSignIn = account != null);
    } catch (e) {
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context)!.errorSign(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _backupToCloud() async {
    setState(() => _isLoading = true);
    try {
      await _backupService.backupToDrive();
      await _loadSyncDates();
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context)!.backupLoaded);
    } catch (e) {
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context)!.errorCloud(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreFromCloud() async {
    setState(() => _isLoading = true);
    try {
      final success = await _backupService.restoreFromDrive();
      await _loadSyncDates();
      if (!mounted) return;
      if (success) {
        _showSnack(AppLocalizations.of(context)!.restoresCloud);
      } else {
        _showSnack(AppLocalizations.of(context)!.restoresCloudempty);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        AppLocalizations.of(context)!.restoredCloudError(e.toString()),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- LÓGICA LOCAL ---
  Future<void> _createLocalBackup() async {
    final jsonString = await _backupService.createBackupJson();
    await _loadSyncDates();
    if (!mounted) return;

    if (kIsWeb) {
      // Magia para Web: Forzar descarga del navegador
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "bloc_notas_backup.json")
        ..click();
      html.Url.revokeObjectUrl(url);
      if (mounted) {
        _showSnack(AppLocalizations.of(context)!.backupDownload);
      }
    } else {
      // En Android, usamos path_provider y SharePlus para guardarlo donde el usuario quiera
      final dir = await getTemporaryDirectory();
      if (!mounted) return;
      final file = File('${dir.path}/bloc_notas_backup.json');
      await file.writeAsString(jsonString);
      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          text: AppLocalizations.of(context)!.backupTLF,
          files: [XFile(file.path)],
        ),
      );
    }
  }

  Future<void> _restoreFromLocal() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        String jsonString;

        if (kIsWeb) {
          // En web los bytes vienen directamente
          jsonString = utf8.decode(result.files.single.bytes!);
        } else {
          // En Android leemos el path del archivo seleccionado
          File file = File(result.files.single.path!);
          jsonString = await file.readAsString();
        }

        await _backupService.restoreFromJson(jsonString);
        await _loadSyncDates();
        if (!mounted) return;
        _showSnack(AppLocalizations.of(context)!.restoredLocal);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context)!.restoredLocalError as String);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.backupSyncTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildCloudSection(colorScheme),
                const SizedBox(height: 24),
                _buildLocalSection(colorScheme),
              ],
            ),
    );
  }

  Widget _buildCloudSection(ColorScheme colorScheme) {
    return Card.outlined(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_outlined,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.cloudBackup,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_isGoogleSignIn)
                  Icon(Icons.check_circle_outlined, color: Colors.green[400]),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _isGoogleSignIn
                  ? AppLocalizations.of(context)!.signing
                  : AppLocalizations.of(context)!.sing_in,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.synchronization(_lastCloudSync),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (!_isGoogleSignIn)
              if (GoogleSignIn.instance.supportsAuthenticate())
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: const Icon(Icons.login_outlined),
                  label: Text(AppLocalizations.of(context)!.connectWithGoogle),
                ),
              )
              else ...<Widget>[
              if (kIsWeb)
    // Usamos 'as dynamic' o la interfaz de plataforma para que el compilador 
    // de Android ignore la implementación específica de web durante el build
    (GoogleSignInPlatform.instance as dynamic).renderButton()
]

            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _backupToCloud,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: Text(AppLocalizations.of(context)!.backup),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _restoreFromCloud,
                      icon: const Icon(Icons.cloud_download_outlined),
                      label: Text(AppLocalizations.of(context)!.restore),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalSection(ColorScheme colorScheme) {
    return Card.outlined(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  color: colorScheme.secondary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.localBackup,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              kIsWeb
                  ? AppLocalizations.of(context)!.downloadBackup
                  : AppLocalizations.of(context)!.backupPhone,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.lastBackup(_lastLocalSync),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _createLocalBackup,
                    icon: Icon(
                      kIsWeb ? Icons.download_outlined : Icons.save_outlined,
                    ),
                    label: Text(
                      kIsWeb
                          ? AppLocalizations.of(context)!.download
                          : AppLocalizations.of(context)!.save,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _restoreFromLocal();
                      // Lógica de file_picker para seleccionar el JSON local
                    },
                    icon: const Icon(Icons.file_open_outlined),
                    label: Text(AppLocalizations.of(context)!.import),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
