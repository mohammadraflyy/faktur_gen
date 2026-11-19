# UI Refresh Tahap 3b (Form Struk + Layar Setelah PDF Jadi) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:**
- Form struk memakai pola A yang sama dengan form invoice (mockup 05 kiri): stepper jumlah langsung di baris, metode bayar sebagai segmented control, uang diterima + nominal cepat + kembalian otomatis, diskon/catatan di baris yang membuka sheet, tombol hijau "Buat struk".
- Setelah dokumen tersimpan, invoice dan struk masuk ke layar "siap" (mockup 03 kanan): centang animasi, ringkasan, Kirim lewat WhatsApp, Bagikan/Cetak/Simpan lewat `showPdfActionSheet`, toggle pengingat, "Selesai" menutup satu layar.

**Architecture:**
- Logika bercabang jadi fungsi murni yang dites: `cashChange` (kembalian/kurang) di `struk_model.dart`, `defaultReminderDate` di `reminder_model.dart`.
- Form struk menyimpan item di `ValueNotifier<List<ItemStruk>>`, total di `ValueNotifier<double>`, uang diterima di `ValueNotifier<double>`. Mengetik di field uang hanya membangun ulang baris kembalian.
- Item struk diedit lewat `showItemEditSheet` yang sudah ada (konversi `ItemStruk` ↔ `ItemFaktur`), ditambah field diskon opsional supaya diskon per item struk tidak hilang.
- Layar baru `DocumentReadyPage` menggantikan form (`pushReplacement`). `PdfPreviewPage` tetap jadi penampil PDF dan dibuka dari baris "Lihat PDF".
- Warna hijau struk lewat `Theme` di atas state form (bukan parameter baru di `TotalBar`): `FilledButton` di `TotalBar` sudah memakai `colorScheme.primary`/`onPrimary`, dan `main.dart` tidak punya `filledButtonTheme`.

**Tech Stack:** Flutter (SDK di `C:\flutter`, tidak ada di PATH), Material 3, `intl`, `printing`, `share_plus` (sudah terpasang), `flutter_test`.

Spec: `docs/superpowers/specs/2026-11-19-ui-refresh-design.md`, bagian "Sistem desain", "Setelah PDF jadi", "Form struk", "Gerak dan kehalusan", "Bahasa", "Verifikasi", "Di luar cakupan". Mockup: `docs/mockups/03-item-and-share-sheets.svg` (kanan), `docs/mockups/05-struk-settings.svg` (kiri).

## Global Constraints

- Tidak ada package baru.
- Font tetap Inter.
- Aksen invoice dari `colorScheme.primary`: #2563EB / #60A5FA. Aksen struk: #047857 (teks putih, 5.48:1) / #34D399 (teks #0F1117, 9.82:1), dipasang oleh `_strukTheme` di `struk_page.dart`.
- Status merah lewat `AppColors.errorFor(brightness)`, sukses lewat `AppColors.successFor(brightness)`.
- Teks memakai `textTheme`:
  - `headlineSmall` 22/700: judul halaman
  - `titleMedium` 17/600: judul bagian
  - `titleSmall` 15/600: judul baris
  - `bodyLarge`/`bodyMedium` 15/400
  - `bodySmall` 13/400 abu-abu
- Tidak ada `GoogleFonts.*()` baru dan tidak ada `fontSize` literal baru.
- Tanpa kartu bergaris. Bagian dipisah jarak + `Divider(height: 1)`.
- Satu tombol utama (filled) per layar.
- Area sentuh ≥ 48dp.
- Semua teks baru lewat `tr()` di `lib/services/locale_service.dart`:
  - Format `'key': ['id', 'en']`.
  - Entri baru ditambah tepat sebelum `};` penutup map `_strings` (sekarang baris 468).
  - Placeholder `{n}`, `{name}`, `{number}`, `{amount}` diisi dengan `.replaceAll(...)`.
  - Struk memakai ulang kunci `invoice.*` / `common.*` yang teks Indonesianya sama persis (`invoice.items`, `invoice.add_item`, `invoice.from_catalog`, `invoice.no_items`, `invoice.item_removed`, `invoice.need_item`, `invoice.notes`, `invoice.leave*`, `invoice.reset_form`, `invoice.store_missing`). Kunci khusus struk memakai awalan `receipt.`.
- Tanggal diformat dengan locale `LocaleService.isEn ? 'en_US' : 'id_ID'`.
- Animasi: kalau `MediaQuery.disableAnimationsOf(context)` true, durasi nol.
- SnackBar dengan Urungkan wajib `persist: false` dan `duration: const Duration(seconds: 4)`.
- Komentar kode singkat, menjelaskan alasan. Tanpa emoji, tanpa kode mati, tanpa kode yang dikomentari.
- Commit: subjek pendek konvensional, tanpa trailer `Co-Authored-By` dan tanpa menyebut AI.
- Perintah Flutter: `/c/flutter/bin/flutter` (Git Bash).
- Baseline: `flutter analyze` = 9 issue (semua di file yang tidak disentuh rencana ini), `flutter test` = 114 lulus. Setiap task: analyze tetap 9, semua test lulus.

## Keputusan yang menyimpang dari spec / perlu diketahui

- **Posisi layar "siap".** "Buat PDF"/"Buat struk" → simpan → layar siap *menggantikan* form (`Navigator.pushReplacement`). Thumbnail di mockup diganti baris "Lihat PDF" yang membuka `PdfPreviewPage` apa adanya (zoom, ganti format, cetak, bagikan tetap di sana). Alasan:
  - Alur lama (preview → Selesai → dialog → form ditutup) butuh dua transisi dan form sempat terlihat lagi.
  - Dokumen sudah tersimpan di Riwayat sebelum PDF dibuka; kembali ke form lalu menekan "Buat PDF" lagi membuat entri ganda. Dengan form diganti, tombol kembali dan "Selesai" sama-sama pulang ke asal form.
  - `main_navigation.dart:_openCreatePage` menunggu `Navigator.push`; future itu selesai saat form diganti, jadi Beranda sudah dimuat ulang ketika layar siap tampil.
- **Tanpa thumbnail raster.** `Printing.raster` bisa, tapi butuh FutureBuilder + gambar untuk sesuatu yang sudah ada satu tap di "Lihat PDF". Tambahkan kalau user memintanya.
- **"Kirim lewat WhatsApp"** membuka share sheet sistem berisi PDF + pesan siap kirim (user memilih WhatsApp di sana). Mengirim lampiran langsung ke nomor WhatsApp tidak bisa tanpa package/platform channel baru. Memakai `WhatsAppService` yang sudah ada (tanpa pemanggil), method-nya diubah jadi `sharePdf(pdfBytes, filename, message)` supaya pesannya bisa diterjemahkan dan dipakai struk.
- **Bagikan / Cetak / Simpan** = tombol teks "Bagikan, cetak, simpan" yang membuka `showPdfActionSheet` (pertama kali dipakai). Cetak = `Printing.layoutPdf`, Simpan = `Printing.sharePdf` (di Android: share sheet dengan opsi simpan ke file).
- **Toggle pengingat** menggantikan dialog + date picker + time picker:
  - Tanggal = jatuh tempo pukul 09:00; kalau tidak ada jatuh tempo atau sudah lewat, 30 hari dari sekarang pukul 09:00 (`defaultReminderDate`).
  - Tanggal tampil di bawah toggle. Mengubah tanggal dilakukan di tab Pengingat (`reminder_page.dart` sudah punya edit).
  - Label: "Ingatkan saat jatuh tempo" hanya kalau tanggalnya memang jatuh tempo; selain itu "Ingatkan saya". Struk selalu "Ingatkan saya".
  - Toggle mati lagi = pengingat dihapus.
- **QRIS** ditambah sebagai nilai `MetodeBayar.qris` (label `QRIS`). Riwayat menyimpan label sebagai string, jadi field tersimpan tidak berubah. Pembayaran kartu tetap ada sebagai segmen keempat "Kartu" (keputusan user). Model punya dua nilai kartu (`debit`, `kredit`); segmen "Kartu" memilih `debit`, dan struk lama berstatus `debit` atau `kredit` sama-sama menyorot "Kartu" (`paymentSegment`). Struk `kredit` tetap `kredit` sampai kasir memilih segmen lain. Kartu tidak menampilkan field uang diterima.
- **Kembalian:** `cashChange` mengembalikan `null` (belum ada uang diterima → baris disembunyikan), positif (Kembalian), nol, atau negatif (tampil "Kurang" merah + teks, bukan warna saja). Getter `StrukModel.kembalian` (dipakai untuk menyimpan ke Riwayat) tidak diubah.
- **Nominal cepat** "Uang pas" selalu ada; 50.000 dan 100.000 hanya untuk mata uang IDR. Ditulis sebagai nominal berformat ("Rp 50.000"), bukan "50rb".
- **Diskon per item** dipertahankan lewat field opsional "Diskon item" di `ItemEditSheet` (hanya muncul kalau pemanggil memberi `discount`). Invoice tidak berubah.
- **Nama kasir dan tanggal/waktu struk** pindah ke sheet "Diskon dan catatan" (mockup tidak punya barisnya). Nomor struk diubah dengan tap judul, sama seperti invoice.
- **Urutan item naik/turun di struk dihapus**, sama seperti invoice di tahap 2.
- **`_CatalogPickerSheet` dipindah** ke `lib/widgets/catalog_picker_sheet.dart` (spec "Sistem desain"). Versi invoice yang dipakai karena sudah lewat `tr()`. Akibatnya dialog "Buat baru" di katalog struk tidak lagi punya field deskripsi; deskripsi item tetap bisa diisi di sheet item.
- **Tidak dikerjakan:** label "Total, 3 item" di bar bawah (TotalBar tetap "Total"), `AnimatedList` tambah/hapus item (invoice tahap 2 juga belum).
- **`TotalBar` tidak diubah**: warna hijau datang dari `Theme`.

