import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'locale_service.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseName,
    required this.changelog,
    required this.downloadUrl,
    required this.fileName,
    required this.fileSize,
    required this.isNewer,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseName;
  final String changelog;
  final String? downloadUrl;
  final String? fileName;
  final int? fileSize;
  final bool isNewer;
}

/// Releases are only published as APKs, so updating is Android-only.
bool get updaterSupported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

class UpdaterService {
  UpdaterService({this.repository = 'mohammadraflyy/faktur_gen'});

  /// GitHub repository in `owner/repo` form.
  final String repository;

  static const _channel = MethodChannel('faktur/native');
  static const currentAppVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

  /// Returns null when the release server can't be reached or answers badly.
  Future<AppUpdateInfo?> checkForUpdate(
      {String currentVersion = currentAppVersion}) async {
    if (!updaterSupported) return null;

    final url =
        Uri.parse('https://api.github.com/repos/$repository/releases/latest');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(url);
      request.headers.set('User-Agent', 'Faktura-App');
      request.headers.set('Accept', 'application/vnd.github.v3+json');
      final response = await request.close();
      if (response.statusCode != 200) return null;

      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) return null;

      final tagName = data['tag_name']?.toString() ?? '';
      final cleanTag = tagName.replaceAll(RegExp(r'^[vV]'), '').trim();
      final releaseName = data['name']?.toString() ?? tagName;
      final bodyText = data['body']?.toString() ?? '';

      final apks = (data['assets'] is List ? data['assets'] as List : const [])
          .whereType<Map>()
          .where((a) =>
              a['name']?.toString().toLowerCase().endsWith('.apk') ?? false)
          .toList();
      // Prefer the arm64 build; the -v7a one is for older 32-bit phones.
      final asset = apks.firstWhere(
          (a) => !a['name'].toString().toLowerCase().contains('-v7a'),
          orElse: () => apks.isEmpty ? const {} : apks.first);

      return AppUpdateInfo(
        currentVersion: currentVersion,
        latestVersion: cleanTag.isEmpty ? tagName : cleanTag,
        releaseName: releaseName,
        changelog: bodyText,
        downloadUrl: asset['browser_download_url']?.toString(),
        fileName: asset['name']?.toString(),
        fileSize: (asset['size'] as num?)?.toInt(),
        isNewer: compareVersions(cleanTag, currentVersion) > 0,
      );
    } on IOException {
      return null;
    } on FormatException {
      return null;
    } finally {
      client.close();
    }
  }

  /// Downloads the APK into the app cache and hands it to the system installer.
  Future<void> downloadAndInstall({
    required String downloadUrl,
    required String fileName,
    void Function(int received, int total)? onProgress,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(downloadUrl));
      request.headers.set('User-Agent', 'Faktura-App');
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException(
            '${tr('update.download_failed')} (${response.statusCode})');
      }

      final total = response.contentLength;
      // The FileProvider only shares the app's cache and files dirs.
      final paths = await _channel.invokeMethod<Map<Object?, Object?>>('paths');
      final saveFile = File('${paths!['cacheDir']}/$fileName');
      final sink = saveFile.openWrite();

      var received = 0;
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
      await sink.close();

      await _channel.invokeMethod('installApk', {'path': saveFile.path});
    } finally {
      client.close();
    }
  }

  /// Returns > 0 if v1 > v2, < 0 if v1 < v2, 0 if equal. Ignores a leading
  /// v, any -pre/+build suffix, and pads missing parts with 0.
  static int compareVersions(String v1, String v2) {
    List<int> parts(String v) => v
        .replaceAll(RegExp(r'^[vV]'), '')
        .split(RegExp(r'[-+]'))
        .first
        .split('.')
        .map((s) => int.tryParse(s) ?? 0)
        .toList();
    final p1 = parts(v1);
    final p2 = parts(v2);
    final len = p1.length > p2.length ? p1.length : p2.length;
    for (var i = 0; i < len; i++) {
      final num1 = i < p1.length ? p1[i] : 0;
      final num2 = i < p2.length ? p2[i] : 0;
      if (num1 != num2) return num1.compareTo(num2);
    }
    return 0;
  }
}

/// Checks for a release and walks the user through download and install.
Future<void> promptAppUpdate(BuildContext context,
    {bool notifyIfLatest = true}) async {
  final updater = UpdaterService();

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 16),
              Text(tr('update.checking')),
            ],
          ),
        ),
      ),
    ),
  );

  final info = await updater.checkForUpdate();

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();

  if (info == null || !info.isNewer) {
    if (notifyIfLatest) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr(info == null ? 'update.check_failed' : 'update.latest')),
          content: Text(info == null
              ? tr('update.check_failed_desc')
              : tr('update.latest_desc')
                  .replaceAll('{version}', info.currentVersion)),
          actions: [
            FilledButton(
                autofocus: true,
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr('common.close'))),
          ],
        ),
      );
    }
    return;
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _AppUpdateDialog(info: info, updater: updater),
  );
}

class _AppUpdateDialog extends StatefulWidget {
  const _AppUpdateDialog({required this.info, required this.updater});
  final AppUpdateInfo info;
  final UpdaterService updater;

  @override
  State<_AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<_AppUpdateDialog> {
  double? _progress;
  bool _downloading = false;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0.0;
    });

    try {
      await widget.updater.downloadAndInstall(
        downloadUrl: widget.info.downloadUrl!,
        fileName: widget.info.fileName!,
        onProgress: (received, total) {
          if (mounted && total > 0) {
            setState(() => _progress = received / total);
          }
        },
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.system_update, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
              child: Text(tr('update.title')
                  .replaceAll('{name}', widget.info.releaseName))),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('update.new_version')
                  .replaceAll('{latest}', widget.info.latestVersion)
                  .replaceAll('{current}', widget.info.currentVersion),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (widget.info.changelog.isNotEmpty) ...[
              Text(tr('update.changelog'),
                  style: TextStyle(fontSize: 12, color: muted)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(
                  child: Text(widget.info.changelog,
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_downloading) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 6),
              Text(
                tr('update.downloading').replaceAll(
                    '{percent}', '${((_progress ?? 0) * 100).toInt()}'),
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: scheme.error, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        if (!_downloading) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('update.later')),
          ),
          if (widget.info.downloadUrl != null && widget.info.fileName != null)
            FilledButton.icon(
              onPressed: _startUpdate,
              icon: const Icon(Icons.download, size: 16),
              label: Text(tr('update.download')),
            ),
        ],
      ],
    );
  }
}
