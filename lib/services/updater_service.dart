import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
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
  static const _readTimeout = Duration(seconds: 20);
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
      final response = await request.close().timeout(_readTimeout);
      if (response.statusCode != 200) return null;

      final body =
          await response.transform(utf8.decoder).join().timeout(_readTimeout);
      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) return null;

      final tagName = data['tag_name']?.toString() ?? '';
      final cleanTag = tagName.replaceAll(RegExp(r'^[vV]'), '').trim();
      final releaseName = data['name']?.toString() ?? tagName;
      final bodyText = data['body']?.toString() ?? '';

      // Faktura.apk is arm64; 32-bit-only phones need Faktura-v7a.apk.
      final abis =
          await _channel.invokeListMethod<String>('supportedAbis') ?? const [];
      final wantV7a = !abis.contains('arm64-v8a');
      final asset = (data['assets'] is List ? data['assets'] as List : const [])
          .whereType<Map>()
          .firstWhere((a) {
        final name = a['name']?.toString().toLowerCase() ?? '';
        return name.endsWith('.apk') && name.contains('-v7a') == wantV7a;
      }, orElse: () => const {});

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
    } on TimeoutException {
      return null;
    } on FormatException {
      return null;
    } finally {
      client.close();
    }
  }

  /// Downloads the APK into the app cache and hands it to the system installer.
  /// [onProgress] gets total <= 0 when the server sends no length.
  Future<void> downloadAndInstall({
    required String downloadUrl,
    required String fileName,
    void Function(int received, int total)? onProgress,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(downloadUrl));
      request.headers.set('User-Agent', 'Faktura-App');
      final response = await request.close().timeout(_readTimeout);
      if (response.statusCode != 200) {
        throw HttpException(
            '${tr('update.download_failed')} (${response.statusCode})');
      }

      final total = response.contentLength;
      // getTemporaryDirectory is cacheDir on Android, the FileProvider root.
      final saveFile =
          File('${(await getTemporaryDirectory()).path}/$fileName');
      final sink = saveFile.openWrite();
      var complete = false;
      var received = 0;
      try {
        await for (final chunk in response.timeout(_readTimeout)) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
        }
        complete = true;
      } finally {
        await sink.close();
        if (!complete) await saveFile.delete();
      }

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
  final navigator = Navigator.of(context, rootNavigator: true);

  // Removed by route handle, so a slow or failed check can never pop the
  // page underneath it.
  final loader = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: Center(
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
    ),
  );
  navigator.push(loader);

  AppUpdateInfo? info;
  Object? error;
  StackTrace? stack;
  try {
    info = await updater.checkForUpdate();
  } catch (e, st) {
    error = e;
    stack = st;
  } finally {
    if (loader.isActive) navigator.removeRoute(loader);
  }

  if (context.mounted && (info == null || !info.isNewer) && notifyIfLatest) {
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
  // Unexpected errors (not network) still reach the framework's error log.
  if (error != null) Error.throwWithStackTrace(error, stack!);
  if (!context.mounted || info == null || !info.isNewer) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _AppUpdateDialog(info: info!, updater: updater),
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
  bool _failed = false;

  Future<void> _startUpdate() async {
    setState(() {
      _downloading = true;
      _failed = false;
      _progress = null;
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    return PopScope(
      canPop: !_downloading,
      child: AlertDialog(
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
                  _progress == null
                      ? tr('update.downloading_plain')
                      : tr('update.downloading').replaceAll(
                          '{percent}', '${(_progress! * 100).toInt()}'),
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
              if (_failed) ...[
                const SizedBox(height: 8),
                Text(tr('update.download_failed'),
                    style: TextStyle(color: scheme.error, fontSize: 12)),
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
      ),
    );
  }
}