## File Structure

| File | Perubahan |
|---|---|
| `lib/models/struk_model.dart` | `MetodeBayar.qris`, fungsi `cashChange`, `paymentSegment` |
| `lib/models/reminder_model.dart` | fungsi `defaultReminderDate` |
| `lib/widgets/item_edit_sheet.dart` | parameter opsional `discount`, `ItemEditResult.discount` |
| `lib/widgets/catalog_picker_sheet.dart` (baru) | `CatalogPickerSheet`, dipindah dari `faktur_page.dart` |
| `lib/widgets/pdf_action_sheet.dart` | `tr()`, `textTheme`, drag handle bawaan |
| `lib/pages/pdf_preview_page.dart` | "Selesai" lewat `tr()` |
| `lib/services/whatsapp_service.dart` | `shareInvoice` → `sharePdf` (pesan dari pemanggil) |
| `lib/pages/document_ready_page.dart` (baru) | layar setelah PDF jadi |
| `lib/pages/faktur_page.dart` | pakai `CatalogPickerSheet`, buka `DocumentReadyPage`, hapus `_showReminderDialog` |
| `lib/pages/struk_page.dart` | ditulis ulang (pola A) |
| `lib/services/locale_service.dart` | kunci `item.discount`, `pdf.*`, `done.*`, `receipt.*`; hapus `invoice.reminder_*` |
| `test/models/struk_model_test.dart`, `test/models/reminder_model_test.dart`, `test/widgets/item_edit_sheet_test.dart` | test baru |
| `test/pages/document_ready_page_test.dart` (baru) | test "Selesai" menutup satu layar |

---

### Task 1: Fungsi murni `cashChange`, `defaultReminderDate`, dan `MetodeBayar.qris`

**Files:**
- Modify: `lib/models/struk_model.dart`
- Modify: `lib/models/reminder_model.dart`
- Test: `test/models/struk_model_test.dart`, `test/models/reminder_model_test.dart`

**Interfaces:**
- Produces: `double? cashChange({required double total, required double paid})`.
- Produces: `DateTime defaultReminderDate(DateTime? due, DateTime now)`.
- Produces: `MetodeBayar.qris` dengan `label == 'QRIS'`.
- Produces: `MetodeBayar paymentSegment(MetodeBayar m)`: segmen yang disorot di form struk (`kredit` → `debit`, sisanya apa adanya).

- [ ] **Step 1: Tulis test yang gagal**

Di `test/models/struk_model_test.dart`, ganti:

```dart
    test('labels are correct', () {
      expect(MetodeBayar.tunai.label, 'Tunai');
      expect(MetodeBayar.transfer.label, 'Transfer');
      expect(MetodeBayar.debit.label, 'Kartu Debit');
      expect(MetodeBayar.kredit.label, 'Kartu Kredit');
    });
```

dengan:

```dart
    test('labels are correct', () {
      expect(MetodeBayar.tunai.label, 'Tunai');
      expect(MetodeBayar.transfer.label, 'Transfer');
      expect(MetodeBayar.debit.label, 'Kartu Debit');
      expect(MetodeBayar.kredit.label, 'Kartu Kredit');
      expect(MetodeBayar.qris.label, 'QRIS');
    });
```

Lalu tambah grup ini sebelum `}` penutup `main()` (setelah grup `StrukModel`):

```dart

  group('cashChange', () {
    test('null until an amount is entered', () {
      expect(cashChange(total: 85000, paid: 0), isNull);
    });

    test('change when paid more than the total', () {
      expect(cashChange(total: 85000, paid: 100000), 15000);
    });

    test('zero for the exact amount', () {
      expect(cashChange(total: 85000, paid: 85000), 0);
    });

    test('negative when the payment is short', () {
      expect(cashChange(total: 85000, paid: 50000), -35000);
    });
  });

  group('paymentSegment', () {
    test('both card values highlight the card segment', () {
      expect(paymentSegment(MetodeBayar.debit), MetodeBayar.debit);
      expect(paymentSegment(MetodeBayar.kredit), MetodeBayar.debit);
    });

    test('other methods map to themselves', () {
      expect(paymentSegment(MetodeBayar.tunai), MetodeBayar.tunai);
      expect(paymentSegment(MetodeBayar.transfer), MetodeBayar.transfer);
      expect(paymentSegment(MetodeBayar.qris), MetodeBayar.qris);
    });
  });
```

Di `test/models/reminder_model_test.dart`, tambah grup ini sebelum `}` penutup `main()`:

```dart

  group('defaultReminderDate', () {
    final now = DateTime(2026, 11, 19, 10, 30);

    test('due date in the future, at 09:00', () {
      expect(defaultReminderDate(DateTime(2026, 12, 3), now),
          DateTime(2026, 12, 3, 9));
    });

    test('no due date: 30 days from now, at 09:00', () {
      expect(defaultReminderDate(null, now), DateTime(2026, 12, 19, 9));
    });

    test('due date already passed: 30 days from now', () {
      expect(defaultReminderDate(DateTime(2026, 11, 1), now),
          DateTime(2026, 12, 19, 9));
    });

    test('due today after 09:00 has passed: 30 days from now', () {
      expect(defaultReminderDate(DateTime(2026, 11, 19), now),
          DateTime(2026, 12, 19, 9));
    });
  });
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `/c/flutter/bin/flutter test test/models/struk_model_test.dart test/models/reminder_model_test.dart`
Expected: gagal kompilasi (`qris`, `cashChange`, `paymentSegment`, `defaultReminderDate` belum ada).

- [ ] **Step 3: Implementasi**

`lib/models/struk_model.dart`, ganti baris 1:

```dart
enum MetodeBayar { tunai, transfer, debit, kredit }
```

dengan:

```dart
// The form shows one "Kartu" segment for debit and kredit; see
// paymentSegment.
enum MetodeBayar { tunai, transfer, debit, kredit, qris }
```

Di switch `label`, ganti:

```dart
      case MetodeBayar.kredit:
        return 'Kartu Kredit';
    }
```

dengan:

```dart
      case MetodeBayar.kredit:
        return 'Kartu Kredit';
      case MetodeBayar.qris:
        return 'QRIS';
    }
```

Tambah di akhir file:

```dart

/// Change for a cash payment. Negative means the customer is still short;
/// null until an amount has been entered.
double? cashChange({required double total, required double paid}) =>
    paid > 0 ? paid - total : null;

/// Segment highlighted in the receipt form. Debit and kredit share one
/// "Kartu" segment whose value is debit.
MetodeBayar paymentSegment(MetodeBayar m) =>
    m == MetodeBayar.kredit ? MetodeBayar.debit : m;
```

`lib/models/reminder_model.dart`, tambah di akhir file:

```dart

/// Date for the "remind me" toggle after a document is created: the due
/// date at 09:00, or 30 days from [now] when there is none or it has passed.
DateTime defaultReminderDate(DateTime? due, DateTime now) {
  if (due != null) {
    final onDue = DateTime(due.year, due.month, due.day, 9);
    if (onDue.isAfter(now)) return onDue;
  }
  return DateTime(now.year, now.month, now.day + 30, 9);
}
```

- [ ] **Step 4: Verifikasi**

Run: `/c/flutter/bin/flutter test test/models/struk_model_test.dart test/models/reminder_model_test.dart`
Expected: semua lulus.
Run: `/c/flutter/bin/flutter analyze`
Expected: 9 issue (sama dengan baseline). `history_page.dart` dan `struk_pdf_service.dart` hanya membandingkan `MetodeBayar` dengan `==`, jadi tidak ada switch yang jadi tidak lengkap.

- [ ] **Step 5: Commit**

```bash
git add lib/models/struk_model.dart lib/models/reminder_model.dart test/models/struk_model_test.dart test/models/reminder_model_test.dart
git commit -m "feat: add QRIS, cash change and reminder helpers"
```

---

### Task 2: Diskon opsional di `ItemEditSheet`

**Files:**
- Modify: `lib/widgets/item_edit_sheet.dart`
- Modify: `lib/services/locale_service.dart`
- Test: `test/widgets/item_edit_sheet_test.dart`

**Interfaces:**
- Produces: `showItemEditSheet(context, {required ItemFaktur item, required NumberFormat currency, bool isNew = false, double? discount})`. `discount != null` menampilkan field "Diskon item".
- Produces: `ItemEditResult.discount` (`double`, 0 kalau tidak dipakai).
- Invoice (`faktur_page.dart`) tidak berubah karena tidak memberi `discount`.

- [ ] **Step 1: Kunci locale**

Sebelum `};` penutup `_strings`:

```dart
  'item.discount': ['Diskon item', 'Item discount'],
