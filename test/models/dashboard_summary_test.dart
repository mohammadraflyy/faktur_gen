import 'package:faktur_gen/models/dashboard_summary.dart';
import 'package:faktur_gen/models/history_model.dart';
import 'package:flutter_test/flutter_test.dart';

HistoryEntry _e({
  DocType type = DocType.invoice,
  PaymentStatus status = PaymentStatus.unpaid,
  double amount = 100,
  DateTime? created,
  DateTime? due,
}) {
  final at = created ?? DateTime(2026, 11, 1);
  return HistoryEntry(
    id: '$amount-$at',
    docType: type,
    nomorDokumen: 'INV-$amount',
    namaKlien: 'Klien',
    totalAmount: amount,
    tanggalDokumen: at,
    createdAt: at,
    paymentStatus: status,
    jatuhTempo: due,
  );
}

void main() {
  final now = DateTime(2026, 11, 19, 15);

  test('unpaid counts only unpaid invoices', () {
    final s = DashboardSummary.from([
      _e(amount: 100),
      _e(amount: 200, status: PaymentStatus.paid),
      _e(amount: 300, type: DocType.struk),
    ], now);
    expect(s.unpaidTotal, 100);
    expect(s.unpaidCount, 1);
  });

  test('overdue = unpaid invoices due before today, oldest first', () {
    final s = DashboardSummary.from([
      _e(amount: 1, due: DateTime(2026, 11, 10)),
      _e(amount: 2, due: DateTime(2026, 11, 5)),
      _e(amount: 3, due: DateTime(2026, 11, 19)),
      _e(amount: 4),
      _e(amount: 5, status: PaymentStatus.paid, due: DateTime(2026, 11, 1)),
      _e(amount: 6, type: DocType.struk, due: DateTime(2026, 11, 1)),
    ], now);
    expect(s.overdue.map((e) => e.totalAmount), [2, 1]);
  });

  test('daysOverdue counts calendar days', () {
    final e = _e(due: DateTime(2026, 11, 14, 23));
    expect(DashboardSummary.daysOverdue(e, now), 5);
  });

  test('months: six, oldest first, income = struk + paid invoices', () {
    final s = DashboardSummary.from([
      _e(amount: 300, type: DocType.struk, created: DateTime(2026, 11, 2)),
      _e(amount: 200, status: PaymentStatus.paid, created: DateTime(2026, 11, 3)),
      _e(amount: 100, created: DateTime(2026, 11, 4)),
      _e(amount: 50, status: PaymentStatus.paid, created: DateTime(2026, 10, 9)),
      _e(amount: 7, type: DocType.struk, created: DateTime(2026, 5, 9)),
    ], now);
    expect(s.months, hasLength(6));
    expect(s.months.first.month, DateTime(2026, 6));
    expect(s.thisMonth.total, 500);
    expect(s.lastMonth.total, 50);
    expect(s.months.fold<double>(0, (a, m) => a + m.total), 550);
  });

  test('month counts documents by type, any payment status', () {
    final s = DashboardSummary.from([
      _e(amount: 100, created: DateTime(2026, 11, 2)),
      _e(amount: 200, status: PaymentStatus.paid, created: DateTime(2026, 11, 3)),
      _e(amount: 300, type: DocType.struk, created: DateTime(2026, 11, 4)),
      _e(amount: 400, type: DocType.struk, created: DateTime(2026, 11, 5)),
    ], now);
    expect(s.thisMonth.invoices, 2);
    expect(s.thisMonth.struks, 2);
    expect(s.thisMonth.total, 900);
  });

  test('January wraps to the previous year', () {
    final s = DashboardSummary.from([
      _e(amount: 40, type: DocType.struk, created: DateTime(2026, 12, 20)),
    ], DateTime(2027, 1, 5));
    expect(s.months.first.month, DateTime(2026, 8));
    expect(s.lastMonth.month, DateTime(2026, 12));
    expect(s.lastMonth.total, 40);
  });
}
