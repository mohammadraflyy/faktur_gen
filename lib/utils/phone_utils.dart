/// Normalize Indonesian phone number for WhatsApp API.
/// Converts leading 0 to 62, ensures country code prefix.
String normalizeIndonesianPhone(String raw) {
  var phone = raw.replaceAll(RegExp(r'[\s\-()]+'), '');
  if (phone.startsWith('0')) {
    phone = '62${phone.substring(1)}';
  } else if (!phone.startsWith('+') && !phone.startsWith('62')) {
    phone = '62$phone';
  }
  return phone.replaceAll('+', '');
}