```

- [ ] **Step 2: Tulis test yang gagal**

Di `test/widgets/item_edit_sheet_test.dart`, ganti:

```dart
Future<ItemEditResult? Function()> _open(WidgetTester tester, ItemFaktur item,
    {bool isNew = false}) async {
```

dengan:

```dart
Future<ItemEditResult? Function()> _open(WidgetTester tester, ItemFaktur item,
    {bool isNew = false, double? discount}) async {
```

dan ganti:

```dart
              result = await showItemEditSheet(context,
                  item: item, currency: _fmt, isNew: isNew);
```

dengan:

```dart
              result = await showItemEditSheet(context,
                  item: item, currency: _fmt, isNew: isNew, discount: discount);
```

Tambah dua test ini di akhir `main()`:

```dart

  testWidgets('no discount field unless the caller asks for one',
      (tester) async {
    await _open(tester, ItemFaktur(namaBarang: 'A', hargaSatuan: 10));
    expect(find.text('Diskon item'), findsNothing);
  });

  testWidgets('discount lowers the subtotal and is returned', (tester) async {
    final read = await _open(
        tester, ItemFaktur(namaBarang: 'Kopi', hargaSatuan: 25000),
        discount: 0);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Diskon item'), '5000');
    await tester.pump();
    await tester.tap(find.text('Simpan · Rp 20,000'));
    await tester.pumpAndSettle();

    final result = read();
    expect(result!.discount, 5000);
    expect(result.item!.hargaSatuan, 25000);
  });
```

Run: `/c/flutter/bin/flutter test test/widgets/item_edit_sheet_test.dart`
Expected: gagal kompilasi (`discount` belum ada).

- [ ] **Step 3: Implementasi**

`lib/widgets/item_edit_sheet.dart`, ganti:

```dart
class ItemEditResult {
  final ItemFaktur? item;
  const ItemEditResult.saved(ItemFaktur this.item);
  const ItemEditResult.deleted() : item = null;
```

dengan:

```dart
class ItemEditResult {
  final ItemFaktur? item;

  /// Per-item discount; stays 0 unless the sheet was opened with one.
  final double discount;
  const ItemEditResult.saved(ItemFaktur this.item, {this.discount = 0});
  const ItemEditResult.deleted()
      : item = null,
        discount = 0;
```

Ganti:

```dart
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
```

dengan:

```dart
  required NumberFormat currency,
  bool isNew = false,
  double? discount,
}) {
  return showModalBottomSheet<ItemEditResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ItemEditSheet(
        item: item, currency: currency, isNew: isNew, discount: discount),
  );
}
```

Ganti:

```dart
  final bool isNew;

  const ItemEditSheet({
    super.key,
    required this.item,
    required this.currency,
    this.isNew = false,
  });
```

dengan:

```dart
  final bool isNew;

  /// Receipts can discount a single item; null hides the field.
  final double? discount;

  const ItemEditSheet({
    super.key,
    required this.item,
    required this.currency,
    this.isNew = false,
    this.discount,
  });
```

Ganti:

```dart
  late double _qty = widget.item.kuantitas;
```

dengan:

```dart
  late final _diskon = TextEditingController(
      text: (widget.discount ?? 0) > 0
          ? widget.discount!.round().toString()
          : '');
  late double _qty = widget.item.kuantitas;
```

Ganti:

```dart
  double get _price => double.tryParse(_harga.text) ?? 0;
```

dengan:

```dart
  double get _price => double.tryParse(_harga.text) ?? 0;
  double get _discount => double.tryParse(_diskon.text) ?? 0;
```

Di `dispose()`, setelah `_harga.dispose();` tambah:

```dart
    _diskon.dispose();
```

Di `_save()`, ganti:

```dart
        satuan: satuan.isEmpty ? 'Unit' : satuan,
        hargaSatuan: _price,
      )),
    );
```

dengan:

```dart
        satuan: satuan.isEmpty ? 'Unit' : satuan,
        hargaSatuan: _price,
      ), discount: _discount),
    );
```

Di `build`, ganti:

```dart
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: Text(
                    '${tr('common.save')} · ${widget.currency.format(_qty * _price)}'),
              ),
```

dengan:

```dart
              if (widget.discount != null) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _diskon,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: tr('item.discount')),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: Text(
                    '${tr('common.save')} · ${widget.currency.format(_qty * _price - _discount)}'),
              ),
```

- [ ] **Step 4: Verifikasi**

Run: `/c/flutter/bin/flutter test test/widgets/item_edit_sheet_test.dart`
Expected: semua lulus (test lama + 2 baru).
Run: `/c/flutter/bin/flutter analyze`
Expected: 9 issue.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/item_edit_sheet.dart lib/services/locale_service.dart test/widgets/item_edit_sheet_test.dart
git commit -m "feat: optional item discount in item sheet"
```

---

### Task 3: Pindahkan sheet katalog ke `lib/widgets/`

**Files:**
- Create: `lib/widgets/catalog_picker_sheet.dart`
- Modify: `lib/pages/faktur_page.dart`

**Interfaces:**
- Produces: `CatalogPickerSheet({Key? key, required List<CatalogItem> items, String currencySymbol = 'Rp ', String currencyLocale = 'id_ID'})`. Pop dengan `CatalogItem` yang dipilih/dibuat.
- Struk masih memakai salinan privatnya sampai Task 6 menulis ulang file itu.

- [ ] **Step 1: Cek jangkar baris**

Run: `grep -n "Catalog Picker Bottom Sheet\|^class _CatalogPickerSheet \|_CatalogPickerSheet(" lib/pages/faktur_page.dart; wc -l lib/pages/faktur_page.dart`
Expected: komentar di 1475, `class _CatalogPickerSheet` di 1477, pemanggil di 456, total 1702 baris. Kalau berbeda, sesuaikan angka di Step 2 dan 3 dengan hasil ini.

- [ ] **Step 2: Buat file widget dari kode yang ada**

```bash
cd /c/Work/faktur_gen
{ cat <<'EOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/catalog_model.dart';
import '../services/catalog_service.dart';
import '../services/locale_service.dart';

/// Catalog search sheet shared by the invoice and receipt forms. Pops with
/// the picked or newly created [CatalogItem].
EOF
sed -n '1477,1702p' lib/pages/faktur_page.dart; } > lib/widgets/catalog_picker_sheet.dart
sed -i 's/_CatalogPickerSheet\b/CatalogPickerSheet/g' lib/widgets/catalog_picker_sheet.dart
```

`\b` membuat `_CatalogPickerSheetState` tetap privat. Lalu di file baru ganti:

```dart
  const CatalogPickerSheet({
    required this.items,
```

dengan:

```dart
  const CatalogPickerSheet({
    super.key,
    required this.items,
```

- [ ] **Step 3: Hapus salinan di `faktur_page.dart` dan pakai widget baru**

```bash
cd /c/Work/faktur_gen
sed -i '1474,1702d' lib/pages/faktur_page.dart
sed -i 's/_CatalogPickerSheet(/CatalogPickerSheet(/' lib/pages/faktur_page.dart
```

Baris 1474 adalah baris kosong setelah `}` penutup `_TemplatePickerSheet`, jadi file berakhir dengan `}` itu.

Ganti import:

```dart
import '../widgets/item_edit_sheet.dart';
```

dengan:

```dart
import '../widgets/catalog_picker_sheet.dart';
import '../widgets/item_edit_sheet.dart';
```

- [ ] **Step 4: Verifikasi**

