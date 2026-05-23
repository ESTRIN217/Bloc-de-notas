import 'dart:convert' show utf8;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html; // Para la descarga en Web
import 'services/backup_service.dart';
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

  Future<void> _handleGoogleSignOut() async {
    setState(() => _isLoading = true);
    try {
      await _backupService.signOut();
      if (!mounted) return;
      setState(() => _isGoogleSignIn = false);
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
      _showSnack(
        AppLocalizations.of(context)!.restoredLocalError(e.toString()),
      );
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
          ? _buildSkeletonBody(colorScheme)
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
  // Bandera temporal para el estado de "Próximamente"
  final bool isComingSoon = true; 

  return Opacity(
    // Si está en "Próximamente", reducimos la opacidad para dar el efecto gris/deshabilitado
    opacity: isComingSoon ? 0.5 : 1.0,
    child: Card.outlined(
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
                  color: isComingSoon ? colorScheme.onSurfaceVariant : colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.cloudBackup,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isComingSoon ? colorScheme.onSurfaceVariant : null,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              // Mensaje dinámico si está deshabilitado o el flujo normal
              isComingSoon 
                  ? "Esta función estará disponible en próximas actualizaciones." // O tu string de l10n
                  : (_isGoogleSignIn 
                      ? AppLocalizations.of(context)!.signing 
                      : AppLocalizations.of(context)!.sing_in),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            // Solo mostramos la última sincronización si no está en modo "Próximamente"
            if (!isComingSoon) ...[
              Text(
                AppLocalizations.of(context)!.synchronization(_lastCloudSync),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Sección de botones o etiqueta de Próximamente
            if (isComingSoon) ...[
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "PRÓXIMAMENTE",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Tu lógica original de botones (SignIn / CloudActions)
              if (!_isGoogleSignIn)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: null, // _handleGoogleSignIn,
                    icon: const Icon(Icons.login_outlined),
                    label: Text(AppLocalizations.of(context)!.connectWithGoogle),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _backupToCloud,
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: Text(AppLocalizations.of(context)!.save),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _restoreFromCloud,
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: Text(AppLocalizations.of(context)!.import),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _handleGoogleSignOut,
                    icon: const Icon(Icons.logout_outlined),
                    label: Text(AppLocalizations.of(context)!.logout),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
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
                  Icons.phone_android_outlined,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.localBackup,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
                    onPressed: _restoreFromLocal,
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

  // Cuerpo completo esquelético que simula la lista de opciones
  Widget _buildSkeletonBody(ColorScheme colorScheme) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.4, end: 0.8),
      duration: const Duration(milliseconds: 1000),
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSkeletonCard(
                colorScheme,
                hasSubtitle: true,
                hasTwoButtons: true,
              ),
              const SizedBox(height: 16),
              _buildSkeletonCard(
                colorScheme,
                hasSubtitle: true,
                hasTwoButtons: true,
              ),
            ],
          ),
        );
      },
    );
  }

  // Molde individual que clona visualmente a Card.outlined
  Widget _buildSkeletonCard(
    ColorScheme colorScheme, {
    required bool hasSubtitle,
    required bool hasTwoButtons,
  }) {
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
            // Fila de Título e Icono
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 140,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Línea de descripción / subtítulo
            Container(
              width: double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (hasSubtitle) ...[
              const SizedBox(height: 8),
              Container(
                width: 200,
                height: 12,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Botones Esqueléticos distribuidos de forma idéntica
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(
                        20,
                      ), // Atributo Stadium de MD3
                    ),
                  ),
                ),
                if (hasTwoButtons) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
