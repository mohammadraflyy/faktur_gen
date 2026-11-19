import 'history_model.dart';

/// Income of one calendar month on the Beranda chart.
class MonthTotal {
  final DateTime month; // first day of the month
  final double total;
  const MonthTotal(this.month, this.total);
}

/// Numbers shown on Beranda, computed from history without any UI.
class DashboardSummary {
  final double unpaidTotal;
  final int unpaidCount;
  final List<HistoryEntry> overdue; // oldest due date first
  final List<MonthTotal> months; // six months, oldest first

  const DashboardSummary._({
    required this.unpaidTotal,
    required this.unpaidCount,
    required this.overdue,
    required this.months,
  });

  factory DashboardSummary.from(List<HistoryEntry> entries, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final unpaid = entries
        .where((e) =>
            e.docType == DocType.invoice &&
            e.paymentStatus == PaymentStatus.unpaid)
        .toList();
    final overdue = unpaid
        .where((e) => e.jatuhTempo != null && e.jatuhTempo!.isBefore(today))
        .toList()
      ..sort((a, b) => a.jatuhTempo!.compareTo(b.jatuhTempo!));
    return DashboardSummary._(
      unpaidTotal: unpaid.fold(0.0, (s, e) => s + e.totalAmount),
      unpaidCount: unpaid.length,
      overdue: overdue,
      months: [
        for (var i = 5; i >= 0; i--)
          _monthTotal(entries, DateTime(now.year, now.month - i)),
      ],
    );
  }

  // Receipts are paid at the counter; invoices count once marked paid.
  // The paid date is not stored, so createdAt decides the month.
  static MonthTotal _monthTotal(List<HistoryEntry> entries, DateTime month) {
    final total = entries
        .where((e) =>
            e.createdAt.year == month.year &&
            e.createdAt.month == month.month &&
            (e.docType == DocType.struk ||
                e.paymentStatus == PaymentStatus.paid))
        .fold(0.0, (s, e) => s + e.totalAmount);
    return MonthTotal(month, total);
  }

  MonthTotal get thisMonth => months.last;
  MonthTotal get lastMonth => months[months.length - 2];

  // UTC dates so a DST shift can never turn 24h into 23h.
  static int daysOverdue(HistoryEntry e, DateTime now) {
    final due = e.jatuhTempo!;
    return DateTime.utc(now.year, now.month, now.day)
        .difference(DateTime.utc(due.year, due.month, due.day))
        .inDays;
  }
}