Run: `grep -n "CatalogPickerSheet" lib/pages/faktur_page.dart`
Expected: hanya pemanggil `CatalogPickerSheet(` (sekitar baris 456).
Run: `tail -3 lib/pages/faktur_page.dart`
Expected: penutup `_TemplatePickerSheet` (`  }` lalu `}`).
Run: `/c/flutter/bin/flutter analyze`
Expected: 9 issue. Import `google_fonts`, `intl`, `catalog_model`, `catalog_service` di `faktur_page.dart` masih dipakai (sheet kontak/template, `_currency`, `_openCatalog`).
Run: `/c/flutter/bin/flutter test`
Expected: semua lulus.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/catalog_picker_sheet.dart lib/pages/faktur_page.dart
git commit -m "refactor: move catalog picker sheet to widgets"
```

---

### Task 4: `pdf_action_sheet`, judul "Selesai" preview, dan `WhatsAppService.sharePdf`

**Files:**
- Modify: `lib/widgets/pdf_action_sheet.dart` (ditulis ulang)
- Modify: `lib/pages/pdf_preview_page.dart`
- Modify: `lib/services/whatsapp_service.dart`
- Modify: `lib/services/locale_service.dart`

**Interfaces:**
- `showPdfActionSheet` tidak berubah signature-nya; `PdfAction { print, download, whatsapp }` tetap.
- Produces: `WhatsAppService.sharePdf({required Uint8List pdfBytes, required String filename, required String message})`. Menggantikan `shareInvoice` (tidak punya pemanggil: `grep -rn shareInvoice lib` hanya menemukan definisinya).

- [ ] **Step 1: Kunci locale**

Sebelum `};` penutup `_strings`:

```dart
  'pdf.choose_action': ['Pilih aksi', 'Choose an action'],
  'pdf.print': ['Cetak', 'Print'],
  'pdf.print_hint': ['Cetak via printer', 'Print on a printer'],
  'pdf.save_hint': ['Simpan atau bagikan PDF', 'Save or share the PDF'],
  'pdf.whatsapp_hint': ['Kirim ke klien', 'Send to the client'],
```

- [ ] **Step 2: Tulis ulang `lib/widgets/pdf_action_sheet.dart`**

Alasan: teks tetap, `Colors.grey` (#9E9E9E, 2.7:1 di putih) gagal AA, hijau #2E7D32 di mode gelap gagal, ukuran font literal.

```dart
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/locale_service.dart';

enum PdfAction { print, download, whatsapp }

/// Bottom sheet with Print / Save and, optionally, WhatsApp.
/// Returns the chosen [PdfAction], or null when dismissed.
Future<PdfAction?> showPdfActionSheet(
  BuildContext context, {
  required String docName,
  bool showWhatsApp = false,
}) {
  return showModalBottomSheet<PdfAction>(
    context: context,
    showDragHandle: true,
    builder: (_) => _PdfActionSheet(docName: docName, showWhatsApp: showWhatsApp),
  );
}

