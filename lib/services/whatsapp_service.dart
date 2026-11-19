import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/phone_utils.dart';

class WhatsAppService {
  /// Shares a PDF with a prefilled message through the system share sheet,
  /// where the user picks WhatsApp. A direct-to-number attachment is not
  /// possible with url_launcher alone.
  static Future<void> sharePdf({
    required Uint8List pdfBytes,
    required String filename,
    required String message,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles([XFile(file.path)], text: message);
  }

  /// Open WhatsApp chat with pre-filled message (no attachment).
  static Future<bool> sendMessage({
    required String phone,
    required String message,
  }) async {
    final normalized = normalizeIndonesianPhone(phone);
    final uri = Uri.parse(
        'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }
}
