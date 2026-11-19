# UI Refresh Tahap 2 (Beranda + Form Invoice) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tata ulang Beranda (mockup 01) dan form invoice pola A (mockup 02):
- Beranda menjawab "siapa yang belum bayar".
- Form invoice jadi satu halaman yang dibaca seperti invoice-nya.
- Item diubah lewat sheet, total menempel di bawah.

**Architecture:**
- Hitungan Beranda dipindah ke kelas murni `DashboardSummary`, supaya bisa dites tanpa Firebase.
- Tiga widget bersama baru: `StatusLabel`, `ItemEditSheet`, `TotalBar`. Masing-masing akan dipakai ≥2 layar (struk di tahap 3, riwayat di tahap 4).
- Form invoice menyimpan item di `ValueNotifier<List<ItemFaktur>>`, dan total di `ValueNotifier<double>` yang dihitung ulang dari `FakturModel.totalTagihan`.
- Mengetik terjadi di dalam sheet, jadi halaman tidak `setState` saat mengetik.

**Tech Stack:** Flutter (SDK di `C:\flutter`, tidak ada di PATH), Material 3, `intl`, `flutter_test`.

Spec: `docs/superpowers/specs/2026-11-19-ui-refresh-design.md`, bagian "Beranda", "Form invoice, pola A", dan "Gerak dan kehalusan". Mockup: `docs/mockups/01-dashboard.svg`, `docs/mockups/02-invoice-form.svg`.

## Global Constraints

- Tidak ada package baru.
- Font tetap Inter.
- Aksen dari `colorScheme.primary`: biru #2563EB (terang) / #60A5FA (gelap).
- Status merah lewat `AppColors.errorFor(brightness)`: #B91C1C terang (6.47:1), #F87171 gelap (6.82:1). Sudah dicek.
- Teks memakai `textTheme` tahap 1:
  - `displaySmall` 32/700: angka utama
  - `headlineSmall` 22/700: judul halaman
  - `titleMedium` 17/600: judul bagian
  - `titleSmall` 15/600: judul baris
  - `bodyLarge`/`bodyMedium` 15/400
  - `bodySmall` 13/400 abu-abu
- Tidak ada `GoogleFonts.*()` baru dan tidak ada `fontSize` literal baru.
- Tanpa kartu bergaris. Bagian dipisah jarak + `Divider(height: 1)`.
- Status = titik + teks berwarna (`StatusLabel`), tidak pernah warna saja.
- Satu tombol utama per layar.
- Area sentuh ≥ 48dp.
- Semua teks baru lewat `tr()` di `lib/services/locale_service.dart`:
  - Format `'key': ['id', 'en']`.
  - Entri baru ditambah sebelum `};` penutup map `_strings` (baris ~370).
  - Teks dengan angka/nama memakai placeholder `{n}`, `{name}`, `{tax}`, lalu `.replaceAll(...)`, sama seperti `update.downloading`.
- Tanggal diformat dengan locale `LocaleService.isEn ? 'en_US' : 'id_ID'`.
- Animasi: kalau `MediaQuery.disableAnimationsOf(context)` true, durasi `Duration.zero`.
- SnackBar dengan tombol Urungkan wajib `persist: false` dan `duration: const Duration(seconds: 4)`. Di SDK lokal, SnackBar yang punya `action` default-nya tidak pernah hilang sendiri (`snack_bar.dart:461-470`).
- Komentar kode mengikuti gaya file: singkat, menjelaskan alasan. Tanpa emoji, tanpa kode mati, tanpa kode yang dikomentari.
- Commit: subjek pendek konvensional, tanpa trailer `Co-Authored-By` dan tanpa menyebut AI.
- Perintah Flutter: `/c/flutter/bin/flutter` (Git Bash) atau `C:\flutter\bin\flutter` (PowerShell).
- Baseline: `flutter test` = 95 lulus. Catat jumlah issue `flutter analyze` di awal Task 1. Di akhir tahap tidak boleh ada issue baru.

## Keputusan yang menyimpang dari spec / perlu diketahui

- **Lingkup:** atas permintaan user, rencana ini menggabungkan:
  - Beranda (spec tahap 4, bagian Beranda saja)
  - form invoice (spec tahap 2)
- **Layar "Setelah PDF jadi" (mockup 03 kanan) tidak termasuk.** Layar itu butuh keputusan soal kirim WhatsApp dan pengganti dialog pengingat, jadi dibuat di rencana terpisah. Dialog pengingat dan `PdfPreviewPage` tetap seperti sekarang.
- **"Masuk" per bulan** = struk + invoice berstatus lunas, dikelompokkan per `createdAt`. Tanggal pelunasan tidak disimpan di `HistoryEntry`. Grafik lama menjumlah semua dokumen, termasuk yang belum dibayar.
- **Lewat jatuh tempo** dihitung per hari kalender (jatuh tempo sebelum hari ini), bukan per jam seperti kode lama (`dashboard_page.dart:101-105`).
- **Banner toko di Beranda dihapus** (sesuai spec). Kalau nama toko kosong:
  - judul Beranda jadi "Faktura"
  - form invoice menampilkan satu baris teks "Nama toko belum diisi. Lengkapi di Pengaturan."
- **Stepper jumlah** naik/turun 1, minimum 1. Item lama dengan jumlah pecahan (mis. 1,5) tetap tampil dan tersimpan, tapi tidak bisa diubah ke pecahan baru lewat sheet.
- **Grafik mini tidak bisa di-tap**, dan detail per bulan lama (`_buildChartDetail`) dihapus. Mockup menyebut "tap untuk detail", tapi spec tidak memintanya.
- **Pengukuran performa DevTools** (spec, "Gerak dan kehalusan") harus dijalankan user di HP dalam profile mode, karena executor tidak bisa. Lihat "Cek manual".

## File Structure

| File | Perubahan |
|---|---|
| `lib/models/dashboard_summary.dart` (baru) | `DashboardSummary`, `MonthTotal`: belum dibayar, lewat jatuh tempo, total masuk 6 bulan |
| `lib/widgets/status_label.dart` (baru) | `StatusLabel`: titik + teks berwarna |
| `lib/widgets/item_edit_sheet.dart` (baru) | `showItemEditSheet`, `ItemEditSheet`, `ItemEditResult` |
| `lib/widgets/total_bar.dart` (baru) | `TotalBar`: total menempel di bawah + tombol utama dengan status sibuk |
| `lib/pages/dashboard_page.dart` | ditulis ulang |
| `lib/pages/main_navigation.dart` | Beranda dimuat ulang setelah halaman buat dokumen ditutup |
| `lib/pages/faktur_page.dart` | pola A: header, baris klien/jatuh tempo/item/pajak+catatan, sheet, `ValueNotifier`, `TotalBar`, `tr()` |
| `lib/services/locale_service.dart` | kunci baru `dashboard.*`, `item.*`, `invoice.*`, `common.*` |
| `test/models/dashboard_summary_test.dart`, `test/widgets/status_label_test.dart`, `test/widgets/item_edit_sheet_test.dart`, `test/widgets/total_bar_test.dart` (baru) | test |

---

### Task 1: `DashboardSummary`

**Files:**
- Create: `lib/models/dashboard_summary.dart`
- Test: `test/models/dashboard_summary_test.dart`

