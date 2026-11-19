# UI Refresh Tahap 3a (Riwayat + Pengingat) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Selaraskan Riwayat dan Pengingat dengan Beranda baru:
- Riwayat (mockup 04): daftar polos per tanggal, filter jadi tab bergaris bawah, ekspor jadi tombol teks, geser hapus + Urungkan, kondisi kosong-karena-filter dan gagal.
- Pengingat: struktur tetap, tapi baris polos + pemisah, peran `textTheme`, `StatusLabel` untuk jatuh tempo/terlewat, `AppColors`, semua teks lewat `tr()`.

**Architecture:**
- Logika filter dan pengelompokan per hari Riwayat dipindah ke fungsi murni di `lib/models/history_view.dart`, dites tanpa Firebase.
- Bagian atas `history_page.dart` (`HistoryPage` + `_HistoryPageState`) ditulis ulang. `_DetailSheet` di file yang sama tidak disentuh.
- Hapus di Riwayat memakai pola `faktur_page._removeItem` (SnackBar `persist: false`, 4 detik, `common.undo`). Bedanya: data di penyimpanan, jadi hapus langsung jalan dan Urungkan menulis ulang entri lewat `HistoryService.add`.
- `reminder_page.dart` diedit per bagian; tidak ada widget atau file baru selain `history_view.dart`.

**Tech Stack:** Flutter (SDK di `C:\flutter`, tidak ada di PATH), Material 3, `intl`, `flutter_test`.

Spec: `docs/superpowers/specs/2026-11-19-ui-refresh-design.md`, bagian "Sistem desain", "Riwayat (mockup 04)", "Pengingat, onboarding, login, splash", "Gerak dan kehalusan", "Bahasa". Mockup: `docs/mockups/04-history.svg`.

## Global Constraints