class _PdfActionSheet extends StatelessWidget {
  final String docName;
  final bool showWhatsApp;
  const _PdfActionSheet({required this.docName, this.showWhatsApp = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(docName,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(tr('pdf.choose_action'), style: theme.textTheme.bodySmall),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.print,
                    label: tr('pdf.print'),
                    sublabel: tr('pdf.print_hint'),
                    color: theme.colorScheme.primary,
                    onTap: () => Navigator.pop(context, PdfAction.print),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.download,
                    label: tr('common.save'),
                    sublabel: tr('pdf.save_hint'),
                    color: AppColors.successFor(theme.brightness),
                    onTap: () => Navigator.pop(context, PdfAction.download),
                  ),
                ),
                if (showWhatsApp) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.chat,
                      label: 'WhatsApp',
                      sublabel: tr('pdf.whatsapp_hint'),
                      color: const Color(0xFF25D366),
                      onTap: () => Navigator.pop(context, PdfAction.whatsapp),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              // The label carries the meaning; the tinted icon is decoration.
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 10),
              Text(label,
                  style: theme.textTheme.titleSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text(sublabel,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: "Selesai" di `pdf_preview_page.dart` lewat `tr()`**

Tambah import setelah `import 'package:printing/printing.dart';`:

```dart
import '../services/locale_service.dart';
```

Ganti:

```dart
            label: Text('Selesai',
```

dengan:

```dart
            label: Text(tr('common.done'),
```

- [ ] **Step 4: `WhatsAppService.sharePdf`**

Di `lib/services/whatsapp_service.dart`, ganti seluruh method `shareInvoice` (dari `/// Share invoice PDF via WhatsApp with pre-filled message.` sampai `}` penutupnya, sebelum `/// Open WhatsApp chat`) dengan:

```dart
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
```

- [ ] **Step 5: Verifikasi**

Run: `grep -rn "shareInvoice" lib test`
Expected: tidak ada output.
Run: `grep -nE "Text\(\s*'|fontSize" lib/widgets/pdf_action_sheet.dart`
Expected: tidak ada output (`'WhatsApp'` ada di argumen `label:`, nama merek).
Run: `/c/flutter/bin/flutter analyze`
Expected: 9 issue.
Run: `/c/flutter/bin/flutter test`
Expected: semua lulus; `test/pages/pdf_preview_page_test.dart` masih menemukan "Selesai" (bahasa default Indonesia).

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/pdf_action_sheet.dart lib/pages/pdf_preview_page.dart lib/services/whatsapp_service.dart lib/services/locale_service.dart
git commit -m "feat: translate PDF action sheet, share PDF helper"
```

---

### Task 5: Layar "Invoice siap" (`DocumentReadyPage`) dan alur invoice

**Files:**
- Create: `lib/pages/document_ready_page.dart`
- Modify: `lib/pages/faktur_page.dart`
- Modify: `lib/services/locale_service.dart`
- Test: `test/pages/document_ready_page_test.dart`

**Interfaces:**
- Consumes: `WhatsAppService.sharePdf`, `showPdfActionSheet`, `PdfPreviewPage`, `ReminderService.add/delete`, `defaultReminderDate`.
- Produces: `DocumentReadyPage({required String title, required String summary, required String shareMessage, required PdfPreviewPage preview, required ReminderModel reminder, required String reminderLabel})`.
  - `preview` dipakai dua kali: dibuka apa adanya dari "Lihat PDF", dan `preview.buildPdf` / `preview.filename` / `preview.initialPageFormat` dipakai untuk kirim, cetak, simpan.
  - "Selesai" dan tombol kembali hanya `pop` layar ini.

- [ ] **Step 1: Kunci locale**

Sebelum `};` penutup `_strings`:

```dart
  'done.invoice_ready': ['Invoice siap', 'Invoice ready'],
  'done.receipt_ready': ['Struk siap', 'Receipt ready'],
  'done.whatsapp': ['Kirim lewat WhatsApp', 'Send via WhatsApp'],
  'done.more': ['Bagikan, cetak, simpan', 'Share, print, save'],
  'done.view_pdf': ['Lihat PDF', 'View PDF'],
  'done.remind_due': ['Ingatkan saat jatuh tempo', 'Remind me on the due date'],
  'done.remind_later': ['Ingatkan saya', 'Remind me'],
  'done.invoice_message': ['Halo {name},\n\nBerikut invoice {number} sebesar {amount}.\n\nTerima kasih.', 'Hello {name},\n\nHere is invoice {number} for {amount}.\n\nThank you.'],
  'done.receipt_message': ['Terima kasih. Berikut struk {number} sebesar {amount}.', 'Thank you. Here is receipt {number} for {amount}.'],
```

- [ ] **Step 2: Tulis test yang gagal**

`test/pages/document_ready_page_test.dart`:

```dart
import 'dart:typed_data';

import 'package:faktur_gen/models/reminder_model.dart';
import 'package:faktur_gen/pages/document_ready_page.dart';
import 'package:faktur_gen/pages/pdf_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

DocumentReadyPage _page() => DocumentReadyPage(
      title: 'Invoice siap',
      summary: 'Klien A · Rp 1.000',
      shareMessage: 'Halo',
      reminderLabel: 'Ingatkan saya',
      reminder: ReminderModel(
        id: '1',
        contactName: 'Klien A',
        serviceName: 'Desain',
        reminderDate: DateTime(2030, 1, 1),
        reminderHour: 9,
      ),
      preview: PdfPreviewPage(
        title: 'Preview',
        filename: 'test.pdf',
        buildPdf: (_) async => Uint8List(0),
      ),
    );

Future<void> _openReady(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (ctx) => TextButton(
        onPressed: () => Navigator.push(
            ctx, MaterialPageRoute(builder: (_) => _page())),
        child: const Text('open'),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('shows the summary and the reminder date, toggle off',
      (tester) async {
    await _openReady(tester);
    expect(find.text('Invoice siap'), findsOneWidget);
    expect(find.text('Klien A · Rp 1.000'), findsOneWidget);
    expect(find.text('1 Jan 2030, 09:00'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse);
  });

  testWidgets('Selesai closes only the ready screen', (tester) async {
    await _openReady(tester);
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(find.text('Invoice siap'), findsNothing);
  });

  testWidgets('Selesai in the PDF view returns to the ready screen',
      (tester) async {
    await _openReady(tester);
    await tester.tap(find.text('Lihat PDF'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Selesai'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Invoice siap'), findsOneWidget);
  });
}
```

Test ketiga memakai `pump` berjangka, bukan `pumpAndSettle`, sama seperti `pdf_preview_page_test.dart`, karena `PdfPreview` bisa terus menggambar indikator.

Run: `/c/flutter/bin/flutter test test/pages/document_ready_page_test.dart`
Expected: gagal kompilasi (`document_ready_page.dart` belum ada).

- [ ] **Step 3: Buat `lib/pages/document_ready_page.dart`**

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../main.dart';
import '../models/reminder_model.dart';
import '../services/locale_service.dart';
import '../services/reminder_service.dart';
import '../services/whatsapp_service.dart';
import '../widgets/pdf_action_sheet.dart';
import 'pdf_preview_page.dart';

/// Shown once an invoice or receipt is saved: send it, set a reminder, or
/// finish. Viewing the PDF itself stays in [PdfPreviewPage].
class DocumentReadyPage extends StatefulWidget {
  final String title;
  final String summary;
  final String shareMessage;
  final PdfPreviewPage preview;
  final ReminderModel reminder;
  final String reminderLabel;

  const DocumentReadyPage({
    super.key,
    required this.title,
    required this.summary,
    required this.shareMessage,
    required this.preview,
    required this.reminder,
    required this.reminderLabel,
  });

  @override
  State<DocumentReadyPage> createState() => _DocumentReadyPageState();
}

class _DocumentReadyPageState extends State<DocumentReadyPage>
    with SingleTickerProviderStateMixin {
  late final _check = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200));
  late final _scale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _check, curve: Easing.emphasizedDecelerate));
  bool _busy = false;
  bool _remind = false;
  bool _savingReminder = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery is not readable in initState; start the check only once.
    if (_check.status != AnimationStatus.dismissed) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _check.value = 1;
    } else {
      _check.forward();
    }
  }

  @override
  void dispose() {
    _check.dispose();
    super.dispose();
  }

  Future<Uint8List> _bytes() =>
      widget.preview.buildPdf(widget.preview.initialPageFormat);

  /// Keeps the share buttons disabled while the PDF is built and handed off.
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendWhatsApp() => _run(() async => WhatsAppService.sharePdf(
        pdfBytes: await _bytes(),
        filename: widget.preview.filename,
        message: widget.shareMessage,
      ));

  Future<void> _showMore() async {
    final action =
        await showPdfActionSheet(context, docName: widget.preview.filename);
    if (!mounted) return;
    switch (action) {
      case PdfAction.print:
        await _run(() => Printing.layoutPdf(
            onLayout: widget.preview.buildPdf, name: widget.preview.filename));
      case PdfAction.download:
        await _run(() async => Printing.sharePdf(
            bytes: await _bytes(), filename: widget.preview.filename));
      case PdfAction.whatsapp:
      case null:
        break;
    }
  }

  Future<void> _toggleReminder(bool on) async {
    setState(() => _savingReminder = true);
    try {
      if (on) {
        await ReminderService.add(widget.reminder);
      } else {
        await ReminderService.delete(widget.reminder.id);
      }
      if (mounted) setState(() => _remind = on);
    } finally {
      if (mounted) setState(() => _savingReminder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.reminder;
    final remindAt = DateTime(r.reminderDate.year, r.reminderDate.month,
        r.reminderDate.day, r.reminderHour, r.reminderMinute);
    final dateLocale = LocaleService.isEn ? 'en_US' : 'id_ID';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Icon(Icons.check_circle_rounded,
                      size: 64, color: AppColors.successFor(theme.brightness)),
                ),
                const SizedBox(height: 16),
                Text(widget.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(widget.summary,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 32),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  onPressed: _busy ? null : _sendWhatsApp,
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(tr('done.whatsapp')),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : _showMore,
                  child: Text(tr('done.more')),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text(tr('done.view_pdf')),
                  subtitle: Text(widget.preview.filename),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => widget.preview)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(widget.reminderLabel),
                  subtitle: Text(DateFormat('d MMM yyyy, HH:mm', dateLocale)
                      .format(remindAt)),
                  value: _remind,
                  onChanged: _savingReminder ? null : _toggleReminder,
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.pop(context),
            child: Text(tr('common.done')),
          ),
        ),
      ),
    );
  }
}
```

Run: `/c/flutter/bin/flutter test test/pages/document_ready_page_test.dart`
Expected: 3 lulus.

- [ ] **Step 4: Alur invoice di `faktur_page.dart`**

Ganti bagian akhir `_generatePdf` (sekitar baris 311–332):

```dart
    if (!saved || !mounted) return;

    final faktur = _faktur;
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewPage(
          title: tr('invoice.preview_title'),
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
```

dengan:

```dart
    if (!saved || !mounted) return;
    _openReady(isPro);
  }

  void _openReady(bool isPro) {
    final faktur = _faktur;
    final settings = _settings;
    final total = _currency.format(faktur.totalTagihan);
    final now = DateTime.now();
    final remindAt = defaultReminderDate(faktur.jatuhTempo, now);
    final onDueDate = faktur.jatuhTempo != null &&
        DateUtils.isSameDay(remindAt, faktur.jatuhTempo);
    final ready = DocumentReadyPage(
      title: tr('done.invoice_ready'),
      summary: '${faktur.namaPembeli} · $total',
      shareMessage: tr('done.invoice_message')
          .replaceAll('{name}', faktur.namaPembeli)
          .replaceAll('{number}', faktur.nomorFaktur)
          .replaceAll('{amount}', total),
      reminderLabel: tr(onDueDate ? 'done.remind_due' : 'done.remind_later'),
      reminder: ReminderModel(
        id: now.millisecondsSinceEpoch.toString(),
        contactName: faktur.namaPembeli,
        contactPhone: faktur.teleponPembeli,
        contactAddress: faktur.alamatPembeli,
        serviceName:
            faktur.items.isNotEmpty ? faktur.items.first.namaBarang : '',
        reminderDate: DateUtils.dateOnly(remindAt),
        reminderHour: remindAt.hour,
        reminderMinute: remindAt.minute,
        docType: ReminderDocType.invoice,
        lastItems: faktur.items
            .map((i) => ReminderItem(
                  nama: i.namaBarang,
                  kuantitas: i.kuantitas,
                  satuan: i.satuan,
                  hargaSatuan: i.hargaSatuan,
                ))
            .toList(),
      ),
      preview: PdfPreviewPage(
        title: tr('invoice.preview_title'),
        filename: 'Invoice_${faktur.nomorFaktur.replaceAll('/', '-')}.pdf',
        buildPdf: (format) => PdfService.buildBytes(faktur, format,
            logoBytes: settings.logoBytes,
            signatureBytes: settings.signatureBytes,
            templateConfig: settings.templateConfig,
            showWatermark: !isPro,
            qrisMerchantId: isPro ? settings.qrisMerchantId : null),
      ),
    );
    // The document is already saved, so the form is replaced: back and
    // "Selesai" both return to wherever the form was opened from.
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => ready));
  }
```

Hapus seluruh method `_showReminderDialog` (dari `Future<void> _showReminderDialog(FakturModel faktur) async {` sampai `}` penutupnya, sekitar baris 382–445, tepat sebelum `Future<void> _openCatalog()`).

Import: hapus

```dart
import '../services/reminder_service.dart';
```

dan ganti

```dart
import 'pdf_preview_page.dart';
```

dengan

```dart
import 'document_ready_page.dart';
import 'pdf_preview_page.dart';
```

- [ ] **Step 5: Hapus kunci dialog lama**

Run: `grep -rn "invoice.reminder_" lib`
Expected: hanya 5 definisi di `locale_service.dart` (`reminder_title`, `reminder_body`, `reminder_no`, `reminder_yes`, `reminder_saved`). Hapus kelima baris itu.

- [ ] **Step 6: Verifikasi**

Run: `grep -n "_showReminderDialog\|ReminderService" lib/pages/faktur_page.dart`
Expected: tidak ada output.
Run: `/c/flutter/bin/flutter analyze`
Expected: 9 issue.
Run: `/c/flutter/bin/flutter test`
Expected: semua lulus.

- [ ] **Step 7: Commit**

```bash
git add lib/pages/document_ready_page.dart lib/pages/faktur_page.dart lib/services/locale_service.dart test/pages/document_ready_page_test.dart
git commit -m "feat: invoice ready screen with share and reminder"
```

---

### Task 6: Form struk pola A

**Files:**
- Modify: `lib/pages/struk_page.dart` (ditulis ulang seluruhnya)
- Modify: `lib/services/locale_service.dart`

**Interfaces:**
- `StrukPage({Key? key, HistoryEntry? initialEntry, List<ReminderItem>? reminderItems, String? reminderContactName})` tetap sama untuk semua pemanggil (`main_navigation.dart:192`, `history_page.dart:167`, `reminder_page.dart:113`). Sekarang `StatelessWidget` yang memasang `Theme` hijau di atas `_StrukForm`, supaya sheet dan dialog dari form ikut hijau (`showModalBottomSheet`/`showDialog` menangkap theme dari `context` pemanggil).
- Consumes: `cashChange`, `paymentSegment`, `defaultReminderDate`, `MetodeBayar.qris`, `showItemEditSheet(discount:)`, `CatalogPickerSheet`, `TotalBar`, `DocumentReadyPage`.
- Yang hilang dari file lama: `_ItemCtrls`, `_card`, `_field`, `_qtyBtn`, `_buildTokoBanner`, `_reorderItem`, `_showReminderDialog`, `_CatalogPickerSheet`, `_formKey`.

- [ ] **Step 1: Kunci locale**

Sebelum `};` penutup `_strings`:

```dart
  'receipt.new_title': ['Struk baru', 'New receipt'],
  'receipt.number': ['Nomor struk', 'Receipt number'],
  'receipt.need_number': ['Isi nomor struk dulu', 'Enter a receipt number first'],
  'receipt.payment': ['Pembayaran', 'Payment'],
  'receipt.cash': ['Tunai', 'Cash'],
  'receipt.transfer': ['Transfer', 'Transfer'],
  'receipt.card': ['Kartu', 'Card'],
  'receipt.cash_received': ['Uang diterima', 'Cash received'],
  'receipt.exact': ['Uang pas', 'Exact amount'],
  'receipt.change': ['Kembalian', 'Change'],
  'receipt.short': ['Kurang', 'Short by'],
  'receipt.extras': ['Diskon, catatan', 'Discount, notes'],
  'receipt.extras_title': ['Diskon dan catatan', 'Discount and notes'],
  'receipt.discount': ['Diskon', 'Discount'],
  'receipt.cashier': ['Nama kasir (opsional)', 'Cashier name (optional)'],
  'receipt.date': ['Tanggal & waktu', 'Date & time'],
  'receipt.make': ['Buat struk', 'Create receipt'],
  'receipt.preview_title': ['Preview Struk', 'Receipt Preview'],
```

- [ ] **Step 2: Tulis ulang `lib/pages/struk_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import '../main.dart';
import '../models/catalog_model.dart';
import '../models/faktur_model.dart';
import '../models/history_model.dart';
import '../models/reminder_model.dart';
import '../models/settings_model.dart';
import '../models/struk_model.dart';
import '../services/catalog_service.dart';
import '../services/history_service.dart';
import '../services/locale_service.dart';
import '../services/settings_service.dart';
import '../services/struk_pdf_service.dart';
import '../services/subscription_service.dart';
import '../widgets/catalog_picker_sheet.dart';
import '../widgets/item_edit_sheet.dart';
import '../widgets/paywall_sheet.dart';
import '../widgets/total_bar.dart';
import 'document_ready_page.dart';
import 'pdf_preview_page.dart';

/// Receipts keep the green accent: #047857 under white text (5.48:1), or
/// #34D399 under the dark theme's #0F1117 onPrimary (9.82:1). The input
/// theme hard-codes blue focus, so that is swapped too.
ThemeData _strukTheme(ThemeData base) {
  final green = base.brightness == Brightness.dark
      ? AppColors.strukGreenSoft
      : AppColors.strukGreen;
  final input = base.inputDecorationTheme;
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(primary: green, secondary: green),
    inputDecorationTheme: input.copyWith(
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: green, width: 2),
      ),
      floatingLabelStyle: input.floatingLabelStyle?.copyWith(color: green),
    ),
  );
}

class StrukPage extends StatelessWidget {
  final HistoryEntry? initialEntry;
  final List<ReminderItem>? reminderItems;
  final String? reminderContactName;
  const StrukPage({
    super.key,
    this.initialEntry,
    this.reminderItems,
    this.reminderContactName,
  });

  // The form's state sits below this Theme, so the sheets and dialogs it
  // opens are green as well.
  @override
  Widget build(BuildContext context) => Theme(
        data: _strukTheme(Theme.of(context)),
        child: _StrukForm(
          initialEntry: initialEntry,
          reminderItems: reminderItems,
          reminderContactName: reminderContactName,
        ),
      );
}

class _StrukForm extends StatefulWidget {
  final HistoryEntry? initialEntry;
  final List<ReminderItem>? reminderItems;
  final String? reminderContactName;
  const _StrukForm({
    this.initialEntry,
    this.reminderItems,
    this.reminderContactName,
  });

  @override
  State<_StrukForm> createState() => _StrukFormState();
}

class _StrukFormState extends State<_StrukForm> {
  final _struk = StrukModel();
  SettingsModel _settings = SettingsModel();

  final _nomorCtrl = TextEditingController();
  final _kasirCtrl = TextEditingController();
  final _diskonCtrl = TextEditingController();
  final _bayarCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();

  // Same split as the invoice form: typing happens in sheets or the cash
  // field, so only these listeners rebuild, never the whole page.
  final _items = ValueNotifier<List<ItemStruk>>([]);
  final _total = ValueNotifier<double>(0);
  final _paid = ValueNotifier<double>(0);

  bool _isLoading = true;
  bool _isDirty = false;
  bool _isGenerating = false;

  NumberFormat get _currency => NumberFormat.currency(
        locale: _settings.currencyLocale,
        symbol: _settings.currencySymbol,
        decimalDigits: 0,
      );

  String get _dateLocale => LocaleService.isEn ? 'en_US' : 'id_ID';

  @override
  void initState() {
    super.initState();
    _items.addListener(_recalcTotal);
    _loadSettings();
  }

  void _recalcTotal() {
    _struk.items = _items.value;
    _total.value = _struk.total;
  }

  String _fmtQty(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  static MetodeBayar _parseMetodeBayar(String? value) {
    if (value == null) return MetodeBayar.tunai;
    for (final m in MetodeBayar.values) {
      if (m.label == value || m.name == value) return m;
    }
    return MetodeBayar.tunai;
  }

  Future<void> _loadSettings() async {
    final s = await SettingsService.load();
    final nomorStruk =
        await SettingsService.generateStrukNumber(prefix: s.strukPrefix);
    if (!mounted) return;
    setState(() {
      _settings = s;
      _struk.namaToko = s.namaToko;
      _struk.alamatToko = s.alamat;
      _struk.teleponToko = s.telepon;
      _nomorCtrl.text = nomorStruk;

      final entry = widget.initialEntry;
      final reminderItems = widget.reminderItems;
      if (entry != null) {
        _kasirCtrl.text = entry.namaKasir ?? '';
        _struk.diskon = entry.diskon ?? 0;
        _diskonCtrl.text =
            _struk.diskon > 0 ? _struk.diskon.toInt().toString() : '';
        _struk.metodeBayar = _parseMetodeBayar(entry.metodeBayar);
        _paid.value = entry.jumlahBayar ?? 0;
        _bayarCtrl.text =
            _paid.value > 0 ? _paid.value.toInt().toString() : '';
        _catatanCtrl.text = entry.catatan;
        _items.value = entry.items
            .map((i) => ItemStruk(
                  nama: i.nama,
                  kuantitas: i.kuantitas,
                  satuan: i.satuan,
                  hargaSatuan: i.hargaSatuan,
                  diskon: i.diskon,
                ))
            .toList();
      } else {
        _catatanCtrl.text = s.footerStruk;
        if (reminderItems != null && reminderItems.isNotEmpty) {
          _kasirCtrl.text = widget.reminderContactName ?? '';
          _items.value = reminderItems
              .map((i) => ItemStruk(
                    nama: i.nama,
                    kuantitas: i.kuantitas,
                    satuan: i.satuan,
                    hargaSatuan: i.hargaSatuan,
                  ))
              .toList();
        }
      }
      _isLoading = false;
      _recalcTotal();
    });
  }

  @override
  void dispose() {
    _nomorCtrl.dispose();
    _kasirCtrl.dispose();
    _diskonCtrl.dispose();
    _bayarCtrl.dispose();
    _catatanCtrl.dispose();
    _items.dispose();
    _total.dispose();
    _paid.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _syncToModel() {
    _struk.namaToko = _settings.namaToko;
    _struk.alamatToko = _settings.alamat;
    _struk.teleponToko = _settings.telepon;
    _struk.nomorStruk = _nomorCtrl.text.trim();
    _struk.namaKasir = _kasirCtrl.text.trim();
    _struk.jumlahBayar = _paid.value;
    _struk.catatan = _catatanCtrl.text;
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _editNumber() async {
    var draft = _nomorCtrl.text;
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('receipt.number')),
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

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _struk.tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_struk.tanggal),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _struk.tanggal = DateTime(pickedDate.year, pickedDate.month,
          pickedDate.day, pickedTime.hour, pickedTime.minute);
      _isDirty = true;
    });
  }

  // The item sheet edits ItemFaktur; a receipt item maps onto it one to one,
  // and its discount travels in ItemEditResult.discount.
  ItemFaktur _toSheetItem(ItemStruk i) => ItemFaktur(
        namaBarang: i.nama,
        deskripsi: i.deskripsi,
        kuantitas: i.kuantitas,
        satuan: i.satuan,
        hargaSatuan: i.hargaSatuan,
      );

  ItemStruk _fromSheet(ItemEditResult r) => ItemStruk(
        nama: r.item!.namaBarang,
        deskripsi: r.item!.deskripsi,
        kuantitas: r.item!.kuantitas,
        satuan: r.item!.satuan,
        hargaSatuan: r.item!.hargaSatuan,
        diskon: r.discount,
      );

  Future<void> _addItem() async {
    final result = await showItemEditSheet(context,
        item: ItemFaktur(satuan: 'pcs'),
        currency: _currency,
        isNew: true,
        discount: 0);
    if (result == null || result.deleted) return;
    _markDirty();
    _items.value = [..._items.value, _fromSheet(result)];
  }

  Future<void> _editItem(int index) async {
    final item = _items.value[index];
    final result = await showItemEditSheet(context,
        item: _toSheetItem(item), currency: _currency, discount: item.diskon);
    if (result == null) return;
    if (result.deleted) {
      _removeItem(index);
      return;
    }
    _markDirty();
    _items.value = [..._items.value]..[index] = _fromSheet(result);
  }

  void _stepQty(int index, int delta) {
    final item = _items.value[index];
    if (item.kuantitas + delta < 1) return;
    item.kuantitas += delta;
    _markDirty();
    // Same item objects in a new list: listeners fire, swipe keys stay.
    _items.value = [..._items.value];
  }

  void _removeItem(int index) {
    final list = [..._items.value];
    final removed = list.removeAt(index);
    _markDirty();
    _items.value = list;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content:
            Text(tr('invoice.item_removed').replaceAll('{name}', removed.nama)),
        duration: const Duration(seconds: 4),
        persist: false,
        action: SnackBarAction(
          label: tr('common.undo'),
          onPressed: () {
            if (!mounted) return;
            final restored = [..._items.value];
            restored.insert(index.clamp(0, restored.length), removed);
            _items.value = restored;
          },
        ),
      ));
  }

  Future<void> _addFromCatalog() async {
    final items = await CatalogService.loadAll();
    if (!mounted) return;
    final selected = await showModalBottomSheet<CatalogItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CatalogPickerSheet(
        items: items,
        currencySymbol: _settings.currencySymbol,
        currencyLocale: _settings.currencyLocale,
      ),
    );
    if (selected == null) return;
    _markDirty();
    _items.value = [
      ..._items.value,
      ItemStruk(
        nama: selected.nama,
        deskripsi: selected.deskripsi,
        satuan: selected.satuan,
        hargaSatuan: selected.hargaSatuan,
      ),
    ];
  }

  void _setMethod(MetodeBayar m) => setState(() {
        _struk.metodeBayar = m;
        _isDirty = true;
      });

  void _setPaid(double value) {
    _bayarCtrl.text = value.round().toString();
    _paid.value = value;
    _markDirty();
  }

  Future<void> _generatePdf() async {
    if (_isGenerating) return;
    _syncToModel();
    if (_struk.nomorStruk.isEmpty) {
      _showMessage(tr('receipt.need_number'));
      _editNumber();
      return;
    }
    if (_items.value.isEmpty) {
      _showMessage(tr('invoice.need_item'));
      return;
    }

    setState(() => _isGenerating = true);
    final bool saved;
    var isPro = false;
    try {
      saved = await _saveDocument();
      if (saved) isPro = await SubscriptionService.isPro();
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
    if (!saved || !mounted) return;
    _openReady(isPro);
  }

  /// Checks the quota, then stores the history entry.
  /// False when the paywall blocked it.
  Future<bool> _saveDocument() async {
    if (!await SubscriptionService.canCreateDocument()) {
      if (mounted) showPaywallSheet(context);
      return false;
    }
    final struk = _struk;
    await HistoryService.add(HistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      docType: DocType.struk,
      nomorDokumen: struk.nomorStruk,
      namaKlien: struk.namaKasir,
      totalAmount: struk.total,
      tanggalDokumen: struk.tanggal,
      createdAt: DateTime.now(),
      items: struk.items
          .map((i) => HistoryItem(
                nama: i.nama,
                kuantitas: i.kuantitas,
                satuan: i.satuan,
                hargaSatuan: i.hargaSatuan,
                subtotal: i.subtotal,
                diskon: i.diskon,
              ))
          .toList(),
      catatan: struk.catatan,
      namaToko: struk.namaToko,
      alamatToko: struk.alamatToko,
      namaKasir: struk.namaKasir,
      diskon: struk.diskon,
      metodeBayar: struk.metodeBayar.label,
      jumlahBayar: struk.jumlahBayar,
      kembalian: struk.kembalian,
    ));
    await SubscriptionService.incrementDocCount();
    _isDirty = false;
    return true;
  }

  void _openReady(bool isPro) {
    final struk = _struk;
    final settings = _settings;
    final total = _currency.format(struk.total);
    final now = DateTime.now();
    final remindAt = defaultReminderDate(null, now);
    final ready = DocumentReadyPage(
      title: tr('done.receipt_ready'),
      summary:
          struk.namaKasir.isEmpty ? total : '${struk.namaKasir} · $total',
      shareMessage: tr('done.receipt_message')
          .replaceAll('{number}', struk.nomorStruk)
          .replaceAll('{amount}', total),
      reminderLabel: tr('done.remind_later'),
      reminder: ReminderModel(
        id: now.millisecondsSinceEpoch.toString(),
        // Stored data, not UI text: same fallback the old dialog saved.
        contactName: struk.namaKasir.isNotEmpty ? struk.namaKasir : 'Pelanggan',
        serviceName: struk.items.isNotEmpty ? struk.items.first.nama : '',
        reminderDate: DateUtils.dateOnly(remindAt),
        reminderHour: remindAt.hour,
        reminderMinute: remindAt.minute,
        docType: ReminderDocType.struk,
        lastItems: struk.items
            .map((i) => ReminderItem(
                  nama: i.nama,
                  kuantitas: i.kuantitas,
                  satuan: i.satuan,
                  hargaSatuan: i.hargaSatuan,
                ))
            .toList(),
      ),
      preview: PdfPreviewPage(
        title: tr('receipt.preview_title'),
        filename: 'Struk_${struk.nomorStruk.replaceAll('/', '-')}.pdf',
        buildPdf: (format) => StrukPdfService.buildBytes(struk, format,
            logoBytes: settings.logoBytes,
            currencySymbol: settings.currencySymbol,
            currencyLocale: settings.currencyLocale,
            templateConfig: settings.templateConfig,
            showWatermark: !isPro),
        initialPageFormat:
            const PdfPageFormat(226.77, double.infinity, marginAll: 12),
        canChangePageFormat: false,
      ),
    );
    // Saved already: replace the form so back and "Selesai" return to the
    // caller. The new route sits outside StrukPage, so it gets its own green.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (ctx) =>
            Theme(data: _strukTheme(Theme.of(ctx)), child: ready),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _isDirty = false;
      _nomorCtrl.clear();
      _kasirCtrl.clear();
      _diskonCtrl.clear();
      _bayarCtrl.clear();
      _catatanCtrl.clear();
      _struk.tanggal = DateTime.now();
      _struk.metodeBayar = MetodeBayar.tunai;
      _struk.diskon = 0;
      _paid.value = 0;
      _items.value = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width >= 600 ? ((width - 680) / 2).clamp(24.0, 9999.0) : 20.0;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(tr('invoice.leave_title')),
            content: Text(tr('invoice.leave_body')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(tr('common.cancel'))),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('invoice.leave'),
                    style: TextStyle(
                        color: AppColors.errorFor(Theme.of(ctx).brightness))),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: tr('invoice.reset_form'),
              onPressed: _resetForm,
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
          children: [
            _buildHeader(theme),
            if (_settings.isEmpty) ...[
              const SizedBox(height: 8),
              Text(tr('invoice.store_missing'),
                  style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 24),
            _buildItems(theme),
            const Divider(height: 1),
            const SizedBox(height: 24),
            _buildPayment(theme),
            const Divider(height: 1),
            _buildExtrasRow(theme),
          ],
        ),
        bottomNavigationBar: TotalBar(
          total: _total,
          currency: _currency,
          actionLabel: tr('receipt.make'),
          busy: _isGenerating,
          onAction: _generatePdf,
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final when =
        DateFormat('d MMM, HH:mm', _dateLocale).format(_struk.tanggal);
    return InkWell(
      onTap: _editNumber,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('receipt.new_title'), style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('${_nomorCtrl.text} · $when',
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildItems(ThemeData theme) {
    return ValueListenableBuilder<List<ItemStruk>>(
      valueListenable: _items,
      builder: (context, items, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('invoice.items'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(tr('invoice.no_items'),
                  style: theme.textTheme.bodySmall),
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
                onPressed: _addFromCatalog,
                child: Text(tr('invoice.from_catalog')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemRow(ThemeData theme, ItemStruk item, int index) {
    final isDark = theme.brightness == Brightness.dark;
    final price = '${_currency.format(item.hargaSatuan)} / ${item.satuan}';
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
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nama, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      item.diskon > 0
                          ? '$price · −${_currency.format(item.diskon)}'
                          : price,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: tr('item.qty_less'),
                onPressed:
                    item.kuantitas >= 2 ? () => _stepQty(index, -1) : null,
                icon: const Icon(Icons.remove),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 32),
                child: Text(_fmtQty(item.kuantitas),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall),
              ),
              IconButton(
                tooltip: tr('item.qty_more'),
                onPressed: () => _stepQty(index, 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayment(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr('receipt.payment'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        // "Kartu" stands for debit and kredit; a kredit receipt stays kredit
        // because tapping the already selected segment changes nothing.
        SegmentedButton<MetodeBayar>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
                value: MetodeBayar.tunai, label: Text(tr('receipt.cash'))),
            ButtonSegment(
                value: MetodeBayar.transfer,
                label: Text(tr('receipt.transfer'))),
            ButtonSegment(
                value: MetodeBayar.qris, label: Text(MetodeBayar.qris.label)),
            ButtonSegment(
                value: MetodeBayar.debit, label: Text(tr('receipt.card'))),
          ],
          selected: {paymentSegment(_struk.metodeBayar)},
          onSelectionChanged: (s) => _setMethod(s.first),
          style: SegmentedButton.styleFrom(
            // A tint, not a fill: the filled green belongs to "Buat struk".
            selectedBackgroundColor: primary.withValues(alpha: 0.12),
            selectedForegroundColor: primary,
          ),
        ),
        if (_struk.metodeBayar == MetodeBayar.tunai) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _bayarCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: tr('receipt.cash_received'),
              prefixText: _settings.currencySymbol,
            ),
            onChanged: (v) {
              _paid.value = double.tryParse(v) ?? 0;
              _markDirty();
            },
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => _setPaid(_total.value),
                child: Text(tr('receipt.exact')),
              ),
              // Fixed rupiah notes; they mean nothing in other currencies.
              if (_settings.currency == 'IDR')
                for (final amount in const [50000.0, 100000.0])
                  TextButton(
                    onPressed: () => _setPaid(amount),
                    child: Text(_currency.format(amount)),
                  ),
            ],
          ),
          _buildChange(theme),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildChange(ThemeData theme) {
    return ListenableBuilder(
      listenable: Listenable.merge([_total, _paid]),
      builder: (context, _) {
        final change = cashChange(total: _total.value, paid: _paid.value);
        if (change == null) return const SizedBox.shrink();
        final short = change < 0;
        final color = short ? AppColors.errorFor(theme.brightness) : null;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(tr(short ? 'receipt.short' : 'receipt.change'),
                    style: theme.textTheme.bodyLarge?.copyWith(color: color)),
              ),
              Text(_currency.format(change.abs()),
                  style: theme.textTheme.titleMedium?.copyWith(color: color)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExtrasRow(ThemeData theme) {
    final kasir = _kasirCtrl.text.trim();
    final note = _catatanCtrl.text.trim();
    final parts = [
      if (_struk.diskon > 0)
        '${tr('receipt.discount')} ${_currency.format(_struk.diskon)}',
      if (kasir.isNotEmpty) kasir,
      if (note.isNotEmpty) note,
    ];
    return InkWell(
      onTap: _showExtrasSheet,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('receipt.extras'), style: theme.textTheme.titleSmall),
                  if (parts.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(parts.join(' · '),
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

  Future<void> _showExtrasSheet() async {
    String snapshot() =>
        '${_diskonCtrl.text}|${_kasirCtrl.text}|${_catatanCtrl.text}';
    final before = snapshot();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('receipt.extras_title'),
                    style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _diskonCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: tr('receipt.discount'),
                    prefixText: _settings.currencySymbol,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _kasirCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      InputDecoration(labelText: tr('receipt.cashier')),
                ),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('receipt.date')),
                  trailing: Text(DateFormat('d MMM yyyy, HH:mm', _dateLocale)
                      .format(_struk.tanggal)),
                  onTap: () async {
                    await _pickDateTime();
                    setSheet(() {});
                  },
                ),
                const SizedBox(height: 4),
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
      ),
    );
    if (!mounted) return;
    _struk.diskon = double.tryParse(_diskonCtrl.text) ?? 0;
    _recalcTotal();
    setState(() {
      if (snapshot() != before) _isDirty = true;
    });
  }
}
```

- [ ] **Step 3: Verifikasi**

Run: `grep -nE "Text\(\s*'[A-Z]|labelText: '|hintText: '|tooltip: '|GoogleFonts|fontSize" lib/pages/struk_page.dart`
Expected: tidak ada output.
Run: `grep -rn "StrukPage(" lib`
Expected: pemanggil di `main_navigation.dart`, `history_page.dart`, `reminder_page.dart` tidak berubah dan tetap terkompilasi.
Run: `/c/flutter/bin/flutter analyze`
Expected: 9 issue. `_strings` tidak boleh punya kunci ganda (`equal_keys_in_map`).
Run: `/c/flutter/bin/flutter test`
Expected: semua lulus (114 baseline + 10 Task 1 + 2 Task 2 + 3 Task 5 = 129).

- [ ] **Step 4: Commit**

```bash
git add lib/pages/struk_page.dart lib/services/locale_service.dart
git commit -m "feat: receipt form pattern A with payment and change"
```

---

## Cek manual (user, di HP/emulator)

Setelah semua task selesai:

1. **Form struk**
   - Tambah item lewat "Tambah item" dan "Dari katalog".
   - Stepper − / + di baris mengubah jumlah dan total; − nonaktif di jumlah 1.
   - Tap baris membuka sheet item; isi "Diskon item", subtotal di tombol Simpan turun, baris menampilkan "· −Rp …".
   - Geser item untuk hapus, Urungkan dalam 4 detik mengembalikannya di posisi semula.
   - Tap judul "Struk baru" mengubah nomor.
2. **Pembayaran**
   - Segmented Tunai/Transfer/QRIS/Kartu; field uang diterima hanya saat Tunai (tidak untuk Kartu). Pilih Kartu, buat struk: PDF dan Riwayat tertulis "Kartu Debit".
   - "Uang pas" mengisi total; Rp 50.000 / Rp 100.000 mengisi nominalnya (hanya mata uang IDR).
   - Ketik uang diterima: baris Kembalian berubah tanpa halaman berkedip; di bawah total tampil "Kurang" merah.
   - Duplikat struk lama dari Riwayat yang metodenya Kartu Kredit: segmen Kartu tersorot, PDF tetap tertulis "Kartu Kredit" selama kasir tidak memilih segmen lain.
   - Skala teks 200%: empat segmen tetap terbaca (cek label "Transfer").
3. **Diskon, catatan**
   - Sheet berisi Diskon, Nama kasir, Tanggal & waktu, Catatan. Setelah ditutup, total turun sesuai diskon dan baris menampilkan ringkasannya.
4. **Layar siap (invoice dan struk)**
   - Centang muncul membesar sekali, HP bergetar ringan. Dengan "Hapus animasi" di Aksesibilitas, centang langsung tampil.
   - "Kirim lewat WhatsApp" membuka share sheet berisi PDF + pesan; pilih WhatsApp, pesan dan lampiran terkirim.
   - "Bagikan, cetak, simpan" membuka sheet Cetak / Simpan; keduanya jalan.
   - "Lihat PDF" membuka preview; "Selesai" di preview kembali ke layar siap.
   - Toggle pengingat: tanggal di bawahnya = jatuh tempo 09:00 (invoice dengan jatuh tempo) atau 30 hari lagi 09:00. Nyalakan, cek muncul di tab Pengingat; matikan, hilang.
   - "Selesai" dan tombol kembali menutup layar siap saja dan kembali ke asal (Beranda, Riwayat, atau Pengingat), Beranda sudah memuat dokumen baru.
5. **Tampilan**
   - Mode terang dan gelap: tombol "Buat struk", segmen terpilih, nominal cepat, fokus field, dan sheet di struk berwarna hijau; teks di tombol hijau gelap terbaca (teks gelap).
   - Bahasa English di form struk, layar siap, sheet aksi PDF, dan judul "Done" di preview.
   - Skala teks 200%: segmented control, baris item dengan stepper, bar total, dan layar siap tidak terpotong.
6. **TalkBack**
   - Stepper terbaca "Kurangi jumlah" / "Tambah jumlah".
   - Latar hapus item terbaca "Hapus".
   - Toggle pengingat terbaca beserta tanggalnya.
