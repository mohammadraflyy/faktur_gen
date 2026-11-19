import 'history_model.dart';

/// Filters on Riwayat; the order is the order of the tabs.
enum HistoryFilter { all, invoice, struk, unpaid }

/// Entries matching [filter] whose client or number contains [query].
List<HistoryEntry> filterHistory(
    List<HistoryEntry> entries, HistoryFilter filter, String query) {
  final q = query.trim().toLowerCase();
  return entries.where((e) {
    final inTab = switch (filter) {
      HistoryFilter.all => true,
      HistoryFilter.invoice => e.docType == DocType.invoice,
      HistoryFilter.struk => e.docType == DocType.struk,
      // Struk is stored as unpaid but is always settled on the spot.
      HistoryFilter.unpaid => e.docType == DocType.invoice &&
          e.paymentStatus == PaymentStatus.unpaid,
    };
    return inTab &&
        (q.isEmpty ||
            e.nomorDokumen.toLowerCase().contains(q) ||
            e.namaKlien.toLowerCase().contains(q));
  }).toList();
}

/// Entries grouped by the calendar day they were created, newest first.
List<(DateTime, List<HistoryEntry>)> groupByDay(List<HistoryEntry> entries) {
  final sorted = [...entries]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final groups = <DateTime, List<HistoryEntry>>{};
  for (final e in sorted) {
    final c = e.createdAt;
    groups.putIfAbsent(DateTime(c.year, c.month, c.day), () => []).add(e);
  }
  return [for (final g in groups.entries) (g.key, g.value)];
}
