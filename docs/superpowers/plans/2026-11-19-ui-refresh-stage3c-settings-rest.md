# UI Refresh Tahap 3c (Pengaturan + layar sisa) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pengaturan mengikuti mockup 05 kanan, dan layar sisa ikut sistem desain Beranda:
- `settings_page.dart` (2284 baris) dipecah: 11 sub-halaman + mixin pindah ke `lib/pages/settings/`, perilaku tidak berubah.
- Hub Pengaturan jadi daftar polos: header (avatar, nama toko, paket + bar kuota tipis, tautan Pro), grup Toko / Dokumen / Aplikasi, nilai saat ini di kanan, label "Pro" tertulis, Sandbox hanya `kDebugMode`.
- Invoice berulang ditambah ke sheet "Buat" (tetap ada di Pengaturan).
- Onboarding, login, splash, invoice berulang, paywall: tidak ditata ulang, hanya ikut tema, `textTheme`, kontras, `tr()`.

**Architecture:**
- Pemecahan file dikerjakan dulu, sebagai task murni pindah (skrip `sed`), lalu dicek dengan diff yang membuktikan isi kode sama.
- Sub-halaman jadi kelas publik (`ProfileSubPage`, ...), state tetap privat. `_SettingsSubPageMixin` jadi `SettingsSubPageMixin` di file sendiri.
- Header Pengaturan jadi widget publik `SettingsHeader` (hanya butuh dua model), supaya bisa dites tanpa Firebase/SharedPreferences.
- Satu test pemindai kunci `tr()` menjaga agar teks tidak tampil sebagai kunci mentah (bug yang sekarang ada di Backup dan Sandbox).

**Tech Stack:** Flutter (SDK di `C:\flutter`, tidak ada di PATH), Material 3, `intl`, `flutter_test`.

Spec: `docs/superpowers/specs/2026-11-19-ui-refresh-design.md`, bagian "Sistem desain", "Pengaturan", "Pengingat, onboarding, login, splash", "Gerak dan kehalusan", "Bahasa", "Verifikasi", "Di luar cakupan". Mockup: `docs/mockups/05-struk-settings.svg` (kanan).

## Global Constraints