**Interfaces:**
- Consumes: `HistoryEntry`, `DocType`, `PaymentStatus` dari `lib/models/history_model.dart`. Field yang dipakai: `docType`, `paymentStatus`, `totalAmount`, `createdAt`, `jatuhTempo`.
- Produces:
  - `class MonthTotal { final DateTime month; final double total; }`
  - `class DashboardSummary`:
    - `factory DashboardSummary.from(List<HistoryEntry> entries, DateTime now)`
    - field `double unpaidTotal`, `int unpaidCount`, `List<HistoryEntry> overdue`, `List<MonthTotal> months`
    - getter `MonthTotal thisMonth`, `MonthTotal lastMonth`
    - `static int daysOverdue(HistoryEntry e, DateTime now)`

- [ ] **Step 1: Catat baseline analyze**

Run: `/c/flutter/bin/flutter analyze 2>&1 | tail -2`
Catat jumlah "N issues found" di laporan task.

- [ ] **Step 2: Tulis test yang gagal**

`test/models/dashboard_summary_test.dart`:

```dart
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

  test('January wraps to the previous year', () {
    final s = DashboardSummary.from([
      _e(amount: 40, type: DocType.struk, created: DateTime(2026, 12, 20)),
    ], DateTime(2027, 1, 5));
    expect(s.months.first.month, DateTime(2026, 8));
    expect(s.lastMonth.month, DateTime(2026, 12));
    expect(s.lastMonth.total, 40);
  });
}
```

- [ ] **Step 3: Jalankan, pastikan gagal**

Run: `/c/flutter/bin/flutter test test/models/dashboard_summary_test.dart`
Expected: FAIL, `dashboard_summary.dart` tidak ditemukan.

- [ ] **Step 4: Implementasi**

`lib/models/dashboard_summary.dart`:

```dart
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
```

- [ ] **Step 5: Jalankan, pastikan lulus**

Run: `/c/flutter/bin/flutter test test/models/dashboard_summary_test.dart`
Expected: 5 test PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/models/dashboard_summary.dart test/models/dashboard_summary_test.dart
git commit -m "feat: compute dashboard summary from history"
```

---

### Task 2: `StatusLabel`

**Files:**
- Create: `lib/widgets/status_label.dart`
- Test: `test/widgets/status_label_test.dart`

**Interfaces:**
- Produces: `StatusLabel({required String text, required Color color})`.

- [ ] **Step 1: Tulis test yang gagal**

`test/widgets/status_label_test.dart`:

```dart
import 'package:faktur_gen/widgets/status_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a dot and the text in the status color', (tester) async {
    const red = Color(0xFFB91C1C);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StatusLabel(text: 'lewat 5 hari', color: red)),
    ));

    final text = tester.widget<Text>(find.text('lewat 5 hari'));
    expect(text.style?.color, red);

    final dot = find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).shape == BoxShape.circle &&
        (w.decoration as BoxDecoration).color == red);
    expect(dot, findsOneWidget);
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `/c/flutter/bin/flutter test test/widgets/status_label_test.dart`
Expected: FAIL, file tidak ditemukan.

- [ ] **Step 3: Implementasi**

`lib/widgets/status_label.dart`:

```dart
import 'package:flutter/material.dart';

/// Status as a dot plus colored text, so it never relies on color alone.
class StatusLabel extends StatelessWidget {
  final String text;
  final Color color;
  const StatusLabel({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: color, fontWeight: FontWeight.w600);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: style)),
      ],
    );
  }
}
```

- [ ] **Step 4: Jalankan, pastikan lulus**

Run: `/c/flutter/bin/flutter test test/widgets/status_label_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/status_label.dart test/widgets/status_label_test.dart
git commit -m "feat: add StatusLabel dot-and-text widget"
```

---

### Task 3: Beranda baru

**Files:**
- Modify (tulis ulang seluruh file): `lib/pages/dashboard_page.dart`
- Modify: `lib/services/locale_service.dart` (tambah kunci)

**Interfaces:**
- Consumes:
  - `DashboardSummary`, `MonthTotal` (Task 1)
  - `StatusLabel` (Task 2)
  - `MainNavigation.goToTab(BuildContext, int)`: 1 = Riwayat, 2 = Pengingat
  - `FakturPage()`
  - `HistoryService.load()`, `SettingsService.load()`, `ReminderService.getUpcoming()`
  - `AppColors.errorFor(Brightness)` dari `lib/main.dart`
- Produces: `DashboardPage`, konstruktor tetap `const DashboardPage({super.key})`.

Halaman ini tidak punya widget test karena `HistoryService` memanggil Firebase. Logika bercabangnya sudah dites di Task 1.

- [ ] **Step 1: Tambah kunci locale**

Di `lib/services/locale_service.dart`, sisipkan sebelum `};` penutup `_strings`:

```dart
  'dashboard.unpaid_heading': ['Belum dibayar', 'Unpaid'],
  'dashboard.invoice_count': ['{n} invoice', '{n} invoices'],
  'dashboard.overdue_count': ['{n} lewat jatuh tempo', '{n} overdue'],
  'dashboard.days_late': ['lewat {n} hari', '{n} days overdue'],
  'dashboard.see_all': ['Lihat semua ({n})', 'See all ({n})'],
  'dashboard.income': ['masuk', 'received'],
  'dashboard.six_months': ['6 bulan', '6 months'],
  'dashboard.reminder_prefix': ['Pengingat: {name}', 'Reminder: {name}'],
  'dashboard.empty': ['Belum ada invoice. Buat yang pertama.', 'No invoices yet. Create your first one.'],
  'dashboard.create_invoice': ['Buat invoice', 'Create invoice'],
  'dashboard.load_failed': ['Data tidak bisa dimuat. Periksa koneksi.', 'Data could not be loaded. Check your connection.'],
  'dashboard.retry': ['Coba lagi', 'Try again'],
  'dashboard.loading': ['Memuat…', 'Loading…'],
```

Kunci `dashboard.*` lama tidak dihapus. Membersihkan kunci yang tak terpakai di luar cakupan.

- [ ] **Step 2: Tulis ulang `lib/pages/dashboard_page.dart`**

