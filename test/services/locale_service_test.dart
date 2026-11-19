import 'package:faktur_gen/services/locale_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => LocaleService.languageNotifier.value = AppLanguage.id);

  test('trN picks the singular form for one in English', () {
    LocaleService.languageNotifier.value = AppLanguage.en;
    expect(trN('invoice.item_count', 1), '1 item');
    expect(trN('invoice.item_count', 3), '3 items');
    expect(trN('dashboard.see_all', 1), 'See all (1)');
  });
}