- Tidak ada package baru. Font tetap Inter.
- Aksen dari `colorScheme.primary`: #2563EB terang / #60A5FA gelap, teks di atasnya `colorScheme.onPrimary` (putih / #0F1117).
- Warna status lewat `AppColors.errorFor/warningFor/successFor(brightness)` (`lib/main.dart:107-116`). Tidak ada `Colors.red`, `Colors.orange`, `Colors.green`, `Color(0xFFFFA000)` baru.
- Teks memakai `textTheme` tahap 1 (`lib/main.dart:238-258`):
  - `displaySmall` 32/700: nama merek di splash/login
  - `headlineSmall` 22/700: judul halaman
  - `titleMedium` 17/600: judul bagian
  - `titleSmall` 15/600: judul baris
  - `bodyLarge`/`bodyMedium` 15/400
  - `bodySmall` 13/400 abu-abu (#6B7280 terang 4.83:1, #9CA3AF gelap 7.43:1)
- Tidak ada `GoogleFonts.*()` baru, tidak ada `fontSize` literal baru, tidak ada teks abu lewat `withValues(alpha: ...)`.
- Tanpa kartu bergaris baru. Bagian dipisah jarak + `Divider(height: 1)`.
- Status = titik + teks (`StatusLabel`), tidak pernah warna saja.
- Area sentuh ≥ 48dp. `IconButton` tanpa teks wajib punya `tooltip` (TalkBack).
- Semua teks baru lewat `tr()` di `lib/services/locale_service.dart`:
  - Format `'key': ['id', 'en']`.
  - Entri baru ditambah tepat sebelum `};` penutup map `_strings` (sekarang baris 468), kecuali disebut lain.
  - Placeholder `{n}`, `{max}`, `{label}` lalu `.replaceAll(...)`, sama seperti `about.version`.
- Tanggal diformat dengan locale `LocaleService.isEn ? 'en_US' : 'id_ID'`.
- Animasi: kalau `MediaQuery.disableAnimationsOf(context)` true, durasi `Duration.zero`.
- Komentar kode singkat, menjelaskan alasan. Tanpa emoji, kode mati, atau kode yang dikomentari.
- Commit: subjek pendek konvensional, tanpa trailer `Co-Authored-By` dan tanpa menyebut AI.
- Perintah Flutter: `/c/flutter/bin/flutter` (Git Bash).
- Baseline: `flutter analyze` = 9 issue:
  - `recurring_invoice_page.dart:349`
  - `settings_page.dart:1892/1911/1949`
  - `paywall_sheet.dart:83/86/88`
  - dua file test
  
  `flutter test` = 114 lulus. Hitungan analyze yang diharapkan ditulis per task.

## Keputusan yang menyimpang dari spec / perlu diketahui

- **Nama kelas sub-halaman** kehilangan `_` (jadi publik) karena tiap file adalah library sendiri. Kelas State, `_BackupTile`, `_BankCtrls` tetap privat. Konstruktor publik mendapat `super.key` (lint `use_key_in_widget_constructors` di `flutter_lints` 6). `BackupSubPage` mendapat konstruktor `const` karena sebelumnya tidak punya. Ini satu-satunya perubahan kode di Task 1.
- **Header:** avatar = logo toko (kalau ada), selain itu ikon toko. Mockup menampilkan inisial "NT", tapi itu butuh logika baru tanpa manfaat fungsional.
- **Grup:** spec menyebut tiga grup. Baris Akun (masuk/keluar Google) masuk grup Aplikasi. Kontak dan QRIS masuk grup Toko, bersama Profil, Rekening, dan Tanda tangan.
- **Nilai di kanan:**
  - Cadangan tidak punya nilai, karena status sinkron ("Tersinkron" di mockup) tidak disimpan di mana pun.
  - Tentang menampilkan versi app.
  - Template menampilkan label template invoice · struk, sama seperti subtitle lama.
- **Label "Pro"** = teks `bodySmall` di kolom nilai untuk pengguna gratis, menggantikan badge oranye. Tap tetap membuka paywall (perilaku lama).
- **Sandbox** tidak ikut dirapikan (Task 2), karena hanya terlihat di build debug. Hanya kuncinya yang diperbaiki (Task 5). Tiga issue analyze di Sandbox tetap ada, hanya pindah file.
- **Bug yang ditemukan:** hub dan sub-halaman Backup/Sandbox memanggil 20 kunci `tr()` yang tidak ada di map, jadi pengguna melihat teks mentah seperti `settings.export_backup_desc`. Hub sudah tidak memakainya setelah Task 4. Sisanya diarahkan ke kunci yang sudah ada di Task 5.
- **Paywall:**
  - Tombol "Activate Pro (Debug)" sekarang tampil di build rilis dan memberi Pro gratis. Task 10 menyembunyikannya di balik `kDebugMode`, sama seperti Sandbox.
  - Oranye (#FFA000) diganti aksen biru, supaya selaras dengan Beranda.
- **Invoice berulang (halaman):**
  - Kartu bergaris jadi baris polos + `Divider`. Chip hijau `Colors.green` jadi `StatusLabel`.
  - `RepeatInterval.label` (`reminder_model.dart`) tetap bahasa Indonesia, karena model itu juga dipakai Pengingat (rencana lain).
  - "Rp" tetap tertulis tetap (format mata uang di luar lingkup).
- **Onboarding dan splash tidak ditata ulang** (spec "Di luar cakupan"). Kartu pratinjau onboarding dan kotak tips splash tetap ada. Yang berubah hanya teks, warna teks, `tr()`, area sentuh tombol kembali, dan animasi yang menghormati `disableAnimations`.
- **Konflik merge:** Task 6 menyentuh `main_navigation.dart` (sheet "Buat"), dan semua task menambah kunci di akhir `_strings`. Kalau rencana tahap 3 lain sudah lebih dulu masuk, sisipkan setelah entri terakhir yang ada.

## File Structure

| File | Perubahan |
|---|---|
| `lib/pages/settings/settings_sub_page_mixin.dart` (baru) | `SettingsSubPageMixin` (dulu `_SettingsSubPageMixin`) |
| `lib/pages/settings/{profile,contact,invoice_settings,struk,template,signature,bank,backup,sandbox,about,qris}_sub_page.dart` (baru) | satu sub-halaman per file |
| `lib/pages/settings_page.dart` | hanya hub; `SettingsHeader` baru; daftar polos |
| `lib/pages/main_navigation.dart` | baris "Invoice berulang" di sheet "Buat" |
| `lib/pages/onboarding_page.dart`, `splash_page.dart`, `login_page.dart`, `recurring_invoice_page.dart`, `lib/widgets/paywall_sheet.dart` | `textTheme`, kontras, `tr()` |
| `lib/services/locale_service.dart` | kunci baru `settings.*`, `onboarding.*`, `splash.*`, `recurring.pick_contact` |
| `test/pages/settings_header_test.dart`, `test/services/tr_keys_test.dart` (baru) | test |

---

### Task 1: Pecah `settings_page.dart` (murni pindah)

Tidak ada perubahan kode selain baris `import`, nama kelas (hapus `_` supaya bisa dipakai lintas file), dan `super.key` di konstruktor publik.

**Files:**
- Create: `lib/pages/settings/settings_sub_page_mixin.dart` dan 11 file `lib/pages/settings/*_sub_page.dart`
- Modify: `lib/pages/settings_page.dart` (sisa baris 1-684, import diganti)

**Interfaces:**
- Produces:
  - `mixin SettingsSubPageMixin<T extends StatefulWidget> on State<T>` dengan `isSaving`, `saveSettings`, `buildField`, `buildSaveButton` (isi sama).
  - `ProfileSubPage`, `ContactSubPage`, `InvoiceSettingsSubPage`, `StrukSubPage`, `TemplateSubPage`, `SignatureSubPage`, `BankSubPage`, `QrisSubPage`: `({Key? key, required SettingsModel settings})`.
  - `BackupSubPage`, `SandboxSubPage`, `AboutSubPage`: `({Key? key})`.

Rentang baris di `settings_page.dart` sekarang (sudah dicek: tiap rentang mulai di baris `class`/`mixin` dan berakhir di `}` penutupnya; banner `// ═══` di antaranya dibuang):

| File | Baris |
|---|---|
| `settings_sub_page_mixin.dart` | 690-746 |
| `profile_sub_page.dart` | 752-901 |
| `contact_sub_page.dart` | 907-964 |
| `invoice_settings_sub_page.dart` | 970-1058 |
| `struk_sub_page.dart` | 1064-1113 |
| `template_sub_page.dart` | 1119-1409 |
| `signature_sub_page.dart` | 1415-1501 |
| `bank_sub_page.dart` | 1507-1613 dan 2188-2208 (`_BankCtrls`, hanya dipakai Bank) |
| `backup_sub_page.dart` | 1619-1773 (termasuk `_BackupTile`) |
| `sandbox_sub_page.dart` | 1779-2041 |
| `about_sub_page.dart` | 2047-2182 |
| `qris_sub_page.dart` | 2214-2284 |

- [ ] **Step 1: Pastikan baseline**

Run: `cd /c/Work/faktur_gen && git status --short lib test && /c/flutter/bin/flutter analyze 2>&1 | tail -1`
Expected: tidak ada perubahan di `lib`/`test`, dan `9 issues found.`
Run: `sed -n '690p;752p;2188p;2214p;2284p' lib/pages/settings_page.dart`
Expected: `mixin _SettingsSubPageMixin...`, `class _ProfileSubPage...`, `class _BankCtrls {`, `class _QrisSubPage...`, `}`. Kalau tidak cocok, file sudah berubah; berhenti dan laporkan.

- [ ] **Step 2: Jalankan skrip pemindahan**

Simpan sebagai `/tmp/split_settings.sh` lalu jalankan `bash /tmp/split_settings.sh`:

```bash
set -e
cd /c/Work/faktur_gen
S=lib/pages/settings_page.dart
D=lib/pages/settings
mkdir -p $D

# split <file> <imports> <range>...: imports, then each line range of the old file.
split() {
  out=$D/$1
  printf '%s\n' "$2" > $out
  shift 2
  for r in "$@"; do
    printf '\n' >> $out
    sed -n "${r}p" $S >> $out
  done
}

MAT="import 'package:flutter/material.dart';"
MODEL="import '../../models/settings_model.dart';"
TR="import '../../services/locale_service.dart';"
MIX="import 'settings_sub_page_mixin.dart';"

split settings_sub_page_mixin.dart "$MAT
import '../../main.dart';
$MODEL
$TR
import '../../services/settings_service.dart';" 690,746

split profile_sub_page.dart "$MAT
import 'package:image_picker/image_picker.dart';
$MODEL
$TR
$MIX" 752,901

split contact_sub_page.dart "$MAT
$MODEL
$TR
$MIX" 907,964

split invoice_settings_sub_page.dart "$MAT
$MODEL
$TR
$MIX" 970,1058

split struk_sub_page.dart "$MAT
$MODEL
$TR
$MIX" 1064,1113

split template_sub_page.dart "$MAT
import 'package:google_fonts/google_fonts.dart';
import '../../models/doc_template_config.dart';
$MODEL
$TR
$MIX" 1119,1409

split signature_sub_page.dart "import 'dart:typed_data';
$MAT
$MODEL
$TR
import '../../widgets/signature_pad.dart';
$MIX" 1415,1501

split bank_sub_page.dart "$MAT
$MODEL
$TR
$MIX" 1507,1613 2188,2208

split backup_sub_page.dart "$MAT
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/backup_service.dart';
$TR" 1619,1773

split sandbox_sub_page.dart "$MAT
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/backup_service.dart';
$TR
import '../../services/notification_service.dart';
import '../../services/reminder_service.dart';" 1779,2041

split about_sub_page.dart "$MAT
import 'package:google_fonts/google_fonts.dart';
$TR
import '../../services/updater_service.dart';" 2047,2182

split qris_sub_page.dart "$MAT
import 'package:google_fonts/google_fonts.dart';
$MODEL
$TR
import '../../services/settings_service.dart';" 2214,2284

# The hub keeps lines 1-684.
sed -i '685,2284d' $S

# Public names across files; \b keeps the private *State classes untouched.
R='s/\b_SettingsSubPageMixin\b/SettingsSubPageMixin/g
s/\b_ProfileSubPage\b/ProfileSubPage/g
s/\b_ContactSubPage\b/ContactSubPage/g
s/\b_InvoiceSettingsSubPage\b/InvoiceSettingsSubPage/g
s/\b_StrukSubPage\b/StrukSubPage/g
s/\b_TemplateSubPage\b/TemplateSubPage/g
s/\b_SignatureSubPage\b/SignatureSubPage/g
s/\b_BankSubPage\b/BankSubPage/g
s/\b_BackupSubPage\b/BackupSubPage/g
s/\b_SandboxSubPage\b/SandboxSubPage/g
s/\b_AboutSubPage\b/AboutSubPage/g
s/\b_QrisSubPage\b/QrisSubPage/g'
echo "$R" > /tmp/settings_renames.sed
sed -i -f /tmp/settings_renames.sed $S $D/*.dart

# Public widgets need a key parameter (use_key_in_widget_constructors).
sed -i -E 's/^(  const [A-Za-z]+SubPage)\(\{required/\1({super.key, required/' $D/*.dart
sed -i -E 's/^(  const (Sandbox|About)SubPage)\(\);/\1({super.key});/' $D/*.dart
sed -i 's/^class BackupSubPage extends StatelessWidget {$/&\n  const BackupSubPage({super.key});\n/' $D/backup_sub_page.dart

# Hub imports: drop what moved out, add the sub-page files.
{ cat <<'EOF'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/settings_model.dart';
import '../models/subscription_model.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/settings_service.dart';
import '../services/subscription_service.dart';
import '../services/theme_service.dart';
import '../services/updater_service.dart';
import '../widgets/paywall_sheet.dart';
import 'recurring_invoice_page.dart';
import 'settings/about_sub_page.dart';
import 'settings/backup_sub_page.dart';
import 'settings/bank_sub_page.dart';
import 'settings/contact_sub_page.dart';
import 'settings/invoice_settings_sub_page.dart';
import 'settings/profile_sub_page.dart';
import 'settings/qris_sub_page.dart';
import 'settings/sandbox_sub_page.dart';
import 'settings/signature_sub_page.dart';
import 'settings/struk_sub_page.dart';
import 'settings/template_sub_page.dart';
EOF
tail -n +21 $S; } > $S.tmp && mv $S.tmp $S
```

- [ ] **Step 3: Buktikan murni pindah**

Run:

```bash
cd /c/Work/faktur_gen
git show HEAD:lib/pages/settings_page.dart | sed -f /tmp/settings_renames.sed \
  | grep -v '^import ' | grep -v '^\s*$' | sort > /tmp/old.txt
cat lib/pages/settings_page.dart lib/pages/settings/*.dart \
  | grep -v '^import ' | grep -v '^\s*$' | sort > /tmp/new.txt
diff /tmp/old.txt /tmp/new.txt | grep '^[<>]' \
  | grep -v '^< // ' | grep -v 'super.key' | grep -vE '^< +const [A-Za-z]+SubPage\('
```

Expected: tidak ada output. Artinya selain banner komentar yang dibuang dan baris konstruktor, setiap baris kode lama ada tepat sekali di file baru.

Run: `grep -c 'super.key' lib/pages/settings/*.dart`
Expected: 1 di tiap file `*_sub_page.dart` (11 file), 0 di `settings_sub_page_mixin.dart`.
Run: `wc -l lib/pages/settings_page.dart`
Expected: sekitar 687 baris.

- [ ] **Step 4: Analyze dan test**

Run: `/c/flutter/bin/flutter analyze 2>&1 | tail -12`
Expected: `9 issues found.` Tiga `use_build_context_synchronously` sekarang dilaporkan di `lib\pages\settings\sandbox_sub_page.dart`, bukan `settings_page.dart`. Tidak ada issue lain yang baru.

Kalau ada `undefined_identifier`/`uri_does_not_exist`/`unused_import`, perbaiki **hanya baris import** di file itu. Jangan ubah kode lain.

Run: `/c/flutter/bin/flutter test 2>&1 | tail -1`
Expected: `+114: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/pages/settings_page.dart lib/pages/settings
git commit -m "refactor: split settings sub-pages into own files"
```

---

### Task 2: Sub-halaman ikut sistem desain

Tampilan dan perilaku sama. Yang berubah hanya:
- teks lewat `tr()`
- gaya teks lewat `textTheme`
- warna merah/oranye lewat `AppColors`
- tombol ikon diberi tooltip
- titik warna template diberi area sentuh 48dp

`sandbox_sub_page.dart` tidak disentuh.

**Files:**
- Modify: `lib/pages/settings/settings_sub_page_mixin.dart`, `profile_sub_page.dart`, `contact_sub_page.dart`, `invoice_settings_sub_page.dart`, `struk_sub_page.dart`, `template_sub_page.dart`, `signature_sub_page.dart`, `bank_sub_page.dart`, `backup_sub_page.dart`, `about_sub_page.dart`, `qris_sub_page.dart`
- Modify: `lib/services/locale_service.dart`

**Interfaces:**
- Consumes: `AppColors.errorFor/warningFor` (`lib/main.dart`), `textTheme` tahap 1.
- Produces: kunci `settings.required`, `settings.npwp_hint`, `settings.website_hint`, `settings.footer_hint`, `settings.bank_hint`.

- [ ] **Step 1: Kunci baru**

`lib/services/locale_service.dart`, sebelum `};` penutup `_strings`:

```dart
  'settings.required': ['{label} wajib diisi', '{label} is required'],
  'settings.npwp_hint': ['cth: 00.000.000.0-000.000', 'e.g. 00.000.000.0-000.000'],
  'settings.website_hint': ['cth: www.tokosaya.com', 'e.g. www.mystore.com'],
  'settings.footer_hint': ['cth: Terima kasih atas kunjungan Anda!', 'e.g. Thank you for visiting!'],
  'settings.bank_hint': ['cth: BCA, Mandiri', 'e.g. BCA, Mandiri'],
```

Judul bagian template jadi sentence case. Ganti baris 207-210:

```dart
  'template.invoice_design': ['DESAIN INVOICE', 'INVOICE DESIGN'],
  'template.receipt_design': ['DESAIN STRUK', 'RECEIPT DESIGN'],
  'template.customize': ['KUSTOMISASI', 'CUSTOMIZATION'],
  'template.primary_color': ['WARNA UTAMA', 'PRIMARY COLOR'],
```

dengan:

```dart
  'template.invoice_design': ['Desain invoice', 'Invoice design'],
  'template.receipt_design': ['Desain struk', 'Receipt design'],
  'template.customize': ['Kustomisasi', 'Customization'],
  'template.primary_color': ['Warna utama', 'Primary color'],
```

- [ ] **Step 2: Mixin**

`settings_sub_page_mixin.dart`, di `buildField`. Old:

```dart
          ? (v) => (v == null || v.isEmpty) ? '$label wajib diisi' : null
```

New:

```dart
          ? (v) => (v == null || v.isEmpty)
              ? tr('settings.required').replaceAll('{label}', label)
              : null
```

- [ ] **Step 3: Profil, Kontak, Pajak, Struk: label dan hint lewat `tr()`**

`profile_sub_page.dart`:
- Tambah `import '../../main.dart';` setelah import `image_picker`.
- Old:

```dart
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(tr('settings.delete_logo'),
                    style: const TextStyle(color: Colors.red)),
```

  New:

```dart
                leading: Icon(Icons.delete_outline,
                    color: AppColors.errorFor(Theme.of(context).brightness)),
                title: Text(tr('settings.delete_logo'),
                    style: TextStyle(
                        color: AppColors.errorFor(Theme.of(context).brightness))),
```

- Ikon pensil di atas lingkaran biru. Di mode gelap, putih di atas #60A5FA hanya 2.5:1. Old: `child: const Icon(Icons.edit, color: Colors.white, size: 12),`. New: `child: Icon(Icons.edit, color: theme.colorScheme.onPrimary, size: 12),` (`theme` sudah ada di `build`).
- Old: `label: 'NPWP', hint: 'cth: 00.000.000.0-000.000',`. New: `label: tr('settings.npwp'), hint: tr('settings.npwp_hint'),`

`contact_sub_page.dart`:
- Old: `label: 'Email',`. New: `label: tr('settings.email'),`
- Old: `label: 'Website', hint: 'cth: www.tokosaya.com',`. New: `label: tr('settings.website'), hint: tr('settings.website_hint'),`

`invoice_settings_sub_page.dart`:
- Old: `label: 'Tarif Pajak (%)',`. New: `label: tr('settings.tax_rate'),`
- Old: `decoration: const InputDecoration(labelText: 'Mata Uang'),`. New: `decoration: InputDecoration(labelText: tr('settings.currency')),`
- Old: `label: 'Prefix Invoice',`. New: `label: tr('settings.prefix_invoice'),`
- Old: `label: 'Prefix Struk',`. New: `label: tr('settings.prefix_receipt'),`

`struk_sub_page.dart`. Old:

```dart
            label: 'Pesan Footer Struk',
            hint: 'cth: Terima kasih atas kunjungan Anda!',
```

New:

```dart
            label: tr('settings.footer_receipt'),
            hint: tr('settings.footer_hint'),
```

- [ ] **Step 4: Template**

`template_sub_page.dart`:

1. Empat judul bagian memakai blok gaya yang sama. Ganti **semua 4** kemunculan. Old:

```dart
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              letterSpacing: 0.8,
            ),
```

   New:

```dart
            style: theme.textTheme.titleMedium,
```

2. Di `_templateOption`. Old:

```dart
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.45),
                    ),
                  ),
```

   New:

```dart
                  Text(label, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(description, style: theme.textTheme.bodySmall),
```

3. Di `_toggleTile`. Old:

```dart
      title: Text(title,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4)))
          : null,
```

   New:

```dart
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle, style: theme.textTheme.bodySmall)
          : null,
```

4. Titik warna 36dp jadi area sentuh 48dp. Hapus jarak `Wrap`, karena padding 6 di tiap titik sudah memberi jarak 12. Old:

```dart
            spacing: 10,
            runSpacing: 10,
```

   New: hapus kedua baris itu.

   Ganti seluruh method `_colorDot` dengan:

```dart
  Widget _colorDot(ThemeData theme, int colorValue) {
    final isSelected = _config.primaryColorValue == colorValue;
    // 36dp dot plus 6dp padding on each side = 48dp tap target.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _config.primaryColorValue = colorValue),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Color(colorValue),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Color(colorValue).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
```

5. Hapus `import 'package:google_fonts/google_fonts.dart';` (tidak ada `GoogleFonts` lagi di file ini).

- [ ] **Step 5: Tanda tangan, Rekening**

`signature_sub_page.dart`:
- Tambah `import '../../main.dart';`.
- Old:

```dart
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
```

  New:

```dart
            IconButton(
              tooltip: tr('common.delete'),
              icon: Icon(Icons.delete_outline,
                  color: AppColors.errorFor(theme.brightness)),
```

- Old:

```dart
                        Text(tr('settings.sign_tap'),
                            style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant)),
```

  New:

```dart
                        Text(tr('settings.sign_tap'),
                            style: theme.textTheme.bodySmall),
```

- Old:

```dart
            tr('settings.sign_note'),
            style: TextStyle(
                fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
```

  New:

```dart
            tr('settings.sign_note'),
            style: theme.textTheme.bodySmall,
```

`bank_sub_page.dart`:
- Tambah `import '../../main.dart';`.
- Old: `style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),`. New: `style: theme.textTheme.titleSmall),`
- Old:

```dart
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
```

  New:

```dart
                          tooltip: tr('common.delete'),
                          icon: Icon(Icons.delete_outline,
                              color: AppColors.errorFor(theme.brightness),
                              size: 20),
```

- Old: `hint: 'cth: BCA, Mandiri'`. New: `hint: tr('settings.bank_hint')`

- [ ] **Step 6: Backup, Tentang, QRIS**

`backup_sub_page.dart`:
- Old:

```dart
            tr('settings.backup_note'),
            style: TextStyle(
                fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
```

  New:

```dart
            tr('settings.backup_note'),
            style: theme.textTheme.bodySmall,
```

- `Colors.orange` di atas putih hanya ~2.2:1. Old:

```dart
            child: Text(tr('settings.import'), style: const TextStyle(color: Colors.orange)),
```

  New:

```dart
            child: Text(tr('settings.import'),
                style: TextStyle(
                    color: AppColors.warningFor(Theme.of(ctx).brightness))),
```

- Di `_BackupTile`. Old:

```dart
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5))),
```

  New:

```dart
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
```

- Hapus import `google_fonts`.

`about_sub_page.dart`. Ganti blok `style:` berikut:

| Teks | Old `style:` | New `style:` |
|---|---|---|
| `'Faktura'` | `GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)` | `theme.textTheme.headlineSmall` |
| `tr('about.subtitle')` | `GoogleFonts.inter(fontSize: 14, color: ...alpha: 0.5)` | `theme.textTheme.bodySmall` |
| `tr('about.version')...` | `GoogleFonts.inter(fontSize: 12, color: ...alpha: 0.35)` | `theme.textTheme.bodySmall` |
| `tr('about.made_with')` | `GoogleFonts.inter(fontSize: 12, color: ...alpha: 0.3)` | `theme.textTheme.bodySmall` |
| `title` di `_infoTile` | `GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: ...)` | `theme.textTheme.titleSmall` |
| `subtitle` di `_infoTile` | `GoogleFonts.inter(fontSize: 12, color: ...alpha: 0.5, height: 1.4)` | `theme.textTheme.bodySmall` |

Setiap `GoogleFonts.inter(...)` (beberapa baris) diganti seluruhnya dengan satu ekspresi di kolom kanan. Lalu hapus import `google_fonts`.

`qris_sub_page.dart`. Old:

```dart
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
```

New:

```dart
            style: theme.textTheme.bodySmall,
```

Lalu hapus import `google_fonts`.

- [ ] **Step 7: Verifikasi**

Run: `cd /c/Work/faktur_gen && grep -l GoogleFonts lib/pages/settings/*.dart`
Expected: hanya `lib/pages/settings/sandbox_sub_page.dart`.
Run: `grep -nE "Colors\.(red|orange)|wajib diisi|'cth:|label: '[A-Z]|labelText: '[A-Z]" lib/pages/settings/*.dart | grep -v sandbox_sub_page`
Expected: tidak ada output.
Run: `/c/flutter/bin/flutter analyze 2>&1 | tail -1`
Expected: `9 issues found.` `_strings` tidak boleh punya kunci ganda (`equal_keys_in_map`).
Run: `/c/flutter/bin/flutter test 2>&1 | tail -1`
Expected: `+114: All tests passed!`

- [ ] **Step 8: Commit**

```bash
git add lib/pages/settings lib/services/locale_service.dart
git commit -m "fix: settings sub-pages follow design system"
```

---

### Task 3: `SettingsHeader`

**Files:**
- Modify: `lib/pages/settings_page.dart` (tambah kelas di akhir file)
- Modify: `lib/services/locale_service.dart`
- Test: `test/pages/settings_header_test.dart`

**Interfaces:**
- Consumes:
  - `SettingsModel.namaToko`, `hasLogo`, `logoBytes`
  - `SubscriptionModel.isPro`, `monthlyDocCount`
  - `SubscriptionService.freeMonthlyLimit` (30)
- Produces: `class SettingsHeader extends StatelessWidget` dengan field `{required SettingsModel settings, required SubscriptionModel sub, required VoidCallback onUpgrade}`.

- [ ] **Step 1: Tulis test yang gagal**

`test/pages/settings_header_test.dart`:

```dart
import 'package:faktur_gen/models/settings_model.dart';
import 'package:faktur_gen/models/subscription_model.dart';
import 'package:faktur_gen/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(SubscriptionModel sub, {VoidCallback? onUpgrade}) => MaterialApp(
      home: Scaffold(
        body: SettingsHeader(
          settings: SettingsModel(namaToko: 'Toko Maju'),
          sub: sub,
          onUpgrade: onUpgrade ?? () {},
        ),
      ),
    );

double? _barValue(WidgetTester tester) => tester
    .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
    .value;

void main() {
  testWidgets('free plan shows usage, a thin bar and the Pro link',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
        _app(SubscriptionModel(monthlyDocCount: 12), onUpgrade: () => taps++));
    expect(find.text('Toko Maju'), findsOneWidget);
    expect(find.text('Gratis · 12 dari 30 dokumen bulan ini'), findsOneWidget);
    expect(_barValue(tester), closeTo(0.4, 1e-9));
    await tester.tap(find.text('Pro'));
    expect(taps, 1);
  });

  testWidgets('bar stays full past the limit', (tester) async {
    await tester.pumpWidget(_app(SubscriptionModel(monthlyDocCount: 45)));
    expect(_barValue(tester), 1);
  });

  testWidgets('pro plan hides the bar and the link', (tester) async {
    await tester.pumpWidget(_app(SubscriptionModel(
      tier: SubscriptionTier.pro,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    )));
    expect(find.text('Pro · dokumen tak terbatas'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Pro'), findsNothing);
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `/c/flutter/bin/flutter test test/pages/settings_header_test.dart`
Expected: FAIL, `SettingsHeader` tidak ditemukan.

- [ ] **Step 3: Implementasi**

`lib/services/locale_service.dart`, sebelum `};`:

```dart
  'settings.plan_free': ['Gratis · {n} dari {max} dokumen bulan ini', 'Free · {n} of {max} documents this month'],
  'settings.plan_pro': ['Pro · dokumen tak terbatas', 'Pro · unlimited documents'],
```

Tambahkan di akhir `lib/pages/settings_page.dart`:

```dart

/// Top of Pengaturan: store avatar and name, plan, monthly quota as a thin
/// bar, and the Pro link for free users.
class SettingsHeader extends StatelessWidget {
  final SettingsModel settings;
  final SubscriptionModel sub;
  final VoidCallback onUpgrade;

  const SettingsHeader({
    super.key,
    required this.settings,
    required this.sub,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const limit = SubscriptionService.freeMonthlyLimit;
    final used = sub.monthlyDocCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              image: settings.hasLogo
                  ? DecorationImage(
                      image: MemoryImage(settings.logoBytes!),
                      fit: BoxFit.contain,
                    )
                  : null,
            ),
            child: settings.hasLogo
                ? null
                : Icon(Icons.storefront_outlined,
                    color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.namaToko.isNotEmpty ? settings.namaToko : 'Faktura',
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sub.isPro
                      ? tr('settings.plan_pro')
                      : tr('settings.plan_free')
                          .replaceAll('{n}', '$used')
                          .replaceAll('{max}', '$limit'),
                  style: theme.textTheme.bodySmall,
                ),
                if (!sub.isPro) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    // The count can pass the limit; the bar just stays full.
                    value: used >= limit ? 1 : used / limit,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ],
              ],
            ),
          ),
          if (!sub.isPro)
            TextButton(
              onPressed: onUpgrade,
              // "Pro" alone says little to TalkBack.
              child: Text('Pro', semanticsLabel: tr('sub.unlock_all')),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Jalankan test**

Run: `/c/flutter/bin/flutter test test/pages/settings_header_test.dart`
Expected: 3 lulus.
Run: `/c/flutter/bin/flutter analyze 2>&1 | tail -1`
Expected: `9 issues found.`
Run: `/c/flutter/bin/flutter test 2>&1 | tail -1`
Expected: `+117: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/pages/settings_page.dart lib/services/locale_service.dart test/pages/settings_header_test.dart
git commit -m "feat: add settings header with quota bar"
```

---

### Task 4: Hub Pengaturan jadi daftar polos

**Files:**
- Modify: `lib/pages/settings_page.dart`
- Modify: `lib/services/locale_service.dart`

**Interfaces:**
- Consumes:
  - `SettingsHeader` (Task 3)
  - sub-halaman publik (Task 1)
  - `UpdaterService.currentAppVersion`, `updaterSupported`, `promptAppUpdate` (`updater_service.dart`)
  - `kDebugMode`
- Produces: tidak ada API baru. `SettingsPage` tetap `const SettingsPage({super.key})`.

- [ ] **Step 1: Kunci grup (sentence case)**

`lib/services/locale_service.dart`, baris 147-149. Old:

```dart
  'settings.general': ['UMUM', 'GENERAL'],
  'settings.documents': ['DOKUMEN', 'DOCUMENTS'],
  'settings.app': ['APLIKASI', 'APP'],
```

New:

```dart
  'settings.group_store': ['Toko', 'Store'],
  'settings.documents': ['Dokumen', 'Documents'],
  'settings.app': ['Aplikasi', 'App'],
```

`settings.general` hanya dipakai hub lama (sudah dicek dengan `grep`), jadi aman dihapus.

- [ ] **Step 2: Tulis ulang hub**

Di `lib/pages/settings_page.dart`, ganti **semua** isi dari baris 1 sampai `}` penutup `class _SettingsPageState`, yaitu tepat sebelum komentar `/// Top of Pengaturan` milik `SettingsHeader`. `SettingsHeader` di bawahnya tidak diubah. Isi baru:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import '../models/settings_model.dart';
import '../models/subscription_model.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/settings_service.dart';
import '../services/subscription_service.dart';
import '../services/theme_service.dart';
import '../services/updater_service.dart';
import '../widgets/paywall_sheet.dart';
import 'recurring_invoice_page.dart';
import 'settings/about_sub_page.dart';
import 'settings/backup_sub_page.dart';
import 'settings/bank_sub_page.dart';
import 'settings/contact_sub_page.dart';
import 'settings/invoice_settings_sub_page.dart';
import 'settings/profile_sub_page.dart';
import 'settings/qris_sub_page.dart';
import 'settings/sandbox_sub_page.dart';
import 'settings/signature_sub_page.dart';
import 'settings/struk_sub_page.dart';
import 'settings/template_sub_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsModel _settings = SettingsModel();
  SubscriptionModel _sub = SubscriptionModel();
  bool _isLoading = true;
  // Nothing for the first 300ms, then a loading text, so a fast load
  // never flashes a spinner.
  bool _showLoadingText = false;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _loadingTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _isLoading) setState(() => _showLoadingText = true);
    });
    _load();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await SettingsService.load();
    final sub = await SubscriptionService.load();
    _loadingTimer?.cancel();
    if (mounted) setState(() { _settings = s; _sub = sub; _isLoading = false; });
  }

  Future<void> _push(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _load(); // refresh after returning
  }

  // Free users get the paywall instead of a Pro page.
  void _pushPro(Widget page) {
    if (!_sub.isPro) {
      showPaywallSheet(context);
      return;
    }
    _push(page);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('settings.title'))),
        body: Center(
          child: _showLoadingText
              ? Text(tr('dashboard.loading'), style: theme.textTheme.bodySmall)
              : const SizedBox.shrink(),
        ),
      );
    }

    final notSet = tr('settings.not_set');
    final isSet = tr('settings.already_set');
    // Written label instead of the old orange badge.
    final pro = _sub.isPro ? null : 'Pro';

    return Scaffold(
      appBar: AppBar(title: Text(tr('settings.title'))),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          SettingsHeader(
            settings: _settings,
            sub: _sub,
            onUpgrade: () => showPaywallSheet(context).then((_) => _load()),
          ),
          _group(theme, tr('settings.group_store'), [
            _row(
              theme,
              tr('settings.store_profile'),
              _settings.namaToko.isNotEmpty ? _settings.namaToko : notSet,
              () => _push(ProfileSubPage(settings: _settings)),
            ),
            _row(
              theme,
              tr('settings.contact'),
              _settings.telepon.isNotEmpty ? _settings.telepon : notSet,
              () => _push(ContactSubPage(settings: _settings)),
            ),
            _row(
              theme,
              tr('settings.payment_info'),
              _settings.bankAccounts.isNotEmpty &&
                      _settings.bankAccounts.first.namaBank.isNotEmpty
                  ? '${_settings.bankAccounts.length} ${tr('settings.accounts')}'
                  : notSet,
              () => _push(BankSubPage(settings: _settings)),
            ),
            _row(
              theme,
              tr('settings.qris'),
              pro ?? (_settings.qrisMerchantId.isNotEmpty ? isSet : notSet),
              () => _pushPro(QrisSubPage(settings: _settings)),
            ),
            _row(
              theme,
              tr('settings.signature'),
              _settings.hasSignature ? isSet : notSet,
              () => _push(SignatureSubPage(settings: _settings)),
            ),
          ]),
          _group(theme, tr('settings.documents'), [
            _row(
              theme,
              tr('template.title'),
              '${_settings.templateConfig.invoiceTemplate.label} · ${_settings.templateConfig.strukTemplate.label}',
              () => _push(TemplateSubPage(settings: _settings)),
            ),
            _row(
              theme,
              tr('settings.tax_doc'),
              'PPN ${_settings.taxRate}% · ${_settings.currency}',
              () => _push(InvoiceSettingsSubPage(settings: _settings)),
            ),
            _row(
              theme,
              tr('settings.receipt_settings'),
              _settings.footerStruk.isNotEmpty
                  ? _settings.footerStruk
                  : 'Default',
              () => _push(StrukSubPage(settings: _settings)),
            ),
            _row(theme, tr('recurring.title'), pro,
                () => _pushPro(const RecurringInvoicePage())),
          ]),
          _group(theme, tr('settings.app'), [
            _accountRow(theme),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeService.themeNotifier,
              builder: (_, mode, _) => _row(
                theme,
                tr('appearance.title'),
                switch (mode) {
                  ThemeMode.dark => tr('appearance.dark'),
                  ThemeMode.light => tr('appearance.light'),
                  ThemeMode.system => tr('appearance.system'),
                },
                () => _showThemePicker(theme),
              ),
            ),
            ValueListenableBuilder<AppLanguage>(
              valueListenable: LocaleService.languageNotifier,
              builder: (_, lang, _) => _row(theme, tr('settings.language'),
                  lang.label, () => _showLanguagePicker(theme)),
            ),
            _row(theme, tr('settings.backup'), null,
                () => _push(BackupSubPage())),
            if (kDebugMode)
              _row(theme, tr('sandbox.title'), null,
                  () => _push(const SandboxSubPage())),
            _row(theme, tr('about.title'), UpdaterService.currentAppVersion,
                () => _push(const AboutSubPage())),
            if (updaterSupported)
              _row(theme, tr('update.check'), null,
                  () => promptAppUpdate(context)),
          ]),
        ],
      ),
    );
  }

  Widget _group(ThemeData theme, String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 4),
          child: Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.bodySmall),
          ),
        ),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 20, endIndent: 20),
          rows[i],
        ],
      ],
    );
  }

  // Title on the left, current value on the right (mockup 05).
  Widget _row(
      ThemeData theme, String title, String? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
            if (value != null) ...[
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _accountRow(ThemeData theme) {
    final user = AuthService.currentUser;
    if (user != null) {
      return _row(
        theme,
        tr('auth.account'),
        user.email ?? user.displayName,
        () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(tr('auth.sign_out_confirm')),
              content: Text(tr('auth.sign_out_warn')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(tr('common.cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(tr('auth.sign_out')),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await AuthService.signOut();
            if (mounted) setState(() {});
          }
        },
      );
    }
    return _row(
      theme,
      tr('auth.sign_in'),
      tr('auth.not_signed_in'),
      () async {
        try {
          await AuthService.signInWithGoogle();
          if (mounted) setState(() {});
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${tr('auth.sign_in_failed')}: $e')),
            );
          }
        }
      },
    );
  }

  void _showLanguagePicker(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ValueListenableBuilder<AppLanguage>(
          valueListenable: LocaleService.languageNotifier,
          builder: (context, current, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(tr('settings.language'),
                          style: theme.textTheme.titleMedium),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...AppLanguage.values.map((lang) {
                    final isSelected = lang == current;
                    return ListTile(
                      leading: Text(
                        lang == AppLanguage.id ? '🇮🇩' : '🇬🇧',
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(
                        lang.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_rounded,
                              color: theme.colorScheme.primary, size: 20)
                          : null,
                      onTap: () {
                        LocaleService.setLanguage(lang);
                        Navigator.pop(context);
                        // Rebuild settings page
                        setState(() {});
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showThemePicker(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.themeNotifier,
          builder: (context, current, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(tr('appearance.title'),
                          style: theme.textTheme.titleMedium),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _themeOption(
                    context,
                    icon: Icons.light_mode_outlined,
                    label: tr('appearance.light'),
                    mode: ThemeMode.light,
                    current: current,
                  ),
                  _themeOption(
                    context,
                    icon: Icons.dark_mode_outlined,
                    label: tr('appearance.dark'),
                    mode: ThemeMode.dark,
                    current: current,
                  ),
                  _themeOption(
                    context,
                    icon: Icons.contrast_outlined,
                    label: tr('appearance.system'),
                    mode: ThemeMode.system,
                    current: current,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _themeOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required ThemeMode mode,
    required ThemeMode current,
  }) {
    final theme = Theme.of(context);
    final isSelected = mode == current;
    return ListTile(
      leading: Icon(icon,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: theme.colorScheme.primary, size: 20)
          : null,
      onTap: () {
        ThemeService.setMode(mode);
        Navigator.pop(context);
      },
    );
  }
}
```

Dibanding hub lama:
- Hilang: `_buildProfileHeader`, `_proBadge`, `_buildSubscriptionCard`, `_buildThemeTile`, `_buildLanguageTile`, `_sectionLabel`, `_menuTile`, dan import `google_fonts`.
- Tap baris tetap membuka halaman yang sama dengan gerbang Pro yang sama.
- Pemilih bahasa dan tema berperilaku sama. Yang berubah hanya gaya teks.

- [ ] **Step 3: Verifikasi**

Run: `cd /c/Work/faktur_gen && grep -cE "GoogleFonts|withValues\(alpha: 0\.[2-5]|FFFFA000|settings\.backup_subtitle|sandbox\.subtitle" lib/pages/settings_page.dart`
Expected: `0`.
Run: `grep -n "kDebugMode" lib/pages/settings_page.dart`
Expected: import + satu `if (kDebugMode)` di baris Sandbox.
Run: `/c/flutter/bin/flutter analyze 2>&1 | tail -1`
Expected: `9 issues found.`
Run: `/c/flutter/bin/flutter test 2>&1 | tail -1`
Expected: `+117: All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add lib/pages/settings_page.dart lib/services/locale_service.dart
git commit -m "feat: settings as plain grouped list"
```

---

### Task 5: Kunci terjemahan yang hilang + test pemindai kunci

Backup dan Sandbox memanggil kunci yang tidak ada, jadi pengguna melihat teks seperti `settings.export_backup_desc`. Kunci yang benar sudah ada dengan nama lain (dicek di `locale_service.dart:189-197, 229-248, 373-374`).

**Files:**
- Test: `test/services/tr_keys_test.dart`
- Modify: `lib/pages/settings/backup_sub_page.dart`, `lib/pages/settings/sandbox_sub_page.dart`, `lib/services/locale_service.dart`

**Interfaces:**
- Produces: kunci `settings.import`.

- [ ] **Step 1: Tulis test yang gagal**

`test/services/tr_keys_test.dart`:

```dart
import 'dart:io';

import 'package:faktur_gen/services/locale_service.dart';
import 'package:flutter_test/flutter_test.dart';

// tr() falls back to the raw key, so a typo shows "settings.foo" to the user.
// Scans the files owned by the stage 3c plan.
const _paths = [
  'lib/pages/settings_page.dart',
  'lib/pages/settings',
  'lib/pages/main_navigation.dart',
  'lib/pages/onboarding_page.dart',
  'lib/pages/splash_page.dart',
  'lib/pages/login_page.dart',
  'lib/pages/recurring_invoice_page.dart',
  'lib/widgets/paywall_sheet.dart',
];

void main() {
  test('every tr() key used in these files exists', () {
    final files = [
      for (final p in _paths)
        if (FileSystemEntity.isDirectorySync(p))
          ...Directory(p).listSync().whereType<File>()
        else
          File(p),
    ];
    final call = RegExp(r"trN?\('([a-z_.0-9]+)'");
    final missing = {
      for (final f in files)
        for (final m in call.allMatches(f.readAsStringSync()))
          if (tr(m.group(1)!) == m.group(1)) m.group(1)!,
    };
    expect(missing, isEmpty);
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `/c/flutter/bin/flutter test test/services/tr_keys_test.dart`
Expected: FAIL, `missing` berisi 18 kunci `settings.*`/`sandbox.*` di Backup dan Sandbox (misalnya `settings.export_backup_desc`, `sandbox.test_notif_sent`).

- [ ] **Step 3: Arahkan ke kunci yang ada**

```bash
cd /c/Work/faktur_gen
sed -i \
  -e "s/'settings\.export_backup_desc'/'settings.export_backup_sub'/" \
  -e "s/'settings\.import_backup_desc'/'settings.import_backup_sub'/" \
  -e "s/'settings\.import_confirm_desc'/'settings.import_warn'/" \
  -e "s/'settings\.invalid_backup'/'settings.import_invalid'/" \
  -e "s/'settings\.export_failed'/'common.export_fail'/" \
  -e "s/'settings\.import_failed'/'common.import_fail'/" \
  lib/pages/settings/backup_sub_page.dart
sed -i \
  -e "s/'sandbox\.scheduled_notif'/'sandbox.scheduled_notifs'/" \
  -e "s/'sandbox\.auto_backup_note'/'sandbox.backup_note'/" \
  -e "s/'sandbox\.test_notif_desc'/'sandbox.test_notif_sub'/" \
  -e "s/'sandbox\.test_notif_sent'/'sandbox.test_sent'/" \
  -e "s/'sandbox\.reschedule_all_desc'/'sandbox.reschedule_sub'/" \
  -e "s/'sandbox\.reschedule_done'/'sandbox.rescheduled'/" \
  -e "s/'sandbox\.cancel_all_desc'/'sandbox.cancel_sub'/" \
  -e "s/'sandbox\.cancel_all_confirm_desc'/'sandbox.cancel_warn'/" \
  -e "s/'sandbox\.cancel_all_confirm'/'sandbox.cancel_confirm'/" \
  -e "s/'sandbox\.yes_delete'/'sandbox.cancel_yes'/" \
  -e "s/'sandbox\.all_cancelled'/'sandbox.cancelled'/" \
  lib/pages/settings/sandbox_sub_page.dart
```

Pola memakai tanda kutip penutup, jadi `'sandbox.cancel_all_confirm'` tidak ikut mengenai `'sandbox.cancel_all_confirm_desc'`.

`lib/services/locale_service.dart`, sebelum `};`:

```dart
  'settings.import': ['Import', 'Import'],
```

- [ ] **Step 4: Jalankan test**

Run: `/c/flutter/bin/flutter test test/services/tr_keys_test.dart`
Expected: lulus.
Run: `/c/flutter/bin/flutter analyze 2>&1 | tail -1`
Expected: `9 issues found.`
Run: `/c/flutter/bin/flutter test 2>&1 | tail -1`
Expected: `+118: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add test/services/tr_keys_test.dart lib/pages/settings lib/services/locale_service.dart
git commit -m "fix: missing translation keys in backup and sandbox"
```

---

### Task 6: Invoice berulang di sheet "Buat"

**Files:**
- Modify: `lib/pages/main_navigation.dart`

**Interfaces:**
- Consumes:
  - `RecurringInvoicePage` (`recurring_invoice_page.dart`)
  - `SubscriptionService.load()` → `SubscriptionModel.isPro`
  - `showPaywallSheet` (`widgets/paywall_sheet.dart`)
  - `_openCreatePage` (`main_navigation.dart:131`)
- Produces: tidak ada API baru.

- [ ] **Step 1: Import**

`lib/pages/main_navigation.dart`:
- Setelah `import '../services/reminder_service.dart';` tambah `import '../services/subscription_service.dart';`.
- Setelah `import '../services/updater_service.dart';` tambah `import '../widgets/paywall_sheet.dart';`.
- Setelah `import 'history_page.dart';` tambah `import 'recurring_invoice_page.dart';`.

- [ ] **Step 2: Gerbang Pro**

Tambahkan method ini tepat setelah `_openCreatePage` (baris 131-136):

```dart
  // Same Pro gate as the row in Pengaturan.
  Future<void> _openRecurring() async {
    final sub = await SubscriptionService.load();
    if (!mounted) return;
    if (!sub.isPro) {
      showPaywallSheet(context);
      return;
    }
    _openCreatePage(const RecurringInvoicePage());
  }
```

- [ ] **Step 3: Baris di sheet**

Di `_showCreateSheet`, old (akhir `Row` dua pilihan, baris 196-199):

```dart
                ],
              ),
              const SizedBox(height: 8),
            ],
```

New:

```dart
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.repeat_rounded),
                title: Text(tr('recurring.title')),
                subtitle: Text(tr('recurring.subtitle')),
                onTap: () {
                  Navigator.pop(context);
                  _openRecurring();
                },
              ),
              const SizedBox(height: 8),
            ],
```

Baris Invoice berulang di Pengaturan tetap ada (Task 4).

- [ ] **Step 4: Verifikasi**

Run: `/c/flutter/bin/flutter analyze 2>&1 | tail -1`
Expected: `9 issues found.`
Run: `/c/flutter/bin/flutter test 2>&1 | tail -1`
Expected: `+118: All tests passed!` (`tr_keys_test` juga memindai `main_navigation.dart`).

- [ ] **Step 5: Commit**

```bash
git add lib/pages/main_navigation.dart
git commit -m "feat: recurring invoice in create sheet"
```

---

### Task 7: Onboarding ikut sistem desain

Tata letak tidak berubah. Yang diubah:
- semua teks lewat `tr()`
- gaya lewat `textTheme`
- tombol kembali 22px jadi `IconButton` 48dp dengan tooltip
- animasi halaman menghormati `disableAnimations`

**Files:**
- Modify: `lib/pages/onboarding_page.dart`
- Modify: `lib/services/locale_service.dart`

**Interfaces:**
- Consumes: `tr`, `settings.gallery`, `settings.camera`, `common.delete` (sudah ada).
- Produces: kunci `onboarding.*`.

- [ ] **Step 1: Kunci baru**

`lib/services/locale_service.dart`, sebelum `};`:

```dart
  'onboarding.skip': ['Lewati', 'Skip'],
  'onboarding.back': ['Kembali', 'Back'],
  'onboarding.next': ['Lanjut', 'Next'],
  'onboarding.start': ['Mulai Sekarang', 'Get started'],
  'onboarding.name_required': ['Nama toko wajib diisi', 'Store name is required'],
  'onboarding.profile_title': ['Atur Profil Toko', 'Set up your store'],
  'onboarding.profile_sub': ['Informasi ini akan muncul di invoice dan struk', 'This appears on your invoices and receipts'],
  'onboarding.name_label': ['Nama Toko / Perusahaan *', 'Store / Company Name *'],
  'onboarding.address_label': ['Alamat (opsional)', 'Address (optional)'],
  'onboarding.phone_label': ['No. Telepon (opsional)', 'Phone (optional)'],
  'onboarding.logo_title': ['Tambahkan Logo', 'Add a logo'],
  'onboarding.logo_sub': ['Logo akan tampil di header dokumen\nBisa ditambahkan nanti di Pengaturan', 'Your logo appears in the document header\nYou can add it later in Settings'],
  'onboarding.pick_logo': ['Pilih Logo', 'Choose logo'],
  'onboarding.done_title': ['Siap Digunakan!', 'All set!'],
  'onboarding.done_sub': ['Kamu bisa langsung buat invoice atau struk.\nSemua pengaturan bisa diubah nanti.', 'You can create an invoice or receipt right away.\nYou can change any setting later.'],
  'onboarding.your_store': ['Toko Anda', 'Your store'],
```

- [ ] **Step 2: Import dan navigasi halaman**

- Ganti `import 'package:google_fonts/google_fonts.dart';` dengan `import '../services/locale_service.dart';` (urutkan setelah `../models/settings_model.dart`).
- Ganti `_next` dan `_back` (baris 56-74) dengan:

```dart
  void _next() {
    if (_currentPage == 0 && _namaCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('onboarding.name_required'))),
      );
      return;
    }
    _goTo(_currentPage + 1);
  }

  void _back() => _goTo(_currentPage - 1);

  // animateToPage asserts a non-zero duration, so jump when animations are off.
  void _goTo(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageCtrl.jumpToPage(page);
      return;
    }
    _pageCtrl.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
```

- [ ] **Step 3: Teks dan gaya**

Ganti per pasangan (old → new):

1. Sheet logo:
   - `title: const Text('Galeri Foto'),` → `title: Text(tr('settings.gallery')),`
   - `title: const Text('Kamera'),` → `title: Text(tr('settings.camera')),`
2. Tombol Lewati. Old:

```dart
                  child: Text(
                    'Lewati',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.45),
                    ),
                  ),
```

   New (warna tautan bawaan `TextButton` = primary):

```dart
                  child: Text(tr('onboarding.skip')),
```

3. Tombol bawah. Old:

```dart
                      : Text(
                          _currentPage == 2 ? 'Mulai Sekarang' : 'Lanjut',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
```

   New:

```dart
                      : Text(_currentPage == 2
                          ? tr('onboarding.start')
                          : tr('onboarding.next')),
```

4. Indikator. Old:

```dart
          if (_currentPage > 0)
            GestureDetector(
              onTap: _back,
              child: Icon(Icons.arrow_back_rounded,
                  size: 22,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            )
          else
            const SizedBox(width: 22),
```

   New:

```dart
          if (_currentPage > 0)
            IconButton(
              onPressed: _back,
              tooltip: tr('onboarding.back'),
              icon: const Icon(Icons.arrow_back_rounded),
            )
          else
            const SizedBox(width: 48),
```

   Lalu old:

```dart
          const Spacer(),
          const SizedBox(width: 22),
```

   New:

```dart
          const Spacer(),
          const SizedBox(width: 48),
```

   Dan pada `AnimatedContainer` titik. Old: `duration: const Duration(milliseconds: 250),`. New:

```dart
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
```

5. Tiga judul langkah: `'Atur Profil Toko'`, `'Tambahkan Logo'`, `'Siap Digunakan!'`. Masing-masing jadi `tr('onboarding.profile_title')`, `tr('onboarding.logo_title')`, `tr('onboarding.done_title')`. Blok gayanya:

```dart
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
```

   (indentasi beda per langkah) jadi `style: theme.textTheme.headlineSmall,`.
6. Tiga subjudul: `'Informasi ini akan muncul di invoice dan struk'`, `'Logo akan tampil di header dokumen\nBisa ditambahkan nanti di Pengaturan'`, `'Kamu bisa langsung buat invoice atau struk.\nSemua pengaturan bisa diubah nanti.'`. Masing-masing jadi `tr('onboarding.profile_sub')`, `tr('onboarding.logo_sub')`, `tr('onboarding.done_sub')`. Blok `GoogleFonts.inter(fontSize: 14, color: ...withValues(alpha: 0.5)[, height: 1.5])` jadi `theme.textTheme.bodySmall`.
7. Label field. `const InputDecoration(...)` jadi `InputDecoration(...)`, dengan `prefixIcon: const Icon(...)`:
   - `labelText: 'Nama Toko / Perusahaan *',` → `labelText: tr('onboarding.name_label'),`
   - `labelText: 'Alamat (opsional)',` → `labelText: tr('onboarding.address_label'),`
   - `labelText: 'No. Telepon (opsional)',` → `labelText: tr('onboarding.phone_label'),`
8. Pilih logo. Old:

```dart
                        Text(
                          'Pilih Logo',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
```

   New:

```dart
                        Text(tr('onboarding.pick_logo'),
                            style: theme.textTheme.bodySmall),
```

9. `label: const Text('Hapus'),` → `label: Text(tr('common.delete')),`
10. Kartu pratinjau. Old:

```dart
                      Text(
                        _namaCtrl.text.isNotEmpty
                            ? _namaCtrl.text
                            : 'Toko Anda',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
```

    New:

```dart
                      Text(
                        _namaCtrl.text.isNotEmpty
                            ? _namaCtrl.text
                            : tr('onboarding.your_store'),
                        style: theme.textTheme.titleSmall,
                      ),
```

    Lalu alamat. Old:

```dart
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
```

    New: `style: theme.textTheme.bodySmall,`

- [ ] **Step 4: Verifikasi**

Run: `cd /c/Work/faktur_gen && grep -nE "GoogleFonts|Text\(\s*'[A-Z]|labelText: '|title: const Text\('" lib/pages/onboarding_page.dart`
Expected: tidak ada output.
Run: `/c/flutter/bin/flutter analyze 2>&1 | tail -1`
Expected: `9 issues found.`
Run: `/c/flutter/bin/flutter test 2>&1 | tail -1`
Expected: `+118: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/pages/onboarding_page.dart lib/services/locale_service.dart
git commit -m "feat: translate onboarding and use text theme"
```

---

### Task 8: Splash dan login ikut sistem desain

**Files:**
- Modify: `lib/pages/splash_page.dart`, `lib/pages/login_page.dart`
- Modify: `lib/services/locale_service.dart`

**Interfaces:**
- Consumes: `tr`, `about.subtitle` (teks yang sama dengan tagline splash, sudah ada).
- Produces: kunci `splash.tip_1` … `splash.tip_10`.

- [ ] **Step 1: Kunci tips**

`lib/services/locale_service.dart`, sebelum `};`:

```dart
  'splash.tip_1': ['Atur profil toko di Pengaturan untuk invoice lebih profesional', 'Set up your store profile in Settings for more professional invoices'],
  'splash.tip_2': ['Tambahkan logo dan tanda tangan untuk branding yang konsisten', 'Add a logo and signature for consistent branding'],
  'splash.tip_3': ['Gunakan template untuk mempercepat pembuatan invoice berulang', 'Use templates to create repeat invoices faster'],
  'splash.tip_4': ['Atur pengingat layanan agar tidak terlewat jadwal pelanggan', 'Set service reminders so you never miss a customer appointment'],
  'splash.tip_5': ['Export data ke CSV untuk pembukuan yang lebih rapi', 'Export data to CSV for tidier bookkeeping'],
  'splash.tip_6': ['Simpan kontak pelanggan untuk auto-fill di invoice berikutnya', 'Save customer contacts to auto-fill your next invoice'],
  'splash.tip_7': ['Gunakan katalog item untuk menambahkan produk dengan cepat', 'Use the item catalog to add products quickly'],
  'splash.tip_8': ['Backup data secara berkala untuk keamanan dokumen Anda', 'Back up your data regularly to keep your documents safe'],
  'splash.tip_9': ['Struk bisa langsung dicetak ke printer thermal 80mm', 'Receipts can be printed straight to an 80mm thermal printer'],
  'splash.tip_10': ['Aktifkan dark mode untuk kenyamanan mata di malam hari', 'Turn on dark mode to rest your eyes at night'],
```

- [ ] **Step 2: Splash**

`lib/pages/splash_page.dart`:

1. Ganti `import 'package:google_fonts/google_fonts.dart';` dengan `import '../services/locale_service.dart';` (setelah `../services/auth_service.dart`).
2. `SplashWrapper.build`. Old: `duration: const Duration(milliseconds: 400),`. New:

```dart
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 400),
```

3. Ganti isi `_tips` (baris 118-129) dengan kunci. Teks dibaca saat `build`, jadi mengikuti bahasa aktif:

```dart
  static const _tips = [
    'splash.tip_1',
    'splash.tip_2',
    'splash.tip_3',
    'splash.tip_4',
    'splash.tip_5',
    'splash.tip_6',
    'splash.tip_7',
    'splash.tip_8',
    'splash.tip_9',
    'splash.tip_10',
  ];
```

4. Di `_SplashContentState.build`, ganti:

```dart
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
```

   dengan:

```dart
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Reduced motion: show the end state right away.
    final still = MediaQuery.disableAnimationsOf(context);
    double v(Animation<double> a) => still ? 1 : a.value;
```

   Lalu ganti `_logoOpacity.value`, `_logoScale.value`, `_textOpacity.value` (dua kali), `_tipOpacity.value` dengan `v(_logoOpacity)`, `v(_logoScale)`, `v(_textOpacity)`, `v(_tipOpacity)`. Nilai akhir keempat animasi itu 1.0 (baris 143-162).
5. `'Faktura'`. Old:

```dart
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
```

   New: `style: theme.textTheme.displaySmall,`
6. Tagline. Old:

```dart
                  child: Text(
                    'Invoice & Struk Profesional',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.45),
                    ),
                  ),
```

   New:

```dart
                  child: Text(
                    tr('about.subtitle'),
                    style: theme.textTheme.bodySmall,
                  ),
```

7. Teks tips. Abu 0.6 di atas latar biru tipis tidak terjamin AA, jadi pakai warna teks utama. Old:

```dart
                          child: Text(
                            _tip,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              height: 1.5,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
```

   New:

```dart
                          child: Text(
                            tr(_tip),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onSurface),
                          ),
```

- [ ] **Step 3: Login**

`lib/pages/login_page.dart`:

1. Hapus `import 'package:google_fonts/google_fonts.dart';`.
2. `'Faktura'`. Old:

```dart
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
```

   New: `style: theme.textTheme.displaySmall,`
3. Subjudul. Old:

```dart
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    height: 1.5,
                  ),
```

   New: `style: theme.textTheme.bodySmall,`
4. Label tombol Google. Old:

```dart
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
```

   New: hapus argumen `style:` itu. `OutlinedButton` sudah memakai `labelLarge` 15/600.
5. Lewati. Old:

```dart
                  child: Text(
                    tr('auth.skip'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
```

   New (tautan memakai warna aksen bawaan `TextButton`):

```dart
                  child: Text(tr('auth.skip')),
```

- [ ] **Step 4: Verifikasi**

Run: `cd /c/Work/faktur_gen && grep -nE "GoogleFonts|withValues\(alpha: 0\.(45|5|6)\)" lib/pages/splash_page.dart lib/pages/login_page.dart`
Expected: tidak ada output.
Run: `/c/flutter/bin/flutter analyze 2>&1 | tail -1`
Expected: `9 issues found.`
Run: `/c/flutter/bin/flutter test 2>&1 | tail -1`
Expected: `+118: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/pages/splash_page.dart lib/pages/login_page.dart lib/services/locale_service.dart
git commit -m "fix: splash and login follow text theme"
```

---

### Task 9: Halaman invoice berulang ikut sistem desain

**Files:**
- Modify: `lib/pages/recurring_invoice_page.dart`
- Modify: `lib/services/locale_service.dart`

**Interfaces:**
- Consumes:
  - `StatusLabel` (`widgets/status_label.dart`)
  - `AppColors.errorFor/successFor`
  - `trN('invoice.item_count', n)` (sudah ada)
- Produces: kunci `recurring.pick_contact`.

- [ ] **Step 1: Kunci baru**

`lib/services/locale_service.dart`, sebelum `};`:

```dart
  'recurring.pick_contact': ['Pilih kontak', 'Choose contact'],
```

- [ ] **Step 2: Import**

Ganti `import 'package:google_fonts/google_fonts.dart';` dengan `import '../main.dart';`. Setelah `import '../services/settings_service.dart';` tambah `import '../widgets/status_label.dart';`.

- [ ] **Step 3: Daftar**

1. Dialog hapus. Old:

```dart
            child: Text(tr('common.delete'),
              style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
```

   New:

```dart
            child: Text(tr('common.delete'),
              style: TextStyle(
                  color: AppColors.errorFor(Theme.of(ctx).brightness)))),
        ],
      ),
    );
```

2. Tombol tambah di AppBar. Old:

```dart
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _add,
          ),
```

   New:

```dart
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: tr('recurring.add_title'),
            onPressed: _add,
          ),
```

3. Kondisi kosong. Old:

```dart
                      Text(tr('recurring.empty'),
                        style: GoogleFonts.inter(fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                      const SizedBox(height: 4),
                      Text(tr('recurring.empty_sub'),
                        style: GoogleFonts.inter(fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.35))),
```

   New:

```dart
                      Text(tr('recurring.empty'),
                        style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 4),
                      Text(tr('recurring.empty_sub'),
                        style: theme.textTheme.bodySmall),
```

4. Kartu jadi baris polos. Old:

```dart
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _buildCard(theme, _items[i]),
                ),
```

   New:

```dart
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _row(theme, _items[i]),
                ),
```

   Ganti seluruh method `_buildCard` (baris 120-181) dengan:

```dart
  Widget _row(ThemeData theme, RecurringInvoiceModel item) {
    final dateFormat =
        DateFormat('dd MMM yyyy', LocaleService.isEn ? 'en_US' : 'id_ID');
    final total = RecurringInvoiceService.calculateTotal(item);

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.contactName,
                    style: theme.textTheme.titleSmall),
              ),
              const SizedBox(width: 12),
              StatusLabel(
                text: item.isActive
                    ? tr('recurring.active')
                    : tr('recurring.paused'),
                color: item.isActive
                    ? AppColors.successFor(theme.brightness)
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${item.interval.label} · ${tr('recurring.next')}: ${dateFormat.format(item.nextDate)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${trN('invoice.item_count', item.items.length)} · Rp ${total.toStringAsFixed(0)}',
            style: theme.textTheme.bodySmall,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _toggleActive(item),
                child: Text(item.isActive
                    ? tr('recurring.pause')
                    : tr('recurring.activate')),
              ),
              TextButton(
                onPressed: () => _edit(item),
                child: Text(tr('common.edit')),
              ),
              TextButton(
                onPressed: () => _delete(item),
                child: Text(tr('common.delete'),
                    style: TextStyle(
                        color: AppColors.errorFor(theme.brightness))),
              ),
            ],
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 4: Form**

1. Tombol kontak. Old:

```dart
                  IconButton(
                    icon: const Icon(Icons.contacts_outlined),
                    onPressed: _pickContact,
                  ),
```

   New:

```dart
                  IconButton(
                    icon: const Icon(Icons.contacts_outlined),
                    tooltip: tr('recurring.pick_contact'),
                    onPressed: _pickContact,
                  ),
```

2. Dropdown interval. `value` sudah deprecated, dan field ini menyimpan pilihannya sendiri lewat `onChanged`. Old: `              value: _interval,`. New: `              initialValue: _interval,`. Ini menghapus issue analyze baseline di baris 349.
3. Tanggal berikutnya. Old: `subtitle: Text(DateFormat('dd MMM yyyy').format(_nextDate)),`. New:

```dart
              subtitle: Text(DateFormat('dd MMM yyyy',
                      LocaleService.isEn ? 'en_US' : 'id_ID')
                  .format(_nextDate)),
```

4. Judul item. Old:

```dart
            Text(tr('recurring.items'),
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
```

   New:

```dart
            Text(tr('recurring.items'), style: theme.textTheme.titleSmall),
```

5. Tombol simpan. Old:

```dart
                    : Text(isEdit ? tr('recurring.save_edit') : tr('recurring.save'),
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
```

   New:

```dart
                    : Text(isEdit ? tr('recurring.save_edit') : tr('recurring.save')),
```

6. Hapus baris item. Old:

```dart
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _items.removeAt(index)),
            ),
```

   New:

```dart
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: tr('common.delete'),
              onPressed: () => setState(() => _items.removeAt(index)),
            ),
```

- [ ] **Step 5: Verifikasi**

Run: `cd /c/Work/faktur_gen && grep -nE "GoogleFonts|Colors\.(red|green|grey)|withValues\(alpha: 0\.(35|5)\)" lib/pages/recurring_invoice_page.dart`
Expected: tidak ada output.
Run: `/c/flutter/bin/flutter analyze 2>&1 | tail -1`
Expected: `8 issues found.` Issue `recurring_invoice_page.dart:349` hilang.
Run: `/c/flutter/bin/flutter test 2>&1 | tail -1`
Expected: `+118: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/pages/recurring_invoice_page.dart lib/services/locale_service.dart
git commit -m "fix: recurring invoices as plain rows with status label"
```

---

### Task 10: Paywall ikut aksen merek, tombol debug hanya di debug

**Files:**
- Modify: `lib/widgets/paywall_sheet.dart`

**Interfaces:**
- Consumes: `kDebugMode`, `colorScheme.primary/onPrimary/onSurfaceVariant`.
- Produces: tidak ada API baru. `showPaywallSheet(BuildContext)` tetap sama.

- [ ] **Step 1: Import**

Ganti `import 'package:google_fonts/google_fonts.dart';` dengan `import 'package:flutter/foundation.dart' show kDebugMode;` (letakkan sebelum `package:flutter/material.dart`).

- [ ] **Step 2: Lint `use_build_context_synchronously` (3 issue baseline)**

Parameter `context` di `_showRedeemDialog` menutupi `State.context`, jadi cek `mounted` dianggap tidak terkait. Pemanggilnya memberi `context` milik State yang sama, jadi perilakunya tidak berubah.

- Old: `  void _showRedeemDialog(BuildContext context) {`. New: `  void _showRedeemDialog() {`
- Old: `              onPressed: _isLoading ? null : () => _showRedeemDialog(context),`. New: `              onPressed: _isLoading ? null : _showRedeemDialog,`

- [ ] **Step 3: Warna dan teks**

1. Di `build`, hapus `    final isDark = theme.brightness == Brightness.dark;` (tidak dipakai lagi setelah langkah ini).
2. Ikon mahkota. Old:

```dart
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  size: 32, color: Color(0xFFFFA000)),
```

   New:

```dart
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.workspace_premium_rounded,
                  size: 32, color: theme.colorScheme.primary),
```

3. Judul. Old:

```dart
              style: GoogleFonts.inter(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
```

   New: `style: theme.textTheme.headlineSmall,`
4. Subjudul. Old:

```dart
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
```

   New: `style: theme.textTheme.bodySmall,`
5. Daftar fitur. Old:

```dart
                  Icon(f.$1, size: 20, color: const Color(0xFFFFA000)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(tr(f.$2),
                      style: GoogleFonts.inter(fontSize: 14,
                        color: theme.colorScheme.onSurface)),
                  ),
```

   New:

```dart
                  Icon(f.$1, size: 20,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tr(f.$2))),
```

6. Tombol langganan (satu tombol utama, aksen biru). Old:

```dart
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA000),
                  foregroundColor: const Color(0xFF111827),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
```

   New:

```dart
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
```

   Lalu old:

```dart
                    : Text(
                        '${tr('sub.subscribe')} — ${BillingService.priceString}',
                        style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600),
                      ),
```

   New:

```dart
                    : Text(
                        '${tr('sub.subscribe')} — ${BillingService.priceString}'),
```

7. Pulihkan dan Redeem jadi tautan (warna aksen bawaan `TextButton`). Old:

```dart
              child: Text(
                tr('sub.restore'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
```

   New: `child: Text(tr('sub.restore')),`

   Old:

```dart
              icon: Icon(Icons.card_giftcard_rounded, size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600]),
              label: Text(
                tr('sub.redeem'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
```

   New:

```dart
              icon: const Icon(Icons.card_giftcard_rounded, size: 16),
              label: Text(tr('sub.redeem')),
```

8. Tombol debug. Sekarang tampil di rilis dan memberi Pro gratis. Old:

```dart
            // Debug: activate Pro without payment (remove in production)
            TextButton(
              onPressed: _isLoading ? null : _debugActivate,
              child: Text(
                'Activate Pro (Debug)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ),
```

   New:

```dart
            // Free Pro without payment: debug builds only.
            if (kDebugMode)
              TextButton(
                onPressed: _isLoading ? null : _debugActivate,
                child: const Text('Activate Pro (Debug)'),
              ),
```

- [ ] **Step 4: Verifikasi**

Run: `cd /c/Work/faktur_gen && grep -nE "GoogleFonts|FFFFA000|FFFFC107|Colors\.grey|isDark" lib/widgets/paywall_sheet.dart`
Expected: tidak ada output.
Run: `/c/flutter/bin/flutter analyze 2>&1 | tail -6`
Expected: `5 issues found.` Sisanya tiga di `lib\pages\settings\sandbox_sub_page.dart` dan dua di file test.
Run: `/c/flutter/bin/flutter test 2>&1 | tail -1`
Expected: `+118: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/paywall_sheet.dart
git commit -m "fix: paywall uses brand accent, debug unlock in debug only"
```

---

## Cek manual (user, di HP/emulator)

Setelah semua task selesai:

1. **Pengaturan, akun gratis**
   - Header: logo atau ikon toko, nama toko, "Gratis · N dari 30 dokumen bulan ini", bar biru tipis sesuai jumlah, tautan "Pro" membuka paywall.
   - Setelah paywall ditutup, header dimuat ulang.
   - Grup "Toko", "Dokumen", "Aplikasi" ditulis sentence case.
   - Baris QRIS dan Invoice berulang menampilkan "Pro" di kanan, dan tap membuka paywall.
2. **Pengaturan, akun Pro**: tanpa bar dan tanpa tautan Pro. QRIS dan Invoice berulang membuka halamannya.
3. **Nilai di kanan** berubah setelah kembali dari sub-halaman (ubah nama toko, rekening, tanda tangan, PPN, footer struk, tema, bahasa).
4. **Sandbox**
   - Terlihat di `flutter run` (debug).
   - Tidak ada di build rilis (`flutter build apk --release`, pasang, buka Pengaturan).
   - Tombol "Activate Pro (Debug)" di paywall juga hilang di rilis.
5. **Sub-halaman**: buka satu per satu (Profil, Kontak, Rekening, QRIS, Tanda tangan, Template, Pajak, Struk, Backup, Tentang).
   - Simpan tetap jalan dan menampilkan snackbar "Disimpan".
   - Field wajib kosong menampilkan "Nama Toko / Perusahaan wajib diisi".
   - Teks Backup tidak lagi berupa kunci mentah.
6. **Sheet "Buat"**
   - Baris "Invoice berulang" ada.
   - Akun gratis melihat paywall.
   - Akun Pro membuka halaman Invoice berulang, lalu kembali ke tab yang sama.
7. **Invoice berulang**
   - Daftar polos dengan garis pemisah.
   - Status "Aktif" berupa titik + teks hijau, "Dijeda" abu.
   - Hapus berwarna merah tema.
8. **Onboarding** (hapus data app):
   - Tombol kembali bisa ditekan dengan mudah.
   - Teks Indonesia sama seperti sebelumnya.
   - Pilih logo dan Lewati tetap jalan.
9. **Splash dan login**
   - Tips terbaca jelas di mode terang dan gelap.
   - Ganti bahasa ke English, lalu buka ulang app: tips dan tagline berbahasa Inggris.
10. **Tampilan**
    - Mode terang dan gelap: ikon pensil logo, tombol Simpan, dan tombol Berlangganan terbaca.
    - Bahasa English di semua layar di atas.
    - Skala teks 200%: nilai di kanan baris Pengaturan terpotong dengan "…", tidak menimpa judul. Header tidak overflow.
11. **TalkBack**
    - Judul grup terbaca sebagai heading.
    - Tautan "Pro" terbaca "Buka semua fitur premium".
    - Tombol hapus (logo, tanda tangan, rekening, item invoice berulang), tambah, pilih kontak, dan kembali (onboarding) terbaca dengan label.
12. **Animasi dikurangi** (Developer options → Remove animations): splash langsung tampil penuh, dan pindah langkah onboarding tidak beranimasi dan tidak error.