Ganti seluruh isi file dengan:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/dashboard_summary.dart';
import '../models/history_model.dart';
import '../models/reminder_model.dart';
import '../models/settings_model.dart';
import '../services/history_service.dart';
import '../services/locale_service.dart';
import '../services/reminder_service.dart';
import '../services/settings_service.dart';
import '../widgets/status_label.dart';
import 'faktur_page.dart';
import 'main_navigation.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<HistoryEntry> _entries = [];
  List<ReminderModel> _reminders = [];
  SettingsModel _settings = SettingsModel();
  bool _isLoading = true;
  bool _showLoadingText = false;
  bool _failed = false;
  Timer? _loadingTimer;

  NumberFormat get _currency => NumberFormat.currency(
        locale: _settings.currencyLocale,
        symbol: _settings.currencySymbol,
        decimalDigits: 0,
      );

  String get _dateLocale => LocaleService.isEn ? 'en_US' : 'id_ID';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _loadingTimer?.cancel();
    // A fast load should not flash a loading message.
    _loadingTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _isLoading) setState(() => _showLoadingText = true);
    });
    try {
      final results = await Future.wait([
        HistoryService.load(),
        SettingsService.load(),
        ReminderService.getUpcoming(),
      ]);
      if (!mounted) return;
      setState(() {
        _entries = results[0] as List<HistoryEntry>;
        _settings = results[1] as SettingsModel;
        _reminders = results[2] as List<ReminderModel>;
        _isLoading = false;
        _failed = false;
      });
    } catch (e) {
      debugPrint('[Dashboard] load failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _failed = true;
        });
      }
    } finally {
      _loadingTimer?.cancel();
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _showLoadingText = false;
      _failed = false;
    });
    _load();
  }

  Future<void> _createInvoice() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const FakturPage()));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: _showLoadingText
              ? Text(tr('dashboard.loading'), style: theme.textTheme.bodySmall)
              : const SizedBox.shrink(),
        ),
      );
    }
    if (_failed) {
      return Scaffold(
        body: Center(
          child: _message(
              theme, tr('dashboard.load_failed'), tr('dashboard.retry'), _retry),
        ),
      );
    }

    final summary = DashboardSummary.from(_entries, DateTime.now());
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              _header(theme),
              const SizedBox(height: 40),
              if (_entries.isEmpty)
                _message(theme, tr('dashboard.empty'),
                    tr('dashboard.create_invoice'), _createInvoice)
              else ...[
                _unpaid(theme, summary),
                const SizedBox(height: 40),
                _income(theme, summary),
              ],
              if (_reminders.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Divider(height: 1),
                _nextReminder(theme, _reminders.first),
                const Divider(height: 1),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _message(
      ThemeData theme, String text, String action, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text,
              style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DateFormat('EEEE, d MMMM', _dateLocale).format(DateTime.now()),
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          _settings.namaToko.isEmpty ? tr('dashboard.title') : _settings.namaToko,
          style: theme.textTheme.headlineSmall,
        ),
      ],
    );
  }

  Widget _unpaid(ThemeData theme, DashboardSummary s) {
    final now = DateTime.now();
    final error = AppColors.errorFor(theme.brightness);
    final shown = s.overdue.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('dashboard.unpaid_heading'), style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(_currency.format(s.unpaidTotal),
            style: theme.textTheme.displaySmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
                tr('dashboard.invoice_count')
                    .replaceAll('{n}', '${s.unpaidCount}'),
                style: theme.textTheme.bodySmall),
            if (s.overdue.isNotEmpty)
              StatusLabel(
                text: tr('dashboard.overdue_count')
                    .replaceAll('{n}', '${s.overdue.length}'),
                color: error,
              ),
          ],
        ),
        if (shown.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Divider(height: 1),
          for (final e in shown) ...[
            _overdueRow(theme, e, now, error),
            const Divider(height: 1),
          ],
        ],
        if (s.unpaidCount > shown.length)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => MainNavigation.goToTab(context, 1),
              child: Text(tr('dashboard.see_all')
                  .replaceAll('{n}', '${s.unpaidCount}')),
            ),
          ),
      ],
    );
  }

  Widget _overdueRow(
      ThemeData theme, HistoryEntry e, DateTime now, Color error) {
    return InkWell(
      onTap: () => MainNavigation.goToTab(context, 1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.namaKlien.isEmpty ? e.nomorDokumen : e.namaKlien,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(e.nomorDokumen, style: theme.textTheme.bodySmall),
                      StatusLabel(
                        text: tr('dashboard.days_late').replaceAll('{n}',
                            '${DashboardSummary.daysOverdue(e, now)}'),
                        color: error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(_currency.format(e.totalAmount),
                style: theme.textTheme.titleSmall),
          ],
        ),
      ),
    );
  }

  Widget _income(ThemeData theme, DashboardSummary s) {
    final monthName = DateFormat('MMMM', _dateLocale);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(monthName.format(s.thisMonth.month),
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_currency.format(s.thisMonth.total),
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                '${tr('dashboard.income')} · '
                '${monthName.format(s.lastMonth.month)} '
                '${_currency.format(s.lastMonth.total)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _miniBars(theme, s.months),
      ],
    );
  }

  Widget _miniBars(ThemeData theme, List<MonthTotal> months) {
    final max = months.fold<double>(0, (m, e) => e.total > m ? e.total : m);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.12);
    return Semantics(
      label: tr('dashboard.six_months'),
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < months.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Container(
                    width: 16,
                    height: max == 0 ? 4 : 4 + 44 * months[i].total / max,
                    decoration: BoxDecoration(
                      color: i == months.length - 1
                          ? theme.colorScheme.primary
                          : muted,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(tr('dashboard.six_months'), style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _nextReminder(ThemeData theme, ReminderModel r) {
    return InkWell(
      onTap: () => MainNavigation.goToTab(context, 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                tr('dashboard.reminder_prefix')
                    .replaceAll('{name}', r.contactName),
                style: theme.textTheme.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Text(DateFormat('d MMM', _dateLocale).format(r.reminderDate),
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
```

Catatan:
- `_load()` tidak memanggil `setState` sebelum `await`, karena dipanggil dari `initState`.
- Untuk memuat ulang setelah gagal, pakai `_retry()`.

- [ ] **Step 3: Analyze + test**

Run: `/c/flutter/bin/flutter analyze lib/pages/dashboard_page.dart lib/services/locale_service.dart`
Expected: No issues found.
Run: `/c/flutter/bin/flutter test`
Expected: semua lulus (95 + test Task 1–2).

- [ ] **Step 4: Commit**

```bash
git add lib/pages/dashboard_page.dart lib/services/locale_service.dart
git commit -m "feat: redesign Beranda around unpaid invoices"
```

---

### Task 4: Beranda dimuat ulang setelah dokumen dibuat

**Files:**
- Modify: `lib/pages/main_navigation.dart` (`_showCreateSheet` ~baris 122-190, `build` ~baris 214-217)

**Interfaces:**
- Consumes: `FakturPage`, `StrukPage`, dan `_loadDueCount()` yang sudah ada.
- Produces: tidak ada API baru.

- [ ] **Step 1: Tambah field generasi**

Di `_MainNavigationState`, setelah `Timer? _updateCheckTimer;`:

```dart
  // Bumped after a create flow closes so the tab remounts and reloads.
  int _pageGeneration = 0;
```

- [ ] **Step 2: Tambah method pembuka halaman buat dokumen**

Di `_MainNavigationState`, sebelum `void _showCreateSheet()`:

```dart
  Future<void> _openCreatePage(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (!mounted) return;
    setState(() => _pageGeneration++);
    _loadDueCount();
  }
```

- [ ] **Step 3: Pakai di dua opsi sheet**

Di `_showCreateSheet`, ganti `onTap` opsi Invoice:

```dart
                      onTap: () {
                        Navigator.pop(context);
                        _openCreatePage(const FakturPage());
                      },
```

dan `onTap` opsi Struk:

```dart
                      onTap: () {
                        Navigator.pop(context);
                        _openCreatePage(const StrukPage());
                      },
```

- [ ] **Step 4: Kunci tab ikut generasi**

Di `build`, ganti:

```dart
      child: KeyedSubtree(
        key: ValueKey(_currentIndex),
        child: _pages[_currentIndex],
      ),
```

dengan:

```dart
      child: KeyedSubtree(
        key: ValueKey('$_currentIndex-$_pageGeneration'),
        child: _pages[_currentIndex],
      ),
```

- [ ] **Step 5: Analyze + test**

Run: `/c/flutter/bin/flutter analyze lib/pages/main_navigation.dart`
Expected: No issues found.
Run: `/c/flutter/bin/flutter test`
Expected: semua lulus.

- [ ] **Step 6: Commit**

```bash
git add lib/pages/main_navigation.dart
git commit -m "fix: reload Beranda after a document is created"
```

---

### Task 5: `ItemEditSheet`

**Files:**
- Create: `lib/widgets/item_edit_sheet.dart`
- Modify: `lib/services/locale_service.dart` (kunci `item.*`)
- Test: `test/widgets/item_edit_sheet_test.dart`

**Interfaces:**
- Consumes:
  - `ItemFaktur` (`lib/models/faktur_model.dart`): `namaBarang`, `deskripsi`, `kuantitas`, `satuan`, `hargaSatuan`, getter `jumlah`
  - `AppColors.errorFor` dari `lib/main.dart`
- Produces:
  - `class ItemEditResult`: field `ItemFaktur? item`, getter `bool deleted`, konstruktor `ItemEditResult.saved(ItemFaktur item)` dan `const ItemEditResult.deleted()`.
  - `Future<ItemEditResult?> showItemEditSheet(BuildContext context, {required ItemFaktur item, required NumberFormat currency, bool isNew = false})`. Mengembalikan `null` bila sheet ditutup tanpa aksi.
  - `ItemEditSheet` (StatefulWidget). Publik supaya bisa dipakai struk di tahap 3.

- [ ] **Step 1: Tambah kunci locale**

Sebelum `};` penutup `_strings`:

```dart
  'item.add_title': ['Tambah item', 'Add item'],
  'item.edit_title': ['Ubah item', 'Edit item'],
  'item.name': ['Nama item', 'Item name'],
  'item.name_required': ['Nama item wajib diisi', 'Item name is required'],
  'item.description': ['Deskripsi (opsional)', 'Description (optional)'],
  'item.qty': ['Jumlah', 'Quantity'],
  'item.qty_less': ['Kurangi jumlah', 'Decrease quantity'],
  'item.qty_more': ['Tambah jumlah', 'Increase quantity'],
  'item.price': ['Harga satuan', 'Unit price'],
  'item.unit': ['Satuan', 'Unit'],
  'item.delete': ['Hapus item', 'Delete item'],
```

- [ ] **Step 2: Tulis test yang gagal**

`test/widgets/item_edit_sheet_test.dart`:

```dart
import 'package:faktur_gen/models/faktur_model.dart';
import 'package:faktur_gen/widgets/item_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

final _fmt =
    NumberFormat.currency(locale: 'en_US', symbol: 'Rp ', decimalDigits: 0);

/// Opens the sheet on a phone-sized screen; the returned function reads
/// the result once the sheet has closed.
Future<ItemEditResult? Function()> _open(WidgetTester tester, ItemFaktur item,
    {bool isNew = false}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  ItemEditResult? result;
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async {
              result = await showItemEditSheet(context,
                  item: item, currency: _fmt, isNew: isNew);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => result;
}

void main() {
  testWidgets('save returns the edited item with stepped quantity',
      (tester) async {
    final read =
        await _open(tester, ItemFaktur(namaBarang: 'Desain', hargaSatuan: 1000));

    await tester.tap(find.byTooltip('Tambah jumlah'));
    await tester.pump();
    expect(find.text('Simpan · Rp 2,000'), findsOneWidget);

    await tester.tap(find.text('Simpan · Rp 2,000'));
    await tester.pumpAndSettle();
    final result = read();
    expect(result, isNotNull);
    expect(result!.deleted, isFalse);
    expect(result.item!.namaBarang, 'Desain');
    expect(result.item!.kuantitas, 2);
    expect(result.item!.hargaSatuan, 1000);
  });

  testWidgets('quantity cannot go below 1', (tester) async {
    await _open(tester, ItemFaktur(namaBarang: 'A', hargaSatuan: 10));
    final less = tester.widget<IconButton>(find.ancestor(
        of: find.byIcon(Icons.remove), matching: find.byType(IconButton)));
    expect(less.onPressed, isNull);
  });

  testWidgets('typing a price updates the subtotal on the button',
      (tester) async {
    await _open(tester, ItemFaktur(namaBarang: 'A'), isNew: true);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Harga satuan'), '2500');
    await tester.pump();
    expect(find.text('Simpan · Rp 2,500'), findsOneWidget);
  });

  testWidgets('empty name blocks save', (tester) async {
    final read = await _open(tester, ItemFaktur(), isNew: true);
    await tester.tap(find.text('Simpan · Rp 0'));
    await tester.pumpAndSettle();
    expect(find.text('Nama item wajib diisi'), findsOneWidget);
    expect(read(), isNull);
  });

  testWidgets('delete returns a deleted result', (tester) async {
    final read = await _open(tester, ItemFaktur(namaBarang: 'A'));
    await tester.tap(find.text('Hapus item'));
    await tester.pumpAndSettle();
    expect(read()?.deleted, isTrue);
  });

  testWidgets('new items have no delete button', (tester) async {
    await _open(tester, ItemFaktur(), isNew: true);
    expect(find.text('Hapus item'), findsNothing);
  });
}
```

- [ ] **Step 3: Jalankan, pastikan gagal**

Run: `/c/flutter/bin/flutter test test/widgets/item_edit_sheet_test.dart`
Expected: FAIL, `item_edit_sheet.dart` tidak ditemukan.

- [ ] **Step 4: Implementasi**

`lib/widgets/item_edit_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/faktur_model.dart';
import '../services/locale_service.dart';

/// Outcome of the item sheet: an edited item, or a delete request.
class ItemEditResult {
  final ItemFaktur? item;
  const ItemEditResult.saved(ItemFaktur this.item);
  const ItemEditResult.deleted() : item = null;

  bool get deleted => item == null;
}

Future<ItemEditResult?> showItemEditSheet(
  BuildContext context, {
  required ItemFaktur item,
  required NumberFormat currency,
  bool isNew = false,
}) {
  return showModalBottomSheet<ItemEditResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        ItemEditSheet(item: item, currency: currency, isNew: isNew),
  );
}

class ItemEditSheet extends StatefulWidget {
  final ItemFaktur item;
  final NumberFormat currency;
  final bool isNew;

  const ItemEditSheet({
    super.key,
    required this.item,
    required this.currency,
    this.isNew = false,
  });

  @override
  State<ItemEditSheet> createState() => _ItemEditSheetState();
}

class _ItemEditSheetState extends State<ItemEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.item.namaBarang);
  late final _deskripsi = TextEditingController(text: widget.item.deskripsi);
  late final _satuan = TextEditingController(text: widget.item.satuan);
  late final _harga = TextEditingController(
      text: widget.item.hargaSatuan > 0 ? _fmt(widget.item.hargaSatuan) : '');
  late double _qty = widget.item.kuantitas;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  double get _price => double.tryParse(_harga.text.replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    _nama.dispose();
    _deskripsi.dispose();
    _satuan.dispose();
    _harga.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final satuan = _satuan.text.trim();
    Navigator.pop(
      context,
      ItemEditResult.saved(ItemFaktur(
        namaBarang: _nama.text.trim(),
        deskripsi: _deskripsi.text.trim(),
        kuantitas: _qty,
        satuan: satuan.isEmpty ? 'Unit' : satuan,
        hargaSatuan: _price,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.isNew ? tr('item.add_title') : tr('item.edit_title'),
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nama,
                autofocus: widget.isNew,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: tr('item.name')),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? tr('item.name_required')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deskripsi,
                decoration: InputDecoration(labelText: tr('item.description')),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: Text(tr('item.qty'),
                          style: theme.textTheme.bodyLarge)),
                  IconButton.filledTonal(
                    tooltip: tr('item.qty_less'),
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed:
                        _qty > 1 ? () => setState(() => _qty -= 1) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(_fmt(_qty),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium),
                  ),
                  IconButton.filledTonal(
                    tooltip: tr('item.qty_more'),
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => setState(() => _qty += 1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _harga,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: InputDecoration(labelText: tr('item.price')),
                      // Only this sheet rebuilds; the invoice page stays still.
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _satuan,
                      decoration: InputDecoration(labelText: tr('item.unit')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: Text(
                    '${tr('common.save')} · ${widget.currency.format(_qty * _price)}'),
              ),
              if (!widget.isNew)
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, const ItemEditResult.deleted()),
                  child: Text(tr('item.delete'),
                      style: TextStyle(
                          color: AppColors.errorFor(theme.brightness))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Jalankan, pastikan lulus**

Run: `/c/flutter/bin/flutter test test/widgets/item_edit_sheet_test.dart`
Expected: 6 test PASS.
Run: `/c/flutter/bin/flutter analyze lib/widgets/item_edit_sheet.dart`
Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/item_edit_sheet.dart lib/services/locale_service.dart test/widgets/item_edit_sheet_test.dart
git commit -m "feat: add item edit sheet with quantity stepper"
```

---

### Task 6: `TotalBar`

**Files:**
- Create: `lib/widgets/total_bar.dart`
- Modify: `lib/services/locale_service.dart` (kunci `common.*`)
- Test: `test/widgets/total_bar_test.dart`

**Interfaces:**
- Produces: `TotalBar({required ValueListenable<double> total, required NumberFormat currency, required String actionLabel, required VoidCallback onAction, bool busy = false})`.
  - Total berganti dengan fade 150ms.
  - Saat `busy`, tombol nonaktif dan menampilkan spinner kecil + "Membuat…".
  - Sudah membungkus dirinya sendiri dengan `SafeArea`.

- [ ] **Step 1: Tambah kunci locale**

Sebelum `};` penutup `_strings`:

```dart
  'common.total': ['Total', 'Total'],
  'common.generating': ['Membuat…', 'Creating…'],
  'common.done': ['Selesai', 'Done'],
```

- [ ] **Step 2: Tulis test yang gagal**

`test/widgets/total_bar_test.dart`:

```dart
import 'package:faktur_gen/widgets/total_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

final _fmt =
    NumberFormat.currency(locale: 'en_US', symbol: 'Rp ', decimalDigits: 0);

Widget _app(TotalBar bar) =>
    MaterialApp(home: Scaffold(bottomNavigationBar: bar));

void main() {
  testWidgets('shows the new total when the notifier changes', (tester) async {
    final total = ValueNotifier<double>(1000);
    await tester.pumpWidget(_app(TotalBar(
        total: total, currency: _fmt, actionLabel: 'Buat PDF', onAction: () {})));
    expect(find.text('Rp 1,000'), findsOneWidget);

    total.value = 2500;
    await tester.pumpAndSettle();
    expect(find.text('Rp 2,500'), findsOneWidget);
    expect(find.text('Rp 1,000'), findsNothing);
  });

  testWidgets('tapping the action calls onAction', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(TotalBar(
        total: ValueNotifier(0),
        currency: _fmt,
        actionLabel: 'Buat PDF',
        onAction: () => taps++)));
    await tester.tap(find.text('Buat PDF'));
    expect(taps, 1);
  });

  testWidgets('busy disables the action and shows progress', (tester) async {
    await tester.pumpWidget(_app(TotalBar(
        total: ValueNotifier(0),
        currency: _fmt,
        actionLabel: 'Buat PDF',
        onAction: () {},
        busy: true)));
    expect(find.text('Membuat…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
  });
}
```

- [ ] **Step 3: Jalankan, pastikan gagal**

Run: `/c/flutter/bin/flutter test test/widgets/total_bar_test.dart`
Expected: FAIL, file tidak ditemukan.

- [ ] **Step 4: Implementasi**

`lib/widgets/total_bar.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/locale_service.dart';

/// Sticky bottom bar: running total plus the screen's one primary action.
class TotalBar extends StatelessWidget {
  final ValueListenable<double> total;
  final NumberFormat currency;
  final String actionLabel;
  final VoidCallback onAction;
  final bool busy;

  const TotalBar({
    super.key,
    required this.total,
    required this.currency,
    required this.actionLabel,
    required this.onAction,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fade = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 150);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('common.total'), style: theme.textTheme.bodySmall),
                    ValueListenableBuilder<double>(
                      valueListenable: total,
                      builder: (_, value, child) => AnimatedSwitcher(
                        duration: fade,
                        child: Text(
                          currency.format(value),
                          key: ValueKey(value),
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: busy ? null : onAction,
                child: busy
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(tr('common.generating')),
                        ],
                      )
                    : Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Jalankan, pastikan lulus**

Run: `/c/flutter/bin/flutter test test/widgets/total_bar_test.dart`
Expected: 3 test PASS.
Run: `/c/flutter/bin/flutter analyze lib/widgets/total_bar.dart`
Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/total_bar.dart lib/services/locale_service.dart test/widgets/total_bar_test.dart
git commit -m "feat: add sticky TotalBar with busy state"
```

---

### Task 7: Form invoice pola A

**Files:**
- Modify: `lib/pages/faktur_page.dart`
- Modify: `lib/services/locale_service.dart` (kunci `invoice.*`)

**Interfaces:**
- Consumes:
  - `showItemEditSheet`, `ItemEditResult` (Task 5)
  - `TotalBar` (Task 6)
  - `FakturModel.totalTagihan`, `taxRate`, `tanggal`, `jatuhTempo`
  - kunci `common.done`, `common.cancel`, `common.save`, `common.undo`, `common.delete`
- Produces: `FakturPage` dengan konstruktor yang sama (`initialEntry`, `reminderItems`, `reminderContactName`). Pemanggil di `history_page.dart:157`, `reminder_page.dart:123`, dan `main_navigation.dart` tidak berubah.

Halaman ini memanggil Firebase lewat service, jadi tidak ada widget test. Logika barunya (sheet, total) sudah dites di Task 5–6. Verifikasinya lewat analyze, test, dan cek manual.

- [ ] **Step 1: Tambah kunci locale**

Sebelum `};` penutup `_strings`:

```dart
  'invoice.new_title': ['Invoice baru', 'New invoice'],
  'invoice.number': ['Nomor invoice', 'Invoice number'],
  'invoice.to': ['Untuk', 'To'],
  'invoice.choose_client': ['Pilih klien', 'Choose client'],
  'invoice.client': ['Klien', 'Client'],
  'invoice.from_contacts': ['Dari kontak', 'From contacts'],
  'invoice.client_name': ['Nama perusahaan / klien', 'Company / client name'],
  'invoice.client_phone': ['No. telepon / WhatsApp', 'Phone / WhatsApp'],
  'invoice.client_address': ['Alamat', 'Address'],
  'invoice.due': ['Jatuh tempo', 'Due date'],
  'invoice.no_due': ['Tanpa jatuh tempo', 'No due date'],
  'invoice.days_short': ['{n} h', '{n} d'],
  'invoice.items': ['Item', 'Items'],
  'invoice.no_items': ['Belum ada item', 'No items yet'],
  'invoice.add_item': ['Tambah item', 'Add item'],
  'invoice.from_catalog': ['Dari katalog', 'From catalog'],
  'invoice.item_removed': ['"{name}" dihapus', '"{name}" removed'],
  'invoice.extras': ['PPN {tax}%, catatan', 'Tax {tax}%, notes'],
  'invoice.extras_title': ['Pajak dan catatan', 'Tax and notes'],
  'invoice.date': ['Tanggal invoice', 'Invoice date'],
  'invoice.tax': ['PPN', 'Tax'],
  'invoice.tax_hint': ['Ubah di Pengaturan', 'Change in Settings'],
  'invoice.notes': ['Catatan', 'Notes'],
  'invoice.make_pdf': ['Buat PDF', 'Create PDF'],
  'invoice.need_number': ['Isi nomor invoice dulu', 'Enter an invoice number first'],
  'invoice.need_client': ['Isi nama klien dulu', 'Enter the client name first'],
  'invoice.need_item': ['Tambahkan minimal satu item', 'Add at least one item'],
  'invoice.store_missing': ['Nama toko belum diisi. Lengkapi di Pengaturan.', 'Store name is empty. Fill it in Settings.'],
```

- [ ] **Step 2: Import dan state**

Tambah import:

```dart
import '../services/locale_service.dart';
import '../widgets/item_edit_sheet.dart';
import '../widgets/total_bar.dart';
```

Di `_FakturPageState`:
- Hapus `final _formKey = GlobalKey<FormState>();`
- Hapus `final List<_ItemCtrls> _itemCtrls = [_ItemCtrls()];`
- Tambah:

```dart
  // Items live here, not in per-field controllers: typing happens inside
  // the item sheet, so the page only rebuilds when an item is saved.
  final _items = ValueNotifier<List<ItemFaktur>>([]);
  final _total = ValueNotifier<double>(0);
  bool _isGenerating = false;

  String get _dateLocale => LocaleService.isEn ? 'en_US' : 'id_ID';
```

Ganti `initState`:

```dart
  @override
  void initState() {
    super.initState();
    _items.addListener(_recalcTotal);
    _recalcTotal();
    _loadSettings();
  }

  void _recalcTotal() {
    _faktur.items = _items.value;
    _total.value = _faktur.totalTagihan;
  }
```

Di `dispose`, hapus loop `for (final c in _itemCtrls) { c.dispose(); }`, lalu tambah sebelum `super.dispose()`:

```dart
    _items.dispose();
    _total.dispose();
```

- [ ] **Step 3: Isi awal item di `_loadSettings`**

Di cabang `if (entry != null)`, ganti semua baris dari `_faktur.items = entry.items` sampai akhir loop `_itemCtrls.add(c);` dengan:

```dart
          _items.value = entry.items
              .map((i) => ItemFaktur(
                    namaBarang: i.nama,
                    kuantitas: i.kuantitas,
                    satuan: i.satuan,
                    hargaSatuan: i.hargaSatuan,
                  ))
              .toList();
```

Di cabang `reminderItems`, ganti semua baris dari `_faktur.items = widget.reminderItems!` sampai akhir loop `_itemCtrls.add(c);` dengan:

```dart
          _items.value = widget.reminderItems!
              .map((i) => ItemFaktur(
                    namaBarang: i.nama,
                    kuantitas: i.kuantitas,
                    satuan: i.satuan,
                    hargaSatuan: i.hargaSatuan,
                  ))
              .toList();
```

`_faktur.taxRate` sudah diset di `setState` yang sama sebelum item, jadi listener menghitung total dengan tarif yang benar. Untuk cabang tanpa item, panggil `_recalcTotal();` setelah `_isLoading = false;` di akhir `setState`.

- [ ] **Step 4: Operasi item**

Ganti `_addItem` dan `_removeItem` dengan:

```dart
  Future<void> _addItem() async {
    final result = await showItemEditSheet(context,
        item: ItemFaktur(), currency: _currency, isNew: true);
    if (result == null || result.deleted) return;
    _isDirty = true;
    _items.value = [..._items.value, result.item!];
  }

  Future<void> _editItem(int index) async {
    final result = await showItemEditSheet(context,
        item: _items.value[index], currency: _currency);
    if (result == null) return;
    if (result.deleted) {
      _removeItem(index);
      return;
    }
    _isDirty = true;
    _items.value = [..._items.value]..[index] = result.item!;
  }

  void _removeItem(int index) {
    final list = [..._items.value];
    final removed = list.removeAt(index);
    _isDirty = true;
    _items.value = list;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(tr('invoice.item_removed')
            .replaceAll('{name}', removed.namaBarang)),
        duration: const Duration(seconds: 4),
        persist: false,
        action: SnackBarAction(
          label: tr('common.undo'),
          onPressed: () {
            final restored = [..._items.value];
            restored.insert(index.clamp(0, restored.length), removed);
            _items.value = restored;
          },
        ),
      ));
  }
```

Di `_openCatalog`, ganti seluruh blok `setState(() { ... });` di akhir method dengan:

```dart
    _isDirty = true;
    _items.value = [
      ..._items.value,
      ItemFaktur(
        namaBarang: selected.nama,
        deskripsi: selected.deskripsi,
        satuan: selected.satuan,
        hargaSatuan: selected.hargaSatuan,
      ),
    ];
```

Di `_loadTemplate`, di dalam `setState`, hapus semua baris dari `_faktur.items = selected.items` sampai akhir loop `_itemCtrls.add(c);`. Setelah `setState(...)` ditutup, tambah:

```dart
    _items.value = selected.items
        .map((i) => ItemFaktur(
              namaBarang: i.nama,
              deskripsi: i.deskripsi,
              kuantitas: i.kuantitas,
              satuan: i.satuan,
              hargaSatuan: i.hargaSatuan,
            ))
        .toList();
```

Perubahan lain:
- Di `_resetForm`, ganti `_faktur.items = [ItemFaktur()];` dan blok dispose/clear `_itemCtrls` dengan `_items.value = [];`.
- Hapus `_reorderItem`. Pola A tidak punya fitur urut ulang.
- Di `_pickDate`, tambah `_isDirty = true;` di dalam `setState` yang sudah ada.

- [ ] **Step 5: Ganti `_generatePdf`**

Ganti seluruh `_generatePdf` dengan dua method di bawah. Isi `HistoryEntry(...)` dan `PdfPreviewPage(...)` disalin **tanpa perubahan** dari versi lama (`faktur_page.dart:308-335` dan `342-354`). Satu pengecualian: judul preview, yang diganti ke `tr` di Task 8.

```dart
  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _generatePdf() async {
    if (_isGenerating) return;
    _syncToModel();
    if (_faktur.nomorFaktur.trim().isEmpty) {
      _showMessage(tr('invoice.need_number'));
      return;
    }
    if (_faktur.namaPembeli.trim().isEmpty) {
      _showMessage(tr('invoice.need_client'));
      _showClientSheet();
      return;
    }
    if (_items.value.isEmpty) {
      _showMessage(tr('invoice.need_item'));
      return;
    }

    setState(() => _isGenerating = true);
    final bool saved;
    try {
      saved = await _saveDocument();
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
    if (!saved || !mounted) return;

    final faktur = _faktur;
    final isPro = await SubscriptionService.isPro();
    if (!mounted) return;
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewPage(
          title: 'Preview Invoice',
          filename: 'Invoice_${faktur.nomorFaktur.replaceAll('/', '-')}.pdf',
          buildPdf: (format) => PdfService.buildBytes(faktur, format,
              logoBytes: _settings.logoBytes,
              signatureBytes: _settings.signatureBytes,
              templateConfig: _settings.templateConfig,
              showWatermark: !isPro,
              qrisMerchantId: isPro ? _settings.qrisMerchantId : null),
        ),
      ),
    );
    if (!mounted) return;
    await _showReminderDialog(faktur);
    if (done == true && mounted) Navigator.pop(context);
  }

  /// Checks the quota, then stores contact and history.
  /// False when the paywall blocked it.
  Future<bool> _saveDocument() async {
    if (!await SubscriptionService.canCreateDocument()) {
      if (mounted) showPaywallSheet(context);
      return false;
    }
    final faktur = _faktur;
    await ContactService.saveIfNotExists(
      nama: faktur.namaPembeli,
      npwp: faktur.npwpPembeli,
      alamat: faktur.alamatPembeli,
      telepon: faktur.teleponPembeli,
    );
    _reloadContacts();
    await HistoryService.add(HistoryEntry(
      // salin isi HistoryEntry(...) lama tanpa perubahan
    ));
    await SubscriptionService.incrementDocCount();
    _isDirty = false;
    return true;
  }
```

Baris `// salin isi HistoryEntry(...) lama` adalah instruksi untuk executor. Ganti dengan argumen persis dari kode lama, mulai `id:` sampai `currency: faktur.currency,`. Komentar ini tidak boleh tertinggal di kode.

- [ ] **Step 6: Bagian layar baru**

Hapus method lama berikut. Sebelum menghapus, pastikan dengan grep bahwa tidak ada pemanggil lain:
- `_buildPenjualBanner`, `_buildInfoInvoice`, `_datePicker`, `_buildPembeli`
- `_buildItemSection`, `_buildItemRow`, `_buildTotalCard`, `_buildCatatanCard`, `_totalRow`, `_buildGenerateButton`
- `_card`, `_field`
- kelas `_ItemCtrls`

`_fmtQty` tetap dipakai. Tambah method berikut di `_FakturPageState`:

```dart
  Widget _row(
    ThemeData theme, {
    String? label,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null) ...[
                    Text(label, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                  ],
                  Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: titleColor)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return InkWell(
      onTap: _editNumber,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('invoice.new_title'), style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(_nomorCtrl.text, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Future<void> _editNumber() async {
    var draft = _nomorCtrl.text;
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('invoice.number')),
        content: TextFormField(
          initialValue: draft,
          autofocus: true,
          onChanged: (v) => draft = v,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('common.cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, draft.trim()),
              child: Text(tr('common.save'))),
        ],
      ),
    );
    if (value == null || value.isEmpty || !mounted) return;
    setState(() {
      _nomorCtrl.text = value;
      _isDirty = true;
    });
  }

  Widget _buildClientRow(ThemeData theme) {
    final name = _namaPembeliCtrl.text.trim();
    final details = [_teleponPembeliCtrl.text.trim(), _alamatPembeliCtrl.text.trim()]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return _row(
      theme,
      label: tr('invoice.to'),
      title: name.isEmpty ? tr('invoice.choose_client') : name,
      titleColor: name.isEmpty ? theme.colorScheme.primary : null,
      subtitle: details.isEmpty ? null : details,
      onTap: _showClientSheet,
    );
  }

  Future<void> _showClientSheet() async {
    String snapshot() =>
        '${_namaPembeliCtrl.text}|${_teleponPembeliCtrl.text}|${_alamatPembeliCtrl.text}';
    final before = snapshot();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(tr('invoice.client'),
                        style: Theme.of(ctx).textTheme.titleMedium)),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showContactPicker();
                  },
                  icon: const Icon(Icons.contacts_outlined, size: 18),
                  label: Text(tr('invoice.from_contacts')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _namaPembeliCtrl,
              autofocus: _namaPembeliCtrl.text.isEmpty,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: tr('invoice.client_name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _teleponPembeliCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: tr('invoice.client_phone')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _alamatPembeliCtrl,
              maxLines: 2,
              decoration:
                  InputDecoration(labelText: tr('invoice.client_address')),
            ),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr('common.done'))),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      if (snapshot() != before) _isDirty = true;
    });
  }

  Widget _buildDueRow(ThemeData theme) {
    final due = _faktur.jatuhTempo;
    final days = due == null
        ? null
        : DateUtils.dateOnly(due)
            .difference(DateUtils.dateOnly(_faktur.tanggal))
            .inDays;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _pickDate(true),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('invoice.due'), style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      due == null
                          ? tr('invoice.no_due')
                          : DateFormat('d MMM yyyy', _dateLocale).format(due),
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          for (final d in const [7, 14, 30])
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: ChoiceChip(
                label: Text(tr('invoice.days_short').replaceAll('{n}', '$d')),
                selected: days == d,
                showCheckmark: false,
                onSelected: (_) => setState(() {
                  _faktur.jatuhTempo = _faktur.tanggal.add(Duration(days: d));
                  _isDirty = true;
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItems(ThemeData theme) {
    return ValueListenableBuilder<List<ItemFaktur>>(
      valueListenable: _items,
      builder: (context, items, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('invoice.items'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child:
                  Text(tr('invoice.no_items'), style: theme.textTheme.bodySmall),
            ),
          for (var i = 0; i < items.length; i++) _itemRow(theme, items[i], i),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 18),
                label: Text(tr('invoice.add_item')),
              ),
              TextButton(
                onPressed: _openCatalog,
                child: Text(tr('invoice.from_catalog')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemRow(ThemeData theme, ItemFaktur item, int index) {
    final isDark = theme.brightness == Brightness.dark;
    return Dismissible(
      key: ObjectKey(item),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.errorFor(theme.brightness),
        child: Icon(Icons.delete_outline,
            // #0F1117 on #F87171 = 6.82:1; white on #B91C1C = 6.47:1.
            color: isDark ? const Color(0xFF0F1117) : Colors.white,
            semanticLabel: tr('common.delete')),
      ),
      onDismissed: (_) => _removeItem(index),
      child: InkWell(
        onTap: () => _editItem(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.namaBarang, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmtQty(item.kuantitas)} ${item.satuan} × '
                      '${_currency.format(item.hargaSatuan)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(_currency.format(item.jumlah),
                  style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExtrasRow(ThemeData theme) {
    final note = _catatanCtrl.text.trim();
    return _row(
      theme,
      title: tr('invoice.extras').replaceAll('{tax}', _fmtQty(_faktur.taxRate)),
      subtitle: note.isEmpty ? null : note,
      onTap: _showExtrasSheet,
    );
  }

  Future<void> _showExtrasSheet() async {
    final before = _catatanCtrl.text;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr('invoice.extras_title'),
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('invoice.date')),
                trailing: Text(DateFormat('d MMM yyyy', _dateLocale)
                    .format(_faktur.tanggal)),
                onTap: () async {
                  await _pickDate(false);
                  setSheet(() {});
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('invoice.tax')),
                subtitle: Text(tr('invoice.tax_hint')),
                trailing: Text('${_fmtQty(_faktur.taxRate)}%'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _catatanCtrl,
                maxLines: 3,
                decoration: InputDecoration(labelText: tr('invoice.notes')),
              ),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(tr('common.done'))),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      if (_catatanCtrl.text != before) _isDirty = true;
    });
  }
```

`_pickDate` sudah `async` dan mengembalikan `Future<void>`, jadi `await _pickDate(false)` valid.

- [ ] **Step 7: Ganti `build`**

Pertahankan `PopScope` (dialog keluar) dan `PopupMenuButton` apa adanya. Lalu ganti:
- `AppBar(title: const Text('Buat Invoice'), actions: [...])` jadi `AppBar(actions: [...])`. Judul pindah ke body.
- Semua dari `body: Form(...)` sampai `bottomNavigationBar: SafeArea(...)` jadi:

```dart
      body: ListView(
        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
        children: [
          _buildHeader(theme),
          if (_settings.isEmpty) ...[
            const SizedBox(height: 8),
            Text(tr('invoice.store_missing'), style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 24),
          _buildClientRow(theme),
          const Divider(height: 1),
          _buildDueRow(theme),
          const Divider(height: 1),
          const SizedBox(height: 24),
          _buildItems(theme),
          const Divider(height: 1),
          _buildExtrasRow(theme),
        ],
      ),
      bottomNavigationBar: TotalBar(
        total: _total,
        currency: _currency,
        actionLabel: tr('invoice.make_pdf'),
        busy: _isGenerating,
        onAction: _generatePdf,
      ),
```

Di awal `build`:
- Ubah `hPad` default untuk ponsel dari `16.0` ke `20.0`.
- Hapus variabel `isTablet` kalau tidak dipakai lagi.

- [ ] **Step 8: Analyze + test**

Run: `/c/flutter/bin/flutter analyze lib/pages/faktur_page.dart`
Expected: No issues found. Hapus import yang jadi tak terpakai.
Run: `grep -n "_itemCtrls\|_ItemCtrls\|_formKey\|_card(\|_field(" lib/pages/faktur_page.dart`
Expected: tidak ada output.
Run: `/c/flutter/bin/flutter test`
Expected: semua lulus.

- [ ] **Step 9: Commit**

```bash
git add lib/pages/faktur_page.dart lib/services/locale_service.dart
git commit -m "feat: invoice form as one readable page with item sheet"
```

---

### Task 8: Sisa teks form invoice lewat `tr()`

**Files:**
- Modify: `lib/pages/faktur_page.dart`
- Modify: `lib/services/locale_service.dart`

**Interfaces:**
- Consumes: kunci yang sudah ada: `common.cancel`, `common.save`, `common.delete`, `common.undo`, `common.close`.
- Produces: tidak ada API baru.

Literal Indonesia yang tersisa ada di:
- dialog keluar (`PopScope`)
- menu titik tiga
- `_showReminderDialog`, `_saveAsTemplate`, `_loadTemplate`
- snackbar
- `_ContactPickerSheet`, `_TemplatePickerSheet`, `_CatalogPickerSheet`
- judul `PdfPreviewPage` di `_generatePdf`

- [ ] **Step 1: Daftar literal**

Run: `grep -nE "Text\(\s*'|Text\(\s*\"|title: '|label: '|labelText: '|hintText: '|content: Text\('" lib/pages/faktur_page.dart`
Simpan daftar ini di laporan task.

- [ ] **Step 2: Ganti setiap literal**

Untuk setiap literal yang tampil ke user:
1. Kalau sudah ada kunci `common.*` dengan teks Indonesia yang sama persis (`Batal`, `Simpan`, `Hapus`, `Tutup`), pakai kunci itu.
2. Kalau belum ada, tambah kunci `invoice.<nama_singkat_snake_case>` di `_strings`:
   - teks Indonesia disalin **persis** dari kode
   - terjemahan Inggris singkat dan natural
3. Literal dengan interpolasi memakai placeholder. Contoh untuk `'Template "$name" tersimpan'`:
   - kunci: `'invoice.template_saved': ['Template "{name}" tersimpan', 'Template "{name}" saved']`
   - pemakaian: `tr('invoice.template_saved').replaceAll('{name}', name)`
4. `const Text('...')` jadi `Text(tr('...'))`. Hapus `const` dari widget induk yang tidak lagi konstan.

Jangan ubah string non-UI:
- kunci map
- nama file `'Invoice_...pdf'`
- `'Unit'` sebagai nilai default model
- nilai `'reset'`/`'catalog'` di menu

Judul preview tetap "Preview Invoice" untuk Bahasa Indonesia, tapi lewat `tr('invoice.preview_title')`: `['Preview Invoice', 'Invoice Preview']`.

Tombol "Keluar" di dialog keluar memakai `Colors.red` (#F44336), yang di atas putih hanya 3.68:1. Ganti dengan `AppColors.errorFor(Theme.of(ctx).brightness)`.

- [ ] **Step 3: Verifikasi**

Run: `grep -nE "Text\(\s*'[A-Z]|title: '|labelText: '|hintText: '" lib/pages/faktur_page.dart`
Expected: tidak ada output.
Run: `/c/flutter/bin/flutter analyze lib/pages/faktur_page.dart lib/services/locale_service.dart`
Expected: No issues found. `_strings` tidak boleh punya kunci ganda; analyzer menandainya sebagai `equal_keys_in_map`.
Run: `/c/flutter/bin/flutter test`
Expected: semua lulus.

- [ ] **Step 4: Commit**

```bash
git add lib/pages/faktur_page.dart lib/services/locale_service.dart
git commit -m "feat: translate invoice form strings"
```

---

## Cek manual (user, di HP/emulator)

Setelah semua task selesai:

1. **Beranda dengan data**
   - Angka "Belum dibayar" sama dengan jumlah invoice belum lunas di Riwayat.
   - Maksimal 2 baris lewat jatuh tempo.
   - "Lihat semua" pindah ke tab Riwayat.
   - Batang bulan ini berwarna biru.
   - Label bulan mengikuti bahasa aktif.
2. **Beranda kosong** (akun baru)
   - Tampil pesan + tombol "Buat invoice".
   - Setelah invoice dibuat dan form ditutup, Beranda langsung terisi tanpa perlu tarik-untuk-muat.
3. **Beranda gagal** (mode pesawat, data lokal kosong): tampil pesan + "Coba lagi".
4. **Form invoice**
   - Tambah item lewat sheet.
   - Stepper ± jalan.
   - Tap item untuk edit.
   - Geser item untuk hapus, lalu Urungkan dalam 4 detik.
   - "Dari katalog" jalan.
   - Chip 7/14/30 dan tap tanggal jatuh tempo jalan.
   - Pajak dan catatan bisa diubah.
   - Buat PDF menampilkan "Membuat…", lalu preview.
5. **Validasi**
   - Buat PDF tanpa klien membuka sheet klien.
   - Buat PDF tanpa item menampilkan pesan.
6. **Tampilan**
   - Mode terang dan gelap.
   - Bahasa English.
   - Skala teks 200%, tidak ada teks terpotong di bar total.
7. **TalkBack**
   - Tombol stepper terbaca "Tambah jumlah" / "Kurangi jumlah".
   - Latar hapus item terbaca "Hapus".
8. **Performa** (sesuai spec)
   - Pakai DevTools dalam profile mode (`flutter run --profile`).
   - Buat form 10 item, buka sheet item, lalu ketik harga.
   - Catat jumlah frame > 16ms sebelum (commit `main` sebelum tahap ini) dan sesudah.
   - Tanpa angka ini, klaim "lebih halus" tidak dipakai.