- Tidak ada package baru. Font tetap Inter.
- Aksen dari `colorScheme.primary` hanya untuk tombol utama, tautan, tab aktif.
- Warna status lewat `AppColors.errorFor/warningFor/successFor(brightness)` (`lib/main.dart:107-117`). Semua sudah ≥ 4.5:1 di latar masing-masing.
- Teks memakai `textTheme` tahap 1 (`lib/main.dart:240-257`):
  - `headlineSmall` 22/700 judul halaman, `titleMedium` 17/600 judul bagian/sheet
  - `titleSmall` 15/600 judul baris, `bodyLarge`/`bodyMedium` 15/400 isi
  - `bodySmall` 13/400 abu-abu (#6B7280 / #9CA3AF)
- Tidak ada `GoogleFonts.*()` baru, tidak ada `fontSize` literal baru, tidak ada `withValues(alpha: ...)` baru untuk warna teks.
- Tanpa kartu bergaris. Baris polos + `Divider(height: 1)`. Baris `InkWell` dengan padding vertikal 14 (≥ 48dp, sama seperti `dashboard_page.dart`).
- Status = titik + teks (`StatusLabel`, `lib/widgets/status_label.dart`), tidak pernah warna saja.
- Semua teks baru lewat `tr()`/`trN()` (`lib/services/locale_service.dart:34-39`), format `'key': ['id', 'en']`. Kunci baru disisipkan di seksi yang sesuai (History, Reminders, Contacts, common) agar tidak bentrok dengan rencana lain yang menambah di akhir map. `_strings` tidak boleh punya kunci ganda (`equal_keys_in_map`).
- Tanggal diformat dengan locale `LocaleService.isEn ? 'en_US' : 'id_ID'`.
- Memuat daftar: tidak tampil apa pun 300ms pertama, lalu teks `tr('dashboard.loading')` (pola `dashboard_page.dart:54-89`).
- SnackBar dengan Urungkan: `persist: false`, `duration: const Duration(seconds: 4)`, label `tr('common.undo')`.
- Animasi: kalau `MediaQuery.disableAnimationsOf(context)` true, tanpa animasi.
- Komentar singkat, menjelaskan alasan. Tanpa emoji di kode, tanpa kode mati, tanpa kode yang dikomentari.
- Commit: subjek pendek konvensional, tanpa trailer `Co-Authored-By`, tanpa menyebut AI.
- Perintah Flutter: `/c/flutter/bin/flutter` (Git Bash).
- Baseline: `flutter analyze` = 9 issue (semua di file yang tidak disentuh), `flutter test` = 114 lulus. Di akhir tiap task: analyze tetap 9, test lulus semua.

## Keputusan yang menyimpang dari spec / perlu diketahui

- **Filter "Lunas" dihapus.** Spec dan mockup hanya punya 4 tab: Semua, Invoice, Struk, Belum dibayar. Invoice lunas tetap terlihat di Semua/Invoice dengan status "Lunas". Label tab memakai kunci yang ada (`history.unpaid` = "Belum Lunas").
- **Struk selalu berstatus "Lunas".** `struk_page.dart:326` menyimpan struk tanpa `paymentStatus`, jadi nilainya default `unpaid`. Filter "Belum dibayar" sudah mengecualikan struk (kode lama `history_page.dart:84-89`); tampilan status mengikuti.
- **"Lewat N hari"** memakai `DashboardSummary.daysOverdue` (hari kalender), sama dengan Beranda.
- **Hapus langsung, Urungkan menulis ulang.** `MainNavigation` membuang `HistoryPage` saat pindah tab (`main_navigation.dart:228-231`), jadi menunda hapus sampai SnackBar tutup bisa hilang. Urungkan menunggu future hapus selesai dulu, lalu `HistoryService.add(entry)` (id dan seluruh `toMap()` sama), supaya tulis lokal tidak saling timpa. Kalau hapus gagal, daftar dimuat ulang dan baris muncul lagi.
- **Angka jumlah hasil** di samping chip (alpha 0.35, ~2:1) dihapus; tidak ada di mockup.
- **`_DetailSheet` Riwayat ditata ulang di Task 5** atas permintaan user ("redesign semua"), walau spec hanya membahas daftar. Perilaku tetap: cetak, ubah status bayar dengan tap, buat ulang. Yang berubah tampilannya:
  - tabel item jadi baris seperti form invoice
  - kartu ringkasan/catatan jadi teks polos
  - "Buat ulang dokumen" jadi satu-satunya tombol utama
  - label "PPN (11%)" yang ditulis mati jadi tarif dari `entry.taxRate` (default 11, sama seperti `FakturModel`)
  - diskon tidak lagi merah, karena merah hanya untuk aksi yang merusak
- **`_message` (teks + satu tombol) disalin dari `dashboard_page.dart:168-182`** ke Riwayat. Menjadikannya widget bersama berarti mengubah Beranda, di luar area rencana ini.
- **Pengingat:** hapus tetap lewat dialog konfirmasi (spec tidak meminta Urungkan di sini). "Hari ini" memakai `warningFor` seperti kode lama; Beranda memakai `primary` untuk label yang sama (`dashboard_page.dart:441-444`). Tidak diubah di sini, dicatat untuk review.
- **Kunci `common.phone` dan `common.address` belum ada**, sehingga detail pengingat sekarang menampilkan teks mentah "common.phone". Ditambahkan di Task 3.
- **`RepeatInterval.label` (model) tidak diubah**: dites sebagai teks Indonesia (`test/models/reminder_model_test.dart:6`) dan dipakai `recurring_invoice_page.dart`. Halaman Pengingat memakai `tr('reminder.repeat_${r.repeatInterval.name}')`.
- **Pesan WhatsApp pengingat** ikut bahasa app (sebelumnya selalu Indonesia).
- **Pengingat tidak mendapat kondisi "gagal"**; spec tidak memintanya. Hanya aturan muat 300ms.

## File Structure

| File | Perubahan |
|---|---|
| `lib/models/history_view.dart` (baru) | `HistoryFilter`, `filterHistory`, `groupByDay` |
| `test/models/history_view_test.dart` (baru) | test filter + pengelompokan |
| `lib/pages/history_page.dart` | baris 1-575 ditulis ulang (state, tab, baris, kondisi, hapus + Urungkan) di Task 2; `_DetailSheet` ditata ulang di Task 5 |
| `lib/pages/reminder_page.dart` | daftar, sheet detail, sheet tambah, sheet kontak: tema, `StatusLabel`, `AppColors`, `tr()` |
| `lib/services/locale_service.dart` | kunci baru `history.*` (daftar + detail), `reminder.*`, `contact.empty_hint`, `common.required/phone/address` |
| `test/services/locale_service_test.dart` | test kunci ulangi per `RepeatInterval` |

---

### Task 1: `filterHistory` dan `groupByDay`

**Files:**
- Create: `lib/models/history_view.dart`
- Test: `test/models/history_view_test.dart`

**Interfaces:**
- Consumes: `HistoryEntry`, `DocType`, `PaymentStatus` dari `lib/models/history_model.dart`. Field: `docType`, `paymentStatus`, `nomorDokumen`, `namaKlien`, `createdAt`.
- Produces:
  - `enum HistoryFilter { all, invoice, struk, unpaid }` (urutan = urutan tab)
  - `List<HistoryEntry> filterHistory(List<HistoryEntry> entries, HistoryFilter filter, String query)`
  - `List<(DateTime, List<HistoryEntry>)> groupByDay(List<HistoryEntry> entries)`

- [ ] **Step 1: Tulis test yang gagal**

`test/models/history_view_test.dart`:

```dart
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
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `/c/flutter/bin/flutter test test/models/history_view_test.dart`
Expected: FAIL, `history_view.dart` tidak ditemukan.

- [ ] **Step 3: Implementasi**

`lib/models/history_view.dart`:

```dart
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
```

- [ ] **Step 4: Jalankan test**

Run: `/c/flutter/bin/flutter test test/models/history_view_test.dart`
Expected: PASS, 7 test.
Run: `/c/flutter/bin/flutter analyze lib/models/history_view.dart test/models/history_view_test.dart`
Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/models/history_view.dart test/models/history_view_test.dart
git commit -m "feat: history filter and day grouping helpers"
```

---

### Task 2: Riwayat baru

**Files:**
- Modify: `lib/pages/history_page.dart` (baris 1-575)
- Modify: `lib/services/locale_service.dart`

**Interfaces:**
- Consumes: `filterHistory`, `groupByDay`, `HistoryFilter` (Task 1); `DashboardSummary.daysOverdue` (`lib/models/dashboard_summary.dart:70`); `StatusLabel`; `HistoryService.load/delete/add`; kunci yang ada `dashboard.loading`, `dashboard.retry`, `common.undo`, `history.*`.
- Produces: tidak ada API baru. `HistoryPage({bool unpaidOnly = false})` tetap (dipakai `main_navigation.dart:230`).

- [ ] **Step 1: Tambah kunci terjemahan**

Di `lib/services/locale_service.dart`, sisipkan setelah baris `'history.tap_to_change': ['Tap untuk ubah', 'Tap to change'],` (baris 91):

```dart
  'history.load_failed': ['Riwayat tidak bisa dimuat.', 'History could not be loaded.'],
  'history.no_unpaid': ['Tidak ada invoice belum dibayar', 'No unpaid invoices'],
  'history.no_match': ['Tidak ada dokumen yang cocok', 'No matching documents'],
  'history.clear_filter': ['Hapus filter', 'Clear filter'],
  'history.clear_search': ['Hapus pencarian', 'Clear search'],
  'history.today': ['Hari ini', 'Today'],
  'history.yesterday': ['Kemarin', 'Yesterday'],
  'history.days_late': ['Lewat {n} hari', '{n} days overdue'],
  'history.days_late_one': ['Lewat {n} hari', '{n} day overdue'],
  'history.deleted': ['"{name}" dihapus', '"{name}" deleted'],
```

- [ ] **Step 2: Tulis ulang `HistoryPage` dan `_HistoryPageState`**

Ganti seluruh baris 1 sampai 575 (`import 'package:flutter/material.dart';` sampai `}` penutup `_HistoryPageState`, tepat sebelum `// ─── Detail Bottom Sheet ───`) dengan kode berikut. `_DetailSheet` dan seterusnya tidak berubah; semua import lama tetap dibutuhkan olehnya.

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import '../main.dart';
import '../models/dashboard_summary.dart';
import '../models/history_model.dart';
import '../models/history_view.dart';
import '../models/faktur_model.dart';
import '../models/settings_model.dart';
import '../models/struk_model.dart';
import '../services/export_service.dart';
import '../services/history_service.dart';
import '../services/pdf_service.dart';
import '../services/settings_service.dart';
import '../services/struk_pdf_service.dart';
import '../pages/pdf_preview_page.dart';
import '../pages/faktur_page.dart';
import '../pages/struk_page.dart';
import '../services/locale_service.dart';
import '../widgets/status_label.dart';

class HistoryPage extends StatefulWidget {
  final bool unpaidOnly;

  const HistoryPage({super.key, this.unpaidOnly = false});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  List<HistoryEntry> _entries = [];
  List<HistoryEntry> _filtered = [];
  bool _isLoading = true;
  bool _showLoadingText = false;
  bool _failed = false;
  Timer? _loadingTimer;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late HistoryFilter _filter;
  late final TabController _tabCtrl;

  SettingsModel _settings = SettingsModel();

  NumberFormat get _currency => NumberFormat.currency(
        locale: _settings.currencyLocale,
        symbol: _settings.currencySymbol,
        decimalDigits: 0,
      );

  String get _dateLocale => LocaleService.isEn ? 'en_US' : 'id_ID';

  @override
  void initState() {
    super.initState();
    _filter = widget.unpaidOnly ? HistoryFilter.unpaid : HistoryFilter.all;
    _tabCtrl = TabController(
      length: HistoryFilter.values.length,
      initialIndex: _filter.index,
      vsync: this,
    );
    _load();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _tabCtrl.dispose();
    _searchCtrl.dispose();
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
      ]);
      if (!mounted) return;
      setState(() {
        _entries = results[0] as List<HistoryEntry>;
        _settings = results[1] as SettingsModel;
        _applyFilter();
        _isLoading = false;
        _failed = false;
      });
    } catch (e) {
      debugPrint('[History] load failed: $e');
      if (!mounted) return;
      if (!_isLoading) {
        // Failed refresh: keep the list already on screen.
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('history.load_failed'))));
      } else {
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

  void _applyFilter() {
    _filtered = filterHistory(_entries, _filter, _searchQuery);
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilter();
    });
  }

  void _onTab(int index) {
    setState(() {
      _filter = HistoryFilter.values[index];
      _applyFilter();
    });
  }

  void _clearFilter() {
    _searchCtrl.clear();
    _tabCtrl.index = 0;
    setState(() {
      _searchQuery = '';
      _filter = HistoryFilter.all;
      _applyFilter();
    });
  }

  Future<void> _exportCsv() async {
    if (_filtered.isEmpty) return;
    try {
      await ExportService.exportCsv(_filtered);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('common.export_fail')}: $e')),
        );
      }
    }
  }

  void _delete(HistoryEntry entry) {
    setState(() {
      _entries = [..._entries]..remove(entry);
      _applyFilter();
    });
    // Undo waits for this, so the restore never interleaves with the delete.
    final deleting = HistoryService.delete(entry.id).then((_) => true,
        onError: (Object e) {
      debugPrint('[History] delete failed: $e');
      return false;
    });
    deleting.then((ok) {
      if (!ok && mounted) _load();
    });
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(
            tr('history.deleted').replaceAll('{name}', entry.nomorDokumen)),
        duration: const Duration(seconds: 4),
        persist: false,
        action: SnackBarAction(
          label: tr('common.undo'),
          // Still runs after leaving the tab; only the reload needs this page.
          onPressed: () async {
            if (await deleting) await HistoryService.add(entry);
            if (mounted) _load();
          },
        ),
      ));
  }

  void _duplicateEntry(HistoryEntry entry) {
    if (entry.docType == DocType.invoice) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FakturPage(initialEntry: entry),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StrukPage(initialEntry: entry),
        ),
      );
    }
  }

  void _showDetail(HistoryEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetailSheet(
        entry: entry,
        currency: _currency,
        onDuplicate: () => _duplicateEntry(entry),
        onStatusChanged: (status) async {
          await HistoryService.updateStatus(entry.id, status);
          await _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('history.title')),
        actions: [
          if (_entries.isNotEmpty)
            TextButton(
              onPressed: _exportCsv,
              child: Text(tr('history.export_csv')),
            ),
        ],
      ),
      body: _body(theme),
    );
  }

  Widget _body(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: _showLoadingText
            ? Text(tr('dashboard.loading'), style: theme.textTheme.bodySmall)
            : const SizedBox.shrink(),
      );
    }
    if (_failed) {
      return Center(
        child: _message(theme, tr('history.load_failed'),
            tr('dashboard.retry'), _retry),
      );
    }
    if (_entries.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
          children: [
            Text(tr('history.empty'),
                style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(tr('history.empty_sub'),
                style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return Column(
      children: [
        _searchAndTabs(theme),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _filtered.isEmpty
                ? ListView(
                    children: [
                      _message(
                        theme,
                        _filter == HistoryFilter.unpaid && _searchQuery.isEmpty
                            ? tr('history.no_unpaid')
                            : tr('history.no_match'),
                        tr('history.clear_filter'),
                        _clearFilter,
                      ),
                    ],
                  )
                : _list(theme),
          ),
        ),
      ],
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

  Widget _searchAndTabs(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: tr('history.search'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: tr('history.clear_search'),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearch('');
                      },
                    ),
            ),
          ),
        ),
        TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          // 4 + the tab's own 16 lines the first label up with the 20dp page edge.
          padding: const EdgeInsets.symmetric(horizontal: 4),
          dividerColor: theme.dividerTheme.color,
          onTap: _onTab,
          tabs: [
            Tab(height: 48, text: tr('history.all')),
            Tab(height: 48, text: tr('history.invoice')),
            Tab(height: 48, text: tr('history.receipt')),
            Tab(height: 48, text: tr('history.unpaid')),
          ],
        ),
      ],
    );
  }

  Widget _list(ThemeData theme) {
    final width = MediaQuery.sizeOf(context).width;
    // Keep rows a readable width on tablets.
    final hPad = width >= 600 ? ((width - 680) / 2).clamp(20.0, 9999.0) : 20.0;
    final now = DateTime.now();
    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 32),
      children: [
        for (final (day, entries) in groupByDay(_filtered)) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Semantics(
              header: true,
              child: Text(_dayLabel(day, now),
                  style: theme.textTheme.bodySmall),
            ),
          ),
          const Divider(height: 1),
          for (final e in entries) ...[
            _entryRow(theme, e, now),
            const Divider(height: 1),
          ],
        ],
      ],
    );
  }

  String _dayLabel(DateTime day, DateTime now) {
    // UTC dates so a DST change cannot make a day 23 hours long.
    final ago = DateTime.utc(now.year, now.month, now.day)
        .difference(DateTime.utc(day.year, day.month, day.day))
        .inDays;
    if (ago == 0) return tr('history.today');
    if (ago == 1) return tr('history.yesterday');
    return DateFormat('d MMMM yyyy', _dateLocale).format(day);
  }

  Widget _entryRow(ThemeData theme, HistoryEntry e, DateTime now) {
    final isDark = theme.brightness == Brightness.dark;
    final type = e.docType == DocType.invoice
        ? tr('history.invoice')
        : tr('history.receipt');
    final method = e.metodeBayar;
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      resizeDuration: MediaQuery.disableAnimationsOf(context)
          ? null
          : const Duration(milliseconds: 200),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.errorFor(theme.brightness),
        child: Icon(Icons.delete_outline,
            // #0F1117 on #F87171 = 6.82:1; white on #B91C1C = 6.47:1.
            color: isDark ? const Color(0xFF0F1117) : Colors.white,
            semanticLabel: tr('common.delete')),
      ),
      onDismissed: (_) => _delete(e),
      child: InkWell(
        onTap: () => _showDetail(e),
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
                    Text(
                      [
                        e.nomorDokumen,
                        type,
                        if (method != null && method.isNotEmpty) method,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_currency.format(e.totalAmount),
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  _status(theme, e, now),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _status(ThemeData theme, HistoryEntry e, DateTime now) {
    final b = theme.brightness;
    if (e.docType == DocType.struk || e.paymentStatus == PaymentStatus.paid) {
      return StatusLabel(
          text: tr('history.paid'), color: AppColors.successFor(b));
    }
    final late = e.jatuhTempo == null ? 0 : DashboardSummary.daysOverdue(e, now);
    if (late > 0) {
      return StatusLabel(
          text: trN('history.days_late', late), color: AppColors.errorFor(b));
    }
    return StatusLabel(
        text: tr('history.unpaid'), color: AppColors.warningFor(b));
  }
}
```

Catatan: `_showDetail` dan `_duplicateEntry` disalin apa adanya dari kode lama (baris 155-190).

- [ ] **Step 3: Analyze + test**

Run: `/c/flutter/bin/flutter analyze lib/pages/history_page.dart lib/services/locale_service.dart`
Expected: No issues found.
Run: `grep -nE "_confirmDeleteEntry|_filterChip|_buildEntryCard|_typeFilter|_paymentFilter|CircularProgressIndicator" lib/pages/history_page.dart`
Expected: tidak ada output.
Run: `awk 'NR<=575' lib/pages/history_page.dart | grep -c GoogleFonts`
Expected: `0` (sisa `GoogleFonts` hanya di `_DetailSheet`).
Run: `/c/flutter/bin/flutter analyze 2>&1 | tail -1`
Expected: `9 issues found.`
Run: `/c/flutter/bin/flutter test`
Expected: semua lulus (114 + 7).

- [ ] **Step 4: Commit**

```bash
git add lib/pages/history_page.dart lib/services/locale_service.dart
git commit -m "feat: plain grouped history with tabs and undo delete"
```

---

### Task 3: Daftar dan sheet detail Pengingat

**Files:**
- Modify: `lib/pages/reminder_page.dart` (baris 1-711)
- Modify: `lib/services/locale_service.dart`
- Test: `test/services/locale_service_test.dart`

**Interfaces:**
- Consumes: `StatusLabel`; `AppColors.errorFor/warningFor/successFor`; `ReminderModel.isOverdue/isDue/isRepeating/repeatInterval`; kunci yang ada `reminder.*`, `dashboard.today`, `dashboard.loading`, `common.delete/cancel`.
- Produces: tidak ada API baru.

- [ ] **Step 1: Tulis test kunci ulangi yang gagal**

Di `test/services/locale_service_test.dart`, tambah import:

```dart
import 'package:faktur_gen/models/reminder_model.dart';
```

dan di dalam `main()` setelah test yang ada:

```dart
  test('every repeat interval has a translated label', () {
    for (final r in RepeatInterval.values) {
      final key = 'reminder.repeat_${r.name}';
      expect(tr(key), isNot(key));
    }
  });
```

Run: `/c/flutter/bin/flutter test test/services/locale_service_test.dart`
Expected: FAIL (`tr` mengembalikan kunci mentah).

- [ ] **Step 2: Tambah kunci terjemahan**

Di `lib/services/locale_service.dart`, sisipkan setelah `'reminder.waiting': ['Menunggu', 'Waiting'],` (baris 132):

```dart
  'reminder.marked_done_msg': ['{service} untuk {name} ditandai selesai', '{service} for {name} marked as done'],
  'reminder.delete_body': ['Hapus "{service}" untuk {name}?', 'Delete "{service}" for {name}?'],
  'reminder.wa_message': ['Halo {name}, ini pengingat untuk layanan *{service}* yang dijadwalkan tanggal {date}.{notes}\n\nTerima kasih 🙏', 'Hi {name}, this is a reminder for *{service}* scheduled on {date}.{notes}\n\nThank you 🙏'],
  'reminder.wa_notes': ['\n\nCatatan: {notes}', '\n\nNotes: {notes}'],
  'reminder.repeat_none': ['Tidak Berulang', 'Does not repeat'],
  'reminder.repeat_monthly': ['Setiap 1 Bulan', 'Every month'],
  'reminder.repeat_bimonthly': ['Setiap 2 Bulan', 'Every 2 months'],
  'reminder.repeat_quarterly': ['Setiap 3 Bulan', 'Every 3 months'],
  'reminder.repeat_semiannual': ['Setiap 6 Bulan', 'Every 6 months'],
  'reminder.repeat_annual': ['Setiap 1 Tahun', 'Every year'],
```

dan setelah `'common.import_fail': ['Gagal import', 'Import failed'],` (baris 374):

```dart
  'common.phone': ['Telepon', 'Phone'],
  'common.address': ['Alamat', 'Address'],
```

Run: `/c/flutter/bin/flutter test test/services/locale_service_test.dart`
Expected: PASS.

- [ ] **Step 3: Import**

Di `lib/pages/reminder_page.dart` baris 1-2:

Old:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
```
New:
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
```

Setelah `import '../services/reminder_service.dart';` tambah:
```dart
import '../widgets/status_label.dart';
```

(`google_fonts` masih dipakai sheet sampai Task 4.)

- [ ] **Step 4: State, format tanggal, muat tertunda**

Old (baris 21-50):
```dart
class _ReminderPageState extends State<ReminderPage>
    with SingleTickerProviderStateMixin {
  List<ReminderModel> _reminders = [];
  bool _isLoading = true;
  late TabController _tabCtrl;

  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await ReminderService.loadAll();
      if (mounted) setState(() { _reminders = list; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('[Reminder] load error: $e');
    }
  }
```
New:
```dart
class _ReminderPageState extends State<ReminderPage>
    with SingleTickerProviderStateMixin {
  List<ReminderModel> _reminders = [];
  bool _isLoading = true;
  bool _showLoadingText = false;
  Timer? _loadingTimer;
  late TabController _tabCtrl;

  DateFormat get _dateFormat =>
      DateFormat('dd MMM yyyy', LocaleService.isEn ? 'en_US' : 'id_ID');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _loadingTimer?.cancel();
    // A fast load should not flash a loading message.
    _loadingTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _isLoading) setState(() => _showLoadingText = true);
    });
    try {
      final list = await ReminderService.loadAll();
      if (mounted) setState(() { _reminders = list; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('[Reminder] load error: $e');
    } finally {
      _loadingTimer?.cancel();
    }
  }
```

- [ ] **Step 5: Snackbar tandai selesai**

Old (baris 83):
```dart
          content: Text('${r.serviceName} untuk ${r.contactName} ${tr('reminder.marked_done')}'),
```
New:
```dart
          content: Text(tr('reminder.marked_done_msg')
              .replaceAll('{service}', r.serviceName)
              .replaceAll('{name}', r.contactName)),
```

- [ ] **Step 6: Pesan WhatsApp**

Old (baris 165-169):
```dart
    final message = 'Halo ${r.contactName}, ini pengingat untuk layanan '
        '*${r.serviceName}* yang dijadwalkan tanggal '
        '${_dateFormat.format(r.reminderDate)}.'
        '${r.notes.isNotEmpty ? '\n\nCatatan: ${r.notes}' : ''}'
        '\n\nTerima kasih 🙏';
```
New:
```dart
    final notes = r.notes.isEmpty
        ? ''
        : tr('reminder.wa_notes').replaceAll('{notes}', r.notes);
    // {notes} last, so placeholders typed inside the notes stay literal.
    final message = tr('reminder.wa_message')
        .replaceAll('{name}', r.contactName)
        .replaceAll('{service}', r.serviceName)
        .replaceAll('{date}', _dateFormat.format(r.reminderDate))
        .replaceAll('{notes}', notes);
```

- [ ] **Step 7: Sheet detail, daftar, baris, hapus**

Ganti dari `  void _showDetail(ReminderModel r) {` (baris 182) sampai `}` penutup kelas `_ReminderPageState` (baris 711, tepat sebelum blok komentar `// Add Reminder Sheet`) dengan:

```dart
  String _when(ReminderModel r) =>
      '${_dateFormat.format(r.reminderDate)}, '
      '${r.reminderHour.toString().padLeft(2, '0')}:'
      '${r.reminderMinute.toString().padLeft(2, '0')}';

  String _repeatLabel(ReminderModel r) =>
      tr('reminder.repeat_${r.repeatInterval.name}');

  void _showDetail(ReminderModel r) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          // Scrolls instead of overflowing at large text sizes.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('reminder.detail_title'),
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                _detailRow(theme, Icons.person_outlined, tr('reminder.customer'), r.contactName),
                if (r.contactPhone.isNotEmpty)
                  _detailRow(theme, Icons.phone_outlined, tr('common.phone'), r.contactPhone),
                if (r.contactAddress.isNotEmpty)
                  _detailRow(theme, Icons.location_on_outlined, tr('common.address'), r.contactAddress),
                _detailRow(theme, Icons.build_outlined, tr('reminder.service'), r.serviceName),
                _detailRow(theme, Icons.calendar_today, tr('reminder.date'), _when(r)),
                if (r.isRepeating)
                  _detailRow(theme, Icons.repeat, tr('reminder.repeat'), _repeatLabel(r)),
                if (r.notes.isNotEmpty)
                  _detailRow(theme, Icons.notes_outlined, tr('reminder.notes'), r.notes),
                _detailRow(
                  theme,
                  Icons.info_outline,
                  tr('reminder.status'),
                  r.isOverdue
                      ? tr('reminder.overdue')
                      : r.isDue
                          ? tr('reminder.due_today')
                          : r.status == ReminderStatus.pending
                              ? tr('reminder.waiting')
                              : tr('reminder.done'),
                ),
                const SizedBox(height: 4),
                const Divider(height: 1),
                if (r.contactPhone.isNotEmpty)
                  _actionTile(
                    theme,
                    icon: Icons.message_outlined,
                    label: tr('reminder.send_wa'),
                    onTap: () {
                      Navigator.pop(context);
                      _sendWhatsApp(r);
                    },
                  ),
                if (r.hasLastItems)
                  _actionTile(
                    theme,
                    icon: r.docType == ReminderDocType.struk
                        ? Icons.receipt_outlined
                        : Icons.receipt_long_outlined,
                    label: r.docType == ReminderDocType.struk
                        ? tr('reminder.create_receipt')
                        : tr('reminder.create_invoice'),
                    onTap: () {
                      Navigator.pop(context);
                      _createDocFromReminder(r);
                    },
                  ),
                _actionTile(
                  theme,
                  icon: Icons.edit_outlined,
                  label: tr('reminder.edit_title'),
                  onTap: () {
                    Navigator.pop(context);
                    _editReminder(r);
                  },
                ),
                if (r.status == ReminderStatus.pending) ...[
                  _actionTile(
                    theme,
                    icon: Icons.event_repeat_rounded,
                    label: tr('reminder.reschedule'),
                    onTap: () {
                      Navigator.pop(context);
                      _reschedule(r);
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _markDone(r);
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(tr('reminder.mark_done')),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _actionTile(
                  theme,
                  icon: Icons.delete_outline,
                  label: tr('common.delete'),
                  color: AppColors.errorFor(theme.brightness),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(r);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(ThemeData theme, IconData icon, String label, String value) {
    final muted = theme.textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: muted?.color),
          const SizedBox(width: 12),
          // Label above the value, so long labels survive 200% text.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: muted),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: theme.textTheme.bodyLarge?.copyWith(color: c)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('reminder.title')),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(text: '${tr('reminder.active')} (${_pending.length})'),
            Tab(text: '${tr('reminder.done')} (${_completed.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        tooltip: tr('reminder.add_title'),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? Center(
              child: _showLoadingText
                  ? Text(tr('dashboard.loading'),
                      style: theme.textTheme.bodySmall)
                  : const SizedBox.shrink(),
            )
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(theme, _pending, isPending: true),
                _buildList(theme, _completed, isPending: false),
              ],
            ),
    );
  }

  Widget _buildList(ThemeData theme, List<ReminderModel> list,
      {required bool isPending}) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
          children: [
            Text(
              isPending
                  ? tr('reminder.empty_pending')
                  : tr('reminder.empty_done'),
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (isPending) ...[
              const SizedBox(height: 4),
              Text(tr('reminder.add_hint'),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        // Bottom room so the FAB never covers the last row.
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.paddingOf(context).bottom + 80),
        itemCount: list.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) => _buildRow(theme, list[i], isPending: isPending),
      ),
    );
  }

  Widget _buildRow(ThemeData theme, ReminderModel r,
      {required bool isPending}) {
    final error = AppColors.errorFor(theme.brightness);
    final repeat = r.isRepeating ? ' · ${_repeatLabel(r)}' : '';

    final row = InkWell(
      onTap: () => _showDetail(r),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.contactName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (r.serviceName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(r.serviceName,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 2),
                  Text('${_when(r)}$repeat', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (r.isOverdue) ...[
              const SizedBox(width: 12),
              StatusLabel(text: tr('reminder.overdue'), color: error),
            ] else if (r.isDue) ...[
              const SizedBox(width: 12),
              StatusLabel(
                  text: tr('dashboard.today'),
                  color: AppColors.warningFor(theme.brightness)),
            ],
          ],
        ),
      ),
    );

    final deleteBg = _swipeBackground(theme,
        alignment: Alignment.centerRight,
        color: error,
        icon: Icons.delete_outline,
        label: tr('common.delete'));

    if (!isPending) {
      // Completed: swipe left to delete only
      return Dismissible(
        key: ValueKey(r.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDelete(r),
        background: deleteBg,
        child: row,
      );
    }

    // Pending: swipe right=done, left=delete
    return Dismissible(
      key: ValueKey(r.id),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          _markDone(r);
          return false; // don't remove, _markDone reloads
        } else {
          return _confirmDelete(r);
        }
      },
      background: _swipeBackground(theme,
          alignment: Alignment.centerLeft,
          color: AppColors.successFor(theme.brightness),
          icon: Icons.check_rounded,
          label: tr('reminder.mark_done')),
      secondaryBackground: deleteBg,
      child: row,
    );
  }

  Future<bool> _confirmDelete(ReminderModel r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('reminder.delete_title')),
        content: Text(tr('reminder.delete_body')
            .replaceAll('{service}', r.serviceName)
            .replaceAll('{name}', r.contactName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('common.delete'),
                style: TextStyle(
                    color: AppColors.errorFor(Theme.of(ctx).brightness))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ReminderService.delete(r.id);
      _load();
      return true;
    }
    return false;
  }

  Widget _swipeBackground(
    ThemeData theme, {
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon,
          // White on the light colors, #0F1117 on the dark-mode ones; all >= 5.48:1.
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF0F1117)
              : Colors.white,
          semanticLabel: label),
    );
  }
}
```

- [ ] **Step 8: Analyze + test**

Run: `/c/flutter/bin/flutter analyze lib/pages/reminder_page.dart lib/services/locale_service.dart test/services/locale_service_test.dart`
Expected: No issues found.
Run: `grep -nE "Color\(0xFF(25D366|059669|2563EB)\)|untuk \\\$\{|Terima kasih|CircularProgressIndicator|_buildCard|\.label\b" lib/pages/reminder_page.dart`
Expected: tidak ada output.
Run: `grep -c GoogleFonts lib/pages/reminder_page.dart`
Expected: `7` (sisa di sheet, dikerjakan Task 4).
Run: `/c/flutter/bin/flutter analyze 2>&1 | tail -1`
Expected: `9 issues found.`
Run: `/c/flutter/bin/flutter test`
Expected: semua lulus.

- [ ] **Step 9: Commit**

```bash
git add lib/pages/reminder_page.dart lib/services/locale_service.dart test/services/locale_service_test.dart
git commit -m "feat: restyle reminder list and detail sheet"
```

---

### Task 4: Sheet tambah pengingat dan sheet kontak

**Files:**
- Modify: `lib/pages/reminder_page.dart` (kelas `_AddReminderSheetState`, `_ContactManagerSheetState`, `_ContactFormSheetState`)
- Modify: `lib/services/locale_service.dart`

**Interfaces:**
- Consumes: kunci Task 3 (`reminder.repeat_*`); `AppColors.errorFor`.
- Produces: tidak ada API baru.

Nomor baris di bawah adalah nomor **sebelum Task 3**; Task 3 menggeser semuanya. Cari dengan isi teks.

- [ ] **Step 1: Tambah kunci terjemahan**

Di `lib/services/locale_service.dart`, setelah `'reminder.repeat_annual': ...` (dari Task 3):

```dart
  'reminder.preset_ac_wash': ['Cuci AC', 'AC cleaning'],
  'reminder.preset_ac_service': ['Service AC', 'AC service'],
  'reminder.preset_ac_filter': ['Ganti Filter AC', 'AC filter change'],
  'reminder.preset_routine': ['Perawatan Rutin', 'Routine maintenance'],
  'reminder.preset_engine': ['Service Mesin', 'Engine service'],
  'reminder.preset_check': ['Pengecekan Berkala', 'Periodic check'],
  'reminder.months': ['{n} Bulan', '{n} months'],
  'reminder.months_one': ['{n} Bulan', '{n} month'],
  'reminder.one_year': ['1 Tahun', '1 year'],
```

Setelah `'contact.name': ['Nama', 'Name'],` (baris 143):

```dart
  'contact.empty_hint': ['Tap "Tambah" untuk menambah kontak baru', 'Tap "Add" to add a new contact'],
```

Setelah `'common.address': ...` (dari Task 3):

```dart
  'common.required': ['Wajib diisi', 'Required'],
```

- [ ] **Step 2: Import**

Hapus baris `import 'package:google_fonts/google_fonts.dart';`. Setelah step ini tidak ada lagi `GoogleFonts` di file.

- [ ] **Step 3: `_AddReminderSheetState`: format tanggal dan preset**

Old (baris 740-749):
```dart
  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  final _presetServices = [
    'Cuci AC',
    'Service AC',
    'Ganti Filter AC',
    'Perawatan Rutin',
    'Service Mesin',
    'Pengecekan Berkala',
  ];
```
New:
```dart
  DateFormat get _dateFormat =>
      DateFormat('dd MMM yyyy', LocaleService.isEn ? 'en_US' : 'id_ID');

  static const _presetServiceKeys = [
    'reminder.preset_ac_wash',
    'reminder.preset_ac_service',
    'reminder.preset_ac_filter',
    'reminder.preset_routine',
    'reminder.preset_engine',
    'reminder.preset_check',
  ];
```

- [ ] **Step 4: `_showContactPicker` pakai drag handle tema**

Old (baris 792-797):
```dart
    final selected = await showModalBottomSheet<ContactModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ContactManagerSheet(
```
New:
```dart
    final selected = await showModalBottomSheet<ContactModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ContactManagerSheet(
```

- [ ] **Step 5: Kepala sheet tambah pengingat**

`_addReminder`/`_editReminder` memakai `enableDrag: false` (form tidak boleh hilang karena tergeser), jadi pegangan palsu dihapus dan tidak diganti `showDragHandle`.

Old (baris 871-900):
```dart
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? tr('reminder.edit_title') : tr('reminder.add_title'),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                  tooltip: tr('common.close'),
                ),
              ],
            ),
```
New:
```dart
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? tr('reminder.edit_title') : tr('reminder.add_title'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: tr('common.close'),
                ),
              ],
            ),
```

- [ ] **Step 6: Tombol pilih kontak tanpa latar aksen**

Old (baris 914-921):
```dart
                IconButton(
                  onPressed: _showContactPicker,
                  icon: const Icon(Icons.contacts_outlined),
                  tooltip: tr('reminder.pick_contact'),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                  ),
                ),
```
New:
```dart
                IconButton(
                  onPressed: _showContactPicker,
                  icon: const Icon(Icons.contacts_outlined),
                  tooltip: tr('reminder.pick_contact'),
                ),
```

- [ ] **Step 7: "Wajib diisi" (3 tempat di file)**

Ganti semua `? 'Wajib diisi' : null` dengan `? tr('common.required') : null` (baris 910, 949, 1439).

- [ ] **Step 8: Chip preset layanan**

Old (baris 955-961):
```dart
              children: _presetServices.map((s) {
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _serviceCtrl.text = s),
                );
              }).toList(),
```
New:
```dart
              children: _presetServiceKeys.map((key) {
                final s = tr(key);
                return ActionChip(
                  label: Text(s),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _serviceCtrl.text = s),
                );
              }).toList(),
```

- [ ] **Step 9: Teks tanggal/jam tanpa ukuran literal**

Dua tempat (baris 976-979 dan 994-997):

Old:
```dart
                      child: Text(
                        _dateFormat.format(_reminderDate),
                        style: const TextStyle(fontSize: 14),
                      ),
```
New:
```dart
                      child: Text(_dateFormat.format(_reminderDate)),
```

Old:
```dart
                      child: Text(
                        _reminderTime.format(context),
                        style: const TextStyle(fontSize: 14),
                      ),
```
New:
```dart
                      child: Text(_reminderTime.format(context)),
```

- [ ] **Step 10: Chip tanggal cepat**

Old (baris 1008-1012):
```dart
                _quickDateChip('1 Bulan', 30),
                _quickDateChip('2 Bulan', 60),
                _quickDateChip('3 Bulan', 90),
                _quickDateChip('6 Bulan', 180),
                _quickDateChip('1 Tahun', 365),
```
New:
```dart
                _quickDateChip(trN('reminder.months', 1), 30),
                _quickDateChip(trN('reminder.months', 2), 60),
                _quickDateChip(trN('reminder.months', 3), 90),
                _quickDateChip(trN('reminder.months', 6), 180),
                _quickDateChip(tr('reminder.one_year'), 365),
```

Old (baris 1058):
```dart
      label: Text(label, style: const TextStyle(fontSize: 11)),
```
New:
```dart
      label: Text(label),
```

- [ ] **Step 11: Dropdown ulangi**

Old (baris 1022-1025):
```dart
              items: RepeatInterval.values
                  .map((r) =>
                      DropdownMenuItem(value: r, child: Text(r.label)))
                  .toList(),
```
New:
```dart
              items: RepeatInterval.values
                  .map((r) => DropdownMenuItem(
                      value: r, child: Text(tr('reminder.repeat_${r.name}'))))
                  .toList(),
```

- [ ] **Step 12: `_ContactManagerSheetState`: sheet tambah/edit kontak**

Di `_addContact` dan `_editContact` (baris 1131-1133 dan 1146-1148), ganti blok:
```dart
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
```
dengan:
```dart
      showDragHandle: true,
```
Hanya dua blok ini di kelas `_ContactManagerSheetState`. Blok yang sama di `_addReminder`/`_editReminder` (kelas halaman) dibiarkan.

- [ ] **Step 13: Dialog hapus kontak**

Old (baris 1170):
```dart
            child: Text(tr('common.delete'), style: const TextStyle(color: Colors.red)),
```
New:
```dart
            child: Text(tr('common.delete'),
                style: TextStyle(
                    color: AppColors.errorFor(Theme.of(ctx).brightness))),
```

- [ ] **Step 14: `build` sheet kontak**

Ganti seluruh method `build` di `_ContactManagerSheetState` (dari `  @override\n  Widget build(BuildContext context) {\n    final theme = Theme.of(context);\n    return DraggableScrollableSheet(` di baris 1181 sampai `}` penutup method di baris 1351, tepat sebelum `}` penutup kelas) dengan:

```dart
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = AppColors.errorFor(theme.brightness);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(tr('contact.title'),
                            style: theme.textTheme.titleMedium),
                      ),
                      TextButton.icon(
                        onPressed: _addContact,
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: Text(tr('contact.add')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: tr('contact.search'),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _contacts.isEmpty
                                  ? tr('contact.empty')
                                  : tr('contact.not_found'),
                              style: theme.textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            if (_contacts.isEmpty) ...[
                              const SizedBox(height: 4),
                              Text(tr('contact.empty_hint'),
                                  style: theme.textTheme.bodySmall,
                                  textAlign: TextAlign.center),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 24),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (_, i) {
                        final c = _filtered[i];
                        final initials = c.nama.isNotEmpty
                            ? c.nama
                                .split(' ')
                                .take(2)
                                .map((w) =>
                                    w.isNotEmpty ? w[0].toUpperCase() : '')
                                .join()
                            : '?';
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            child: Text(initials),
                          ),
                          title: Text(c.nama,
                              style: theme.textTheme.titleSmall),
                          subtitle: c.telepon.isNotEmpty
                              ? Text(c.telepon,
                                  style: theme.textTheme.bodySmall)
                              : null,
                          onTap: () => Navigator.pop(context, c),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (v) {
                              if (v == 'edit') _editContact(c);
                              if (v == 'delete') _deleteContact(c);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: const Icon(Icons.edit_outlined),
                                  title: Text(tr('common.edit')),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline,
                                      color: error),
                                  title: Text(tr('common.delete'),
                                      style: TextStyle(color: error)),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
```

- [ ] **Step 15: `_ContactFormSheetState`: kepala sheet**

Old (baris 1408-1434):
```dart
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditing ? tr('contact.edit_title') : tr('contact.add_title'),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
```
New (sheet ini sekarang memakai `showDragHandle`, jadi padding atas 0):
```dart
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? tr('contact.edit_title') : tr('contact.add_title'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
```

- [ ] **Step 16: Verifikasi**

Run: `grep -nE "GoogleFonts|fontSize|Colors\.red|withValues\(alpha|'Wajib|Bulan'|Tahun'|'Tap \"|\.label\)" lib/pages/reminder_page.dart`
Expected: tidak ada output.
Run: `grep -nE "Text\(\s*'[A-Z]|title: '|labelText: '|hintText: '" lib/pages/reminder_page.dart`
Expected: tidak ada output.
Run: `/c/flutter/bin/flutter analyze lib/pages/reminder_page.dart lib/services/locale_service.dart`
Expected: No issues found.
Run: `/c/flutter/bin/flutter analyze 2>&1 | tail -1`
Expected: `9 issues found.`
Run: `/c/flutter/bin/flutter test`
Expected: semua lulus.

- [ ] **Step 17: Commit**

```bash
git add lib/pages/reminder_page.dart lib/services/locale_service.dart
git commit -m "feat: restyle reminder and contact sheets"
```

---

### Task 5: Sheet detail Riwayat (`_DetailSheet`)

**Files:**
- Modify: `lib/pages/history_page.dart` (`_HistoryPageState._showDetail` dari Task 2, dan `_DetailSheetState`)
- Modify: `lib/services/locale_service.dart`

**Interfaces:**
- Consumes: `StatusLabel`; `AppColors.successFor/warningFor`; `HistoryItem` (`nama`, `kuantitas`, `satuan`, `hargaSatuan`, `subtotal`); kunci yang ada `history.invoice/receipt/paid/unpaid/tap_to_change/duplicate`, `common.total`, `invoice.preview_title`.
- Produces: tidak ada API baru. Konstruktor `_DetailSheet` tidak berubah.

Nomor baris di bawah adalah nomor **sebelum Task 2** (file asli). Task 2 menggeser semuanya; cari dengan isi teks. Perilaku tetap: cetak membuka `PdfPreviewPage`, tap status mengganti lunas/belum lunas lewat `onStatusChanged`, "Buat ulang" menutup sheet lalu memanggil `onDuplicate`.

- [ ] **Step 1: Tambah kunci terjemahan**

Di `lib/services/locale_service.dart`, setelah `'history.deleted': ...` (dari Task 2):

```dart
  'history.print': ['Cetak', 'Print'],
  'history.doc_info': ['Informasi dokumen', 'Document info'],
  'history.doc_date': ['Tanggal dokumen', 'Document date'],
  'history.created_at': ['Dibuat pada', 'Created at'],
  'history.due_date': ['Jatuh tempo', 'Due date'],
  'history.seller': ['Penjual', 'Seller'],
  'history.buyer': ['Pembeli', 'Buyer'],
  'history.buyer_npwp': ['NPWP pembeli', 'Buyer tax ID'],
  'history.buyer_phone': ['Telepon pembeli', 'Buyer phone'],
  'history.buyer_address': ['Alamat pembeli', 'Buyer address'],
  'history.store': ['Toko', 'Store'],
  'history.store_address': ['Alamat toko', 'Store address'],
  'history.cashier': ['Kasir', 'Cashier'],
  'history.items_invoice': ['Item / layanan', 'Items / services'],
  'history.items_receipt': ['Daftar barang', 'Items'],
  'history.summary': ['Ringkasan', 'Summary'],
  'history.notes': ['Catatan', 'Notes'],
  'history.dpp': ['DPP', 'Tax base'],
  'history.ppn': ['PPN ({rate}%)', 'VAT ({rate}%)'],
  'history.subtotal': ['Subtotal', 'Subtotal'],
  'history.discount': ['Diskon', 'Discount'],
  'history.method': ['Metode', 'Method'],
  'history.paid_amount': ['Bayar', 'Paid'],
  'history.change': ['Kembalian', 'Change'],
  'history.payment_status': ['Status pembayaran', 'Payment status'],
  'history.preview_receipt': ['Preview Struk', 'Receipt Preview'],
```

(`history.preview_receipt`, bukan `struk.*`, supaya tidak bentrok dengan rencana form struk.)

- [ ] **Step 2: Pegangan tarik dari tema**

Di `_HistoryPageState._showDetail` (kode Task 2):

Old:
```dart
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetailSheet(
```
New:
```dart
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DetailSheet(
```

- [ ] **Step 3: Tulis ulang `build` `_DetailSheetState`**

Ganti seluruh method `build` (file asli baris 607-867: dari `  @override\n  Widget build(BuildContext context) {\n    final theme = Theme.of(context);\n    final isDark = theme.brightness == Brightness.dark;` sampai `}` penutup method, tepat sebelum `  Future<void> _handlePrint(BuildContext context) async {`) dengan:

```dart
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInvoice = entry.docType == DocType.invoice;
    final paid = entry.paymentStatus == PaymentStatus.paid;
    final locale = LocaleService.isEn ? 'en_US' : 'id_ID';
    final dateFmt = DateFormat('dd MMMM yyyy', locale);
    final dateTimeFmt = DateFormat('dd MMM yyyy, HH:mm', locale);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          isInvoice
                              ? tr('history.invoice')
                              : tr('history.receipt'),
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 2),
                      Text(entry.nomorDokumen,
                          style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _handlePrint(context),
                  icon: const Icon(Icons.print_outlined),
                  tooltip: tr('history.print'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _sectionTitle(theme, tr('history.doc_info')),
            _infoRow(theme, tr('history.doc_date'),
                dateFmt.format(entry.tanggalDokumen)),
            _infoRow(theme, tr('history.created_at'),
                dateTimeFmt.format(entry.createdAt)),
            if (isInvoice) ...[
              if (entry.jatuhTempo != null)
                _infoRow(theme, tr('history.due_date'),
                    dateFmt.format(entry.jatuhTempo!)),
              if (entry.namaPenjual != null && entry.namaPenjual!.isNotEmpty)
                _infoRow(theme, tr('history.seller'), entry.namaPenjual!),
              if (entry.namaKlien.isNotEmpty)
                _infoRow(theme, tr('history.buyer'), entry.namaKlien),
              if (entry.npwpPembeli != null && entry.npwpPembeli!.isNotEmpty)
                _infoRow(theme, tr('history.buyer_npwp'), entry.npwpPembeli!),
              if (entry.teleponPembeli != null &&
                  entry.teleponPembeli!.isNotEmpty)
                _infoRow(
                    theme, tr('history.buyer_phone'), entry.teleponPembeli!),
              if (entry.alamatPembeli != null &&
                  entry.alamatPembeli!.isNotEmpty)
                _infoRow(
                    theme, tr('history.buyer_address'), entry.alamatPembeli!),
            ] else ...[
              if (entry.namaToko != null && entry.namaToko!.isNotEmpty)
                _infoRow(theme, tr('history.store'), entry.namaToko!),
              if (entry.alamatToko != null && entry.alamatToko!.isNotEmpty)
                _infoRow(theme, tr('history.store_address'), entry.alamatToko!),
              if (entry.namaKasir != null && entry.namaKasir!.isNotEmpty)
                _infoRow(theme, tr('history.cashier'), entry.namaKasir!),
            ],

            if (entry.items.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionTitle(
                  theme,
                  isInvoice
                      ? tr('history.items_invoice')
                      : tr('history.items_receipt')),
              const Divider(height: 1),
              for (final item in entry.items) ...[
                _itemRow(theme, item),
                const Divider(height: 1),
              ],
            ],

            const SizedBox(height: 24),
            _sectionTitle(theme, tr('history.summary')),
            ..._totals(theme),

            if (entry.catatan.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionTitle(theme, tr('history.notes')),
              Text(entry.catatan, style: theme.textTheme.bodyMedium),
            ],

            if (isInvoice) ...[
              const SizedBox(height: 24),
              const Divider(height: 1),
              InkWell(
                onTap: () async {
                  final newStatus =
                      paid ? PaymentStatus.unpaid : PaymentStatus.paid;
                  await widget.onStatusChanged?.call(newStatus);
                  setState(() => entry.paymentStatus = newStatus);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('history.payment_status'),
                                style: theme.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            StatusLabel(
                              text: paid
                                  ? tr('history.paid')
                                  : tr('history.unpaid'),
                              color: paid
                                  ? AppColors.successFor(theme.brightness)
                                  : AppColors.warningFor(theme.brightness),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(tr('history.tap_to_change'),
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onDuplicate?.call();
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(tr('history.duplicate')),
              ),
            ),
          ],
        );
      },
    );
  }
```

- [ ] **Step 4: Judul preview cetak**

Di `_handlePrint`:

Old (file asli baris 904):
```dart
            title: 'Preview Invoice',
```
New:
```dart
            title: tr('invoice.preview_title'),
```

Old (file asli baris 939):
```dart
            title: 'Preview Struk',
```
New:
```dart
            title: tr('history.preview_receipt'),
```

Nama file PDF (`'Invoice_...pdf'`, `'Struk_...pdf'`) tidak diubah.

- [ ] **Step 5: Ganti helper tampilan**

Ganti dari `  Widget _sectionTitle(String title, IconData icon, Color color) {` (file asli baris 963) sampai `}` penutup `_totalRow` (file asli baris 1225, tepat sebelum `  String _fmtQty(double v) => v == v.roundToDouble()`) dengan:

```dart
  Widget _sectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        header: true,
        child: Text(title, style: theme.textTheme.titleMedium),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    // Label above the value, so long labels survive 200% text.
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _itemRow(ThemeData theme, HistoryItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nama, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  '${_fmtQty(item.kuantitas)} ${item.satuan} × '
                  '${currency.format(item.hargaSatuan)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(currency.format(item.subtotal),
              style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  List<Widget> _totals(ThemeData theme) {
    Widget row(String label, String value, {bool bold = false}) {
      final style =
          bold ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            const SizedBox(width: 12),
            Text(value, style: style),
          ],
        ),
      );
    }

    if (entry.docType == DocType.invoice) {
      return [
        if (entry.totalDpp != null)
          row(tr('history.dpp'), currency.format(entry.totalDpp!)),
        if (entry.totalPpn != null)
          // Old entries have no taxRate; 11 is FakturModel's default.
          row(tr('history.ppn').replaceAll('{rate}', _fmtQty(entry.taxRate ?? 11)),
              currency.format(entry.totalPpn!)),
        row(tr('common.total'), currency.format(entry.totalAmount),
            bold: true),
      ];
    }
    return [
      row(tr('history.subtotal'),
          currency.format(entry.totalAmount + (entry.diskon ?? 0))),
      if (entry.diskon != null && entry.diskon! > 0)
        row(tr('history.discount'), '- ${currency.format(entry.diskon!)}'),
      row(tr('common.total'), currency.format(entry.totalAmount), bold: true),
      if (entry.metodeBayar != null)
        row(tr('history.method'), entry.metodeBayar!),
      if (entry.jumlahBayar != null && entry.jumlahBayar! > 0)
        row(tr('history.paid_amount'), currency.format(entry.jumlahBayar!)),
      if (entry.kembalian != null && entry.kembalian! > 0)
        row(tr('history.change'), currency.format(entry.kembalian!),
            bold: true),
    ];
  }
```

`_buildItemsTable`, `_buildTotals`, `_totalRow` hilang bersama blok ini; `_handlePrint`, `_parseMetodeBayar`, `_fmtQty` tetap.

- [ ] **Step 6: Import**

Hapus baris `import 'package:google_fonts/google_fonts.dart';` dari `lib/pages/history_page.dart`; setelah step 3 dan 5 tidak ada lagi pemakainya.

- [ ] **Step 7: Analyze + test**

Run: `grep -nE "GoogleFonts|fontSize|withValues\(alpha|Colors\.red|_buildItemsTable|_buildTotals|_totalRow" lib/pages/history_page.dart`
Expected: tidak ada output.
Run: `grep -nE "Text\(\s*'[A-Z]|_infoRow\('|_sectionTitle\('|title: '" lib/pages/history_page.dart`
Expected: tidak ada output.
Run: `/c/flutter/bin/flutter analyze lib/pages/history_page.dart lib/services/locale_service.dart`
Expected: No issues found. Kalau `AppColors` atau import lain jadi tak terpakai, analyzer menandainya; hapus hanya yang ditandai.
Run: `/c/flutter/bin/flutter analyze 2>&1 | tail -1`
Expected: `9 issues found.`
Run: `/c/flutter/bin/flutter test`
Expected: semua lulus.

- [ ] **Step 8: Commit**

```bash
git add lib/pages/history_page.dart lib/services/locale_service.dart
git commit -m "feat: restyle history detail sheet"
```

---

## Cek manual (user, di HP/emulator)

Setelah semua task selesai, cek di mode terang dan gelap, Bahasa Indonesia dan English, skala teks 200%, dan TalkBack.

1. **Riwayat dengan data**
   - Baris polos dengan pemisah, dikelompokkan "Hari ini" / "Kemarin" / tanggal (nama bulan ikut bahasa).
   - Klien sebagai judul; di bawahnya nomor · jenis (· metode bayar untuk struk).
   - Kanan: nominal + status. Struk "Lunas" hijau, invoice lunas "Lunas", invoice belum lunas "Belum Lunas" oranye, lewat jatuh tempo "Lewat N hari" merah.
   - Tab Semua / Invoice / Struk / Belum Lunas bergaris bawah, tinggi 48dp, tap mengganti daftar.
   - Cari nama klien atau nomor jalan bersama tab.
   - "Export CSV" di kanan atas berupa tombol teks.
2. **Dari Beranda**: "Lihat semua" membuka Riwayat dengan tab "Belum Lunas" aktif.
3. **Geser hapus**
   - Geser ke kiri: latar merah dengan ikon, baris menutup ~200ms, SnackBar "\"INV-…\" dihapus" + Undo hilang sendiri setelah 4 detik.
   - Undo: baris kembali, status dan isi detail sama seperti sebelum dihapus.
   - Hapus, langsung pindah tab, tekan Undo: dokumen kembali saat Riwayat dibuka lagi.
   - Login (Firestore): hapus lalu tarik-untuk-muat; dokumen tetap hilang. Hapus lalu Undo lalu tarik-untuk-muat; dokumen ada.
4. **Kosong karena filter**: tab "Belum Lunas" tanpa invoice belum lunas menampilkan "Tidak ada invoice belum dibayar" + "Hapus filter"; tombol mengembalikan tab Semua dan mengosongkan pencarian. Pencarian tanpa hasil: "Tidak ada dokumen yang cocok".
5. **Gagal**: pesan "Riwayat tidak bisa dimuat." + "Coba lagi". (Sulit dipicu karena `HistoryService.load` jatuh ke data lokal; cukup cek bila bisa.)
6. **Memuat**: tidak ada spinner berkedip; teks "Memuat…" hanya muncul jika lebih dari 300ms.
7. **Pengingat**
   - Baris polos + pemisah, tanpa kotak ikon. Terlewat = titik + "Terlewat" merah, hari ini = titik + "Hari ini" oranye.
   - Baris ulang menampilkan " · Setiap 1 Bulan" / " · Every month".
   - Geser kanan = tandai selesai (latar hijau), geser kiri = hapus dengan dialog.
   - Sheet detail: label di atas nilai, "Telepon"/"Alamat" tampil benar (sebelumnya "common.phone"), satu tombol utama "Tandai Selesai", Hapus merah.
   - Kirim WhatsApp: pesan dalam bahasa aktif.
   - Sheet tambah: chip layanan dan "1 Bulan…1 Tahun" ikut bahasa; dropdown ulangi ikut bahasa; validasi "Wajib diisi"/"Required".
   - Sheet kontak: pegangan tarik bawaan, daftar polos, menu Hapus merah.
8. **Detail Riwayat** (tap baris)
   - Pegangan tarik bawaan.
   - Jenis + nomor di atas, tombol cetak berlabel "Cetak".
   - Label di atas nilai, judul bagian sentence case.
   - Item sebagai baris `qty satuan × harga` + subtotal.
   - Ringkasan polos, dengan PPN menampilkan tarif dokumen.
   - Tap baris status mengganti Lunas ↔ Belum Lunas (titik + teks), dan Riwayat di belakangnya ikut berubah.
   - "Buat Ulang Dokumen" satu-satunya tombol terisi.
   - Cetak membuka preview dengan judul sesuai bahasa.
   - Struk menampilkan subtotal, diskon, metode, bayar, kembalian.
9. **200%**: baris Riwayat tidak overflow (nominal + status di kanan, judul terpotong elipsis); sheet detail pengingat bisa digulir.
10. **TalkBack**
   - Tab Riwayat terbaca sebagai tab dengan status terpilih.
   - Judul tanggal terbaca sebagai heading.
   - Latar geser terbaca "Hapus" / "Tandai Selesai".
   - Tombol hapus pencarian terbaca "Hapus pencarian"; FAB Pengingat terbaca "Tambah Pengingat".
