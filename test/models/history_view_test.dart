import 'package:faktur_gen/models/history_model.dart';
import 'package:faktur_gen/models/history_view.dart';
import 'package:flutter_test/flutter_test.dart';

HistoryEntry _e(
  String id, {
  DocType type = DocType.invoice,
  PaymentStatus status = PaymentStatus.unpaid,
  String client = 'Klien',
  String number = 'INV-1',
  DateTime? created,
}) {
  final at = created ?? DateTime(2026, 11, 19, 10);
  return HistoryEntry(
    id: id,
    docType: type,
    nomorDokumen: number,
    namaKlien: client,
    totalAmount: 100,
    tanggalDokumen: at,
    createdAt: at,
    paymentStatus: status,
  );
}

List<String> _ids(List<HistoryEntry> list) => list.map((e) => e.id).toList();

void main() {
  final unpaid = _e('a', number: 'INV-001', client: 'Toko Maju');
  final paid = _e('b', number: 'INV-002', client: 'Budi', status: PaymentStatus.paid);
  // Struk is stored with the default unpaid status.
  final struk = _e('c', type: DocType.struk, number: 'STR-0451', client: '');
  final all = [unpaid, paid, struk];

  group('filterHistory', () {
    test('all keeps every entry in order', () {
      expect(_ids(filterHistory(all, HistoryFilter.all, '')), ['a', 'b', 'c']);
    });

    test('invoice and struk tabs filter by type', () {
      expect(_ids(filterHistory(all, HistoryFilter.invoice, '')), ['a', 'b']);
      expect(_ids(filterHistory(all, HistoryFilter.struk, '')), ['c']);
    });

    test('unpaid keeps only unpaid invoices, never struk', () {
      expect(_ids(filterHistory(all, HistoryFilter.unpaid, '')), ['a']);
    });

    test('query matches client or number, ignoring case and spaces', () {
      expect(_ids(filterHistory(all, HistoryFilter.all, '  maju ')), ['a']);
      expect(_ids(filterHistory(all, HistoryFilter.all, 'str-04')), ['c']);
    });

    test('tab and query combine', () {
      expect(filterHistory(all, HistoryFilter.struk, 'budi'), isEmpty);
    });
  });

  group('groupByDay', () {
    test('groups by calendar day, newest day and entry first', () {
      final groups = groupByDay([
        _e('old', created: DateTime(2026, 11, 18, 23, 59)),
        _e('am', created: DateTime(2026, 11, 19, 0, 1)),
        _e('pm', created: DateTime(2026, 11, 19, 15)),
      ]);
      expect(groups.map((g) => g.$1).toList(),
          [DateTime(2026, 11, 19), DateTime(2026, 11, 18)]);
      expect(_ids(groups[0].$2), ['pm', 'am']);
      expect(_ids(groups[1].$2), ['old']);
    });

    test('empty input gives no groups', () {
      expect(groupByDay([]), isEmpty);
    });
  });
}
