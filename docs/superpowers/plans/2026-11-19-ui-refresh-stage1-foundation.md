# UI Refresh Tahap 1 (Fondasi) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Perbaiki bug tombol "Selesai" di preview PDF, buat warna lulus WCAG AA di mode terang dan gelap, satukan tipografi dan komponen di `ThemeData`, dan ganti swipe antar tab dengan transisi fade pendek.

**Architecture:** Semua token desain tetap di `lib/main.dart` (`AppColors` + `MyApp.light()/dark()`), tidak ada file tema baru. Halaman tidak ditata ulang di tahap ini; hanya tombol yang memaksa teks putih diganti ke `colorScheme.onPrimary`. Navigasi tab memakai `AnimatedSwitcher` menggantikan `PageView`.

**Tech Stack:** Flutter (SDK di `C:\flutter`, tidak ada di PATH), Material 3, `google_fonts` (Inter), `flutter_test`.

Spec: `docs/superpowers/specs/2026-11-19-ui-refresh-design.md`

## Global Constraints

- Tidak ada package baru.
- Font tetap Inter; warna merek tetap biru #2563EB.
- Setiap pasangan teks/latar ≥ 4.5:1 (cek: `python "C:/Users/USER/.claude/skills/antislop-human/contrast-check.py" "#FG" "#BG"`).
- Area sentuh tombol ≥ 48dp.
- Komentar kode mengikuti gaya file (bahasa campur Indonesia/Inggris, singkat, menjelaskan alasan). Tanpa emoji, tanpa kode mati.
- Commit: subjek pendek konvensional, tanpa trailer `Co-Authored-By` dan tanpa menyebut AI.
- Perintah Flutter: `/c/flutter/bin/flutter` (Git Bash) atau `C:\flutter\bin\flutter` (PowerShell).
- Baseline sebelum tahap ini: `flutter analyze` = 9 issue lama (info/warning, tidak ada error); `flutter test` = 78 lulus. Akhir tahap: tidak ada issue analyze baru, semua test lulus.

## Keputusan yang menyimpang dari spec

- **Nama gaya teks:** spec menyebut 15/400 sebagai `bodyLarge` dan 13/400 sebagai `bodyMedium`. `Text` tanpa style memakai `bodyMedium`, jadi kalau `bodyMedium` diset 13 dan abu-abu, semua teks polos di app ikut mengecil dan memudar. Rencana ini memakai `bodyLarge` dan `bodyMedium` = 15/400 (warna utama), `bodySmall` = 13/400 (sekunder). Enam ukuran tetap sama: 32, 22, 17, 15, 13, 12.
- **Durasi transisi halaman:** `FadeForwardsPageTransitionsBuilder` memakai durasi tetap 450ms (`kTransitionMilliseconds`), bukan 300ms. Spec dikoreksi di Task 3.
- **Widget bersama** (`AppSection`, `AppField`, `StatusLabel`) tidak dibuat di tahap ini karena belum ada pemakai. Dibuat di tahap 2 bersama pemakai pertamanya.
- **Migrasi 188 panggilan `GoogleFonts.*()` di halaman** dilakukan per layar di tahap 2–5, saat layar itu ditata ulang.

## File Structure

| File | Perubahan |
|---|---|
| `lib/pages/pdf_preview_page.dart` | "Selesai" pop satu layar dan mengembalikan `true` |
| `lib/pages/faktur_page.dart` | tunggu hasil preview, tampilkan dialog pengingat, lalu tutup form; tombol generate pakai `onPrimary` |
| `lib/pages/struk_page.dart` | sama seperti faktur |
| `lib/main.dart` | `AppColors` kontras; `MyApp.light()/dark()` publik; tipografi, tombol, field, divider, transisi halaman; status bar ikut tema aktual |
| `lib/pages/onboarding_page.dart`, `recurring_invoice_page.dart`, `settings_page.dart`, `lib/widgets/signature_pad.dart`, `lib/widgets/paywall_sheet.dart` | ganti `foregroundColor: Colors.white` |
| `lib/pages/main_navigation.dart` | `AnimatedSwitcher` menggantikan `PageView`; `MainNavigation.goToTab()` |
| `lib/pages/dashboard_page.dart` | `_navigateToSettings` pakai `MainNavigation.goToTab` |
| `test/pages/pdf_preview_page_test.dart` | baru |
| `test/app_colors_test.dart` | warna baru + uji kontras |
| `test/theme_test.dart` | baru |
| `docs/superpowers/specs/2026-11-19-ui-refresh-design.md` | durasi transisi halaman 450ms |

---

### Task 1: Tombol "Selesai" di preview PDF hanya menutup satu layar

Bug (sudah direproduksi dengan widget test): `pdf_preview_page.dart:35-37` memanggil `pop()` dua kali. Dari form invoice/struk, form ikut tertutup sehingga `_showReminderDialog` tidak pernah jalan (`if (!mounted) return;`). Dari Riwayat (`history_page.dart:900,935`), pop kedua menutup halaman utama.

**Files:**
- Modify: `lib/pages/pdf_preview_page.dart:31-46`
- Modify: `lib/pages/faktur_page.dart:342-358`
- Modify: `lib/pages/struk_page.dart` (blok `await Navigator.push(` di `_generatePdf`, sekitar baris 359-378)
- Test: `test/pages/pdf_preview_page_test.dart`

**Interfaces:**
- Produces: `PdfPreviewPage` mengembalikan `true` lewat `Navigator.pop` saat "Selesai" ditekan; `null` saat tombol back sistem. Pemanggil memakai `Navigator.push<bool>`.

- [ ] **Step 1: Tulis test yang gagal**

Buat `test/pages/pdf_preview_page_test.dart`:

```dart
import 'dart:typed_data';

import 'package:faktur_gen/pages/pdf_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Selesai closes only the preview and returns true',
      (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => TextButton(
          onPressed: () async {
            result = await Navigator.push<bool>(
              ctx,
              MaterialPageRoute(
                builder: (_) => PdfPreviewPage(
                  title: 'Preview',
                  filename: 'test.pdf',
                  buildPdf: (_) async => Uint8List(0),
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Selesai'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('open'), findsOneWidget);
    expect(result, isTrue);
  });
}
```

(`pump` dengan durasi tetap, bukan `pumpAndSettle`: `PdfPreview` bisa terus menjadwalkan frame. Pola ini sudah diuji jalan di repo ini.)

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `/c/flutter/bin/flutter test test/pages/pdf_preview_page_test.dart`
Expected: FAIL pada `expect(find.text('open'), findsOneWidget)` (layar awal ikut ter-pop).

- [ ] **Step 3: Perbaiki `PdfPreviewPage`**

Di `lib/pages/pdf_preview_page.dart`, ganti `onPressed` tombol "Selesai" (hapus blok `Navigator.of(context)..pop()..pop();` beserta dua komentarnya):

```dart
          TextButton.icon(
            // Caller decides what to close next; popping twice here also
            // closed MainNavigation when opened from History.
            onPressed: () => Navigator.of(context).pop(true),
```

- [ ] **Step 4: Jalankan test, pastikan lulus**

Run: `/c/flutter/bin/flutter test test/pages/pdf_preview_page_test.dart`
Expected: PASS

- [ ] **Step 5: Sesuaikan pemanggil di form invoice**

Di `lib/pages/faktur_page.dart`, ganti blok dari `await Navigator.push(` sampai akhir method (`_showReminderDialog(faktur);` dan `}` penutup):

```dart
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewPage(
          title: 'Preview Invoice',
          filename: 'Invoice_${faktur.nomorFaktur.replaceAll('/', '-')}.pdf',
          buildPdf: (format) => PdfService.buildBytes(faktur, format,
              logoBytes: logoBytes,
              signatureBytes: signatureBytes,
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

- [ ] **Step 6: Sesuaikan pemanggil di form struk**

Di `lib/pages/struk_page.dart`, dalam `_generatePdf`, ubah `await Navigator.push(` menjadi `final done = await Navigator.push<bool>(` (argumen `PdfPreviewPage` tidak berubah), lalu ganti dua baris setelah penutup `);`:

```dart
    if (!mounted) return;
    await _showReminderDialog(struk);
    if (done == true && mounted) Navigator.pop(context);
  }
```

`history_page.dart` tidak diubah: pop tunggal sekarang kembali ke Riwayat.

- [ ] **Step 7: Analyze dan test**

Run: `/c/flutter/bin/flutter analyze && /c/flutter/bin/flutter test`
Expected: 9 issue (sama dengan baseline); 79 test lulus.

- [ ] **Step 8: Commit**

```bash
git add lib/pages/pdf_preview_page.dart lib/pages/faktur_page.dart lib/pages/struk_page.dart test/pages/pdf_preview_page_test.dart
git commit -m "fix: close only the PDF preview on Selesai" -m "Preview popped two routes: the form was gone before the reminder prompt could show, and from History it closed the main screen. Preview now returns true and the form closes itself after the prompt."
```

---

### Task 2: Warna lulus AA di terang dan gelap

**Files:**
- Modify: `lib/main.dart` (`AppColors` baris 81-115; `MyApp._light`/`_dark` jadi `light`/`dark`; `colorScheme`)
- Modify: `lib/pages/faktur_page.dart:1124`, `lib/pages/onboarding_page.dart:187`, `lib/pages/recurring_invoice_page.dart:400`, `lib/pages/settings_page.dart:727`, `lib/pages/struk_page.dart:1099`, `lib/widgets/signature_pad.dart:113`, `lib/widgets/paywall_sheet.dart:206`
- Test: `test/app_colors_test.dart`

**Interfaces:**
- Produces: `MyApp.light()` dan `MyApp.dark()` (public static, return `ThemeData`), dipakai Task 3 dan test. `AppColors.strukGreen` = `0xFF047857`, `error` = `0xFFB91C1C`, `warning` = `0xFFB45309`, `success` = `0xFF047857`. `colorScheme.onPrimary`: light `Colors.white`, dark `0xFF0F1117`.

- [ ] **Step 1: Tulis test yang gagal**

Ganti isi `test/app_colors_test.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:faktur_gen/main.dart';

// WCAG 2.x contrast ratio, same formula as antislop contrast-check.py.
double _contrast(Color a, Color b) {
  double lin(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double lum(Color c) => 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
  final la = lum(a), lb = lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

const _white = Color(0xFFFFFFFF);
const _darkBg = Color(0xFF0F1117);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppColors', () {
    test('brand colors are defined', () {
      expect(AppColors.invoiceBlue, const Color(0xFF2563EB));
      expect(AppColors.strukGreen, const Color(0xFF047857));
      expect(AppColors.invoiceBlueSoft, const Color(0xFF60A5FA));
      expect(AppColors.strukGreenSoft, const Color(0xFF34D399));
    });

    test('errorFor returns correct color per brightness', () {
      expect(AppColors.errorFor(Brightness.light), AppColors.error);
      expect(AppColors.errorFor(Brightness.dark), AppColors.errorSoft);
    });

    test('warningFor returns correct color per brightness', () {
      expect(AppColors.warningFor(Brightness.light), AppColors.warning);
      expect(AppColors.warningFor(Brightness.dark), AppColors.warningSoft);
    });

    test('successFor returns correct color per brightness', () {
      expect(AppColors.successFor(Brightness.light), AppColors.success);
      expect(AppColors.successFor(Brightness.dark), AppColors.successSoft);
    });

    test('soft colors are lighter than base colors', () {
      expect(
        HSLColor.fromColor(AppColors.errorSoft).lightness,
        greaterThan(HSLColor.fromColor(AppColors.error).lightness),
      );
      expect(
        HSLColor.fromColor(AppColors.warningSoft).lightness,
        greaterThan(HSLColor.fromColor(AppColors.warning).lightness),
      );
    });
  });

  group('WCAG AA contrast (4.5:1)', () {
    test('status text on light background', () {
      for (final c in [AppColors.error, AppColors.warning, AppColors.success]) {
        expect(_contrast(c, _white), greaterThanOrEqualTo(4.5), reason: '$c');
      }
    });

    test('status text on dark background', () {
      for (final c in [
        AppColors.errorSoft,
        AppColors.warningSoft,
        AppColors.successSoft,
      ]) {
        expect(_contrast(c, _darkBg), greaterThanOrEqualTo(4.5), reason: '$c');
      }
    });

    test('button label on primary, both themes and struk green', () {
      final light = MyApp.light().colorScheme;
      final dark = MyApp.dark().colorScheme;
      expect(_contrast(light.onPrimary, light.primary), greaterThanOrEqualTo(4.5));
      expect(_contrast(dark.onPrimary, dark.primary), greaterThanOrEqualTo(4.5));
      expect(_contrast(light.onPrimary, AppColors.strukGreen), greaterThanOrEqualTo(4.5));
      expect(_contrast(dark.onPrimary, AppColors.strukGreenSoft), greaterThanOrEqualTo(4.5));
    });
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `/c/flutter/bin/flutter test test/app_colors_test.dart`
Expected: FAIL kompilasi `The method 'light' isn't defined for the type 'MyApp'`.

- [ ] **Step 3: Ubah `AppColors`**

Di `lib/main.dart`, dalam `class AppColors`:

```dart
  // Brand colors
  static const invoiceBlue = Color(0xFF2563EB);
  // #059669 was 3.77:1 under white text; #047857 is 5.48:1.
  static const strukGreen = Color(0xFF047857);
```

```dart
  // Status colors (light mode), all >= 4.5:1 on white
  static const error = Color(0xFFB91C1C);
  static const warning = Color(0xFFB45309);
```

```dart
  // Success (for snackbar, badges)
  static const success = Color(0xFF047857);
```

(`invoiceBlueSoft`, `strukGreenSoft`, `errorSoft`, `warningSoft`, `successSoft` tidak berubah.)

- [ ] **Step 4: Jadikan tema publik dan set `onPrimary`**

Di `lib/main.dart`, ubah `theme: _light(),` → `theme: light(),` dan `darkTheme: _dark(),` → `darkTheme: dark(),`. Ubah deklarasi `static ThemeData _light()` → `static ThemeData light()` dan `static ThemeData _dark()` → `static ThemeData dark()`.

`colorScheme` milik `light()`:

```dart
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.light,
        primary: _primary,
        onPrimary: Colors.white,
        secondary: AppColors.strukGreen,
        surface: const Color(0xFFFAFBFC),
        onSurface: const Color(0xFF111827),
      ),
```

`colorScheme` milik `dark()`:

```dart
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.dark,
        primary: const Color(0xFF60A5FA),
        // White on #60A5FA is only 2.5:1.
        onPrimary: const Color(0xFF0F1117),
        secondary: const Color(0xFF34D399),
        surface: const Color(0xFF161822),
        onSurface: const Color(0xFFE5E7EB),
      ),
```

- [ ] **Step 5: Ganti teks putih paksa di tombol**

Di tiap lokasi berikut, baris `foregroundColor: Colors.white,` tepat di bawah `backgroundColor: theme.colorScheme.primary,` diganti dengan (indentasi mengikuti baris asal):

```dart
          foregroundColor: theme.colorScheme.onPrimary,
```

Lokasi: `faktur_page.dart:1124`, `onboarding_page.dart:187`, `recurring_invoice_page.dart:400`, `settings_page.dart:727`, `struk_page.dart:1099`, `signature_pad.dart:113`. Struk mengganti `primary` lewat `Theme` lokal di `struk_page.dart:472-481` tetapi mewarisi `onPrimary`: putih di #047857 = 5.48:1, #0F1117 di #34D399 = 9.82:1.

Di `lib/widgets/paywall_sheet.dart:206` (tombol amber `0xFFFFA000`; putih = 2.04:1, #111827 = 8.68:1):

```dart
                  foregroundColor: const Color(0xFF111827),
```

Lalu hapus warna putih eksplisit di dalam tujuh tombol itu (misalnya `color: Colors.white` pada `Text`/`Icon` anak tombol) supaya mewarisi `foregroundColor`. Cari dengan:

Run: `grep -rn -A14 "foregroundColor: theme.colorScheme.onPrimary\|foregroundColor: const Color(0xFF111827)" lib | grep "Colors.white"`
Expected setelah dibersihkan: tidak ada output.

- [ ] **Step 6: Jalankan test, pastikan lulus**

Run: `/c/flutter/bin/flutter test test/app_colors_test.dart`
Expected: PASS (8 test)

- [ ] **Step 7: Analyze dan test penuh**

Run: `/c/flutter/bin/flutter analyze && /c/flutter/bin/flutter test`
Expected: 9 issue (baseline); 82 test lulus.

- [ ] **Step 8: Commit**

```bash
git add lib/main.dart lib/pages lib/widgets test/app_colors_test.dart
git commit -m "fix: meet WCAG AA contrast for buttons and status" -m "Dark-mode buttons forced white text on #60A5FA (2.5:1) and #34D399 (1.9:1). Buttons now use colorScheme.onPrimary (#0F1117 in dark). Struk green, error, warning and success darkened to pass 4.5:1 on white. Paywall button text is dark on amber."
```

---

### Task 3: Tipografi, komponen, transisi halaman, status bar

**Files:**
- Modify: `lib/main.dart` (`MyApp.build`, `light()`, `dark()`, `_appBar`, `_input`, `_elevatedBtn`, `_textBtn`; tambah `_text`, `_pageTransitions`)
- Modify: `docs/superpowers/specs/2026-11-19-ui-refresh-design.md` (tabel gerak, baris "Buka halaman")
- Test: `test/theme_test.dart`

**Interfaces:**
- Consumes: `MyApp.light()`, `MyApp.dark()` dari Task 2.
- Produces: `textTheme` dengan `displaySmall` 32/w700, `headlineSmall` 22/w700, `titleLarge` 22/w700, `titleMedium` 17/w600, `titleSmall` 15/w600, `bodyLarge` 15/w400, `bodyMedium` 15/w400, `bodySmall` 13/w400 (warna sekunder), `labelLarge` 15/w600, `labelMedium` 12/w600, `labelSmall` 12/w500. Tahap 2–5 memakai nama-nama ini.

- [ ] **Step 1: Tulis test yang gagal**

Buat `test/theme_test.dart`:

```dart
import 'package:faktur_gen/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final entry in {'light': MyApp.light(), 'dark': MyApp.dark()}.entries) {
    final theme = entry.value;

    group('${entry.key} theme', () {
      test('text scale uses only 32/22/17/15/13/12', () {
        final t = theme.textTheme;
        expect(t.displaySmall!.fontSize, 32);
        expect(t.headlineSmall!.fontSize, 22);
        expect(t.titleLarge!.fontSize, 22);
        expect(t.titleMedium!.fontSize, 17);
        expect(t.titleSmall!.fontSize, 15);
        expect(t.bodyLarge!.fontSize, 15);
        expect(t.bodyMedium!.fontSize, 15);
        expect(t.bodySmall!.fontSize, 13);
        expect(t.labelLarge!.fontSize, 15);
        expect(t.labelMedium!.fontSize, 12);
        expect(t.labelSmall!.fontSize, 12);
      });

      test('buttons are at least 48dp tall', () {
        final elevated =
            theme.elevatedButtonTheme.style!.minimumSize!.resolve({})!;
        final text = theme.textButtonTheme.style!.minimumSize!.resolve({})!;
        expect(elevated.height, greaterThanOrEqualTo(48));
        expect(text.height, greaterThanOrEqualTo(48));
      });

      test('android pages use the built-in fade-forwards transition', () {
        expect(
          theme.pageTransitionsTheme.builders[TargetPlatform.android],
          isA<FadeForwardsPageTransitionsBuilder>(),
        );
      });
    });
  }

  test('light theme: white background, borderless filled fields', () {
    final theme = MyApp.light();
    expect(theme.scaffoldBackgroundColor, Colors.white);
    expect(theme.inputDecorationTheme.fillColor, const Color(0xFFF3F4F6));
    expect(theme.inputDecorationTheme.hintStyle!.color,
        const Color(0xFF4B5563));
    expect(
      (theme.inputDecorationTheme.enabledBorder as OutlineInputBorder)
          .borderSide,
      BorderSide.none,
    );
  });

  test('dark theme background', () {
    expect(MyApp.dark().scaffoldBackgroundColor, const Color(0xFF0F1117));
  });
}
```

- [ ] **Step 2: Jalankan, pastikan gagal**

Run: `/c/flutter/bin/flutter test test/theme_test.dart`
Expected: FAIL (mis. `displaySmall` 36 bukan 32, `minimumSize` null, builder bukan `FadeForwardsPageTransitionsBuilder`).

- [ ] **Step 3: Tambah `_text` dan `_pageTransitions`, pakai di kedua tema**

Di `lib/main.dart`, dalam `class MyApp`, tambahkan setelah `dark()`:

```dart
  // Six sizes only: 32 / 22 / 17 / 15 / 13 / 12. bodyMedium is the default
  // for plain Text, so it stays at body size and primary color.
  static TextTheme _text(TextTheme base, Color strong, Color muted) {
    final t = GoogleFonts.interTextTheme(base).apply(
      bodyColor: strong,
      displayColor: strong,
    );
    TextStyle s(TextStyle? x, double size, FontWeight w) =>
        x!.copyWith(fontSize: size, fontWeight: w, height: 1.3);
    return t.copyWith(
      displaySmall: s(t.displaySmall, 32, FontWeight.w700),
      headlineSmall: s(t.headlineSmall, 22, FontWeight.w700),
      titleLarge: s(t.titleLarge, 22, FontWeight.w700),
      titleMedium: s(t.titleMedium, 17, FontWeight.w600),
      titleSmall: s(t.titleSmall, 15, FontWeight.w600),
      bodyLarge: s(t.bodyLarge, 15, FontWeight.w400),
      bodyMedium: s(t.bodyMedium, 15, FontWeight.w400),
      bodySmall: s(t.bodySmall, 13, FontWeight.w400).copyWith(color: muted),
      labelLarge: s(t.labelLarge, 15, FontWeight.w600),
      labelMedium: s(t.labelMedium, 12, FontWeight.w600),
      labelSmall: s(t.labelSmall, 12, FontWeight.w500),
    );
  }

  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );
```

Di `light()`, ganti `final txt = GoogleFonts.interTextTheme(base.textTheme);` dengan:

```dart
    final txt = _text(
        base.textTheme, const Color(0xFF111827), const Color(0xFF6B7280));
```

Di `copyWith` milik `light()`: ubah `scaffoldBackgroundColor: const Color(0xFFF8F9FB),` menjadi `scaffoldBackgroundColor: Colors.white,`, tambahkan `pageTransitionsTheme: _pageTransitions,`, dan ganti `dividerTheme` lama (yang memakai `Colors.grey.shade200`) dengan:

```dart
      dividerTheme: const DividerThemeData(
        color: Color(0xFFF0F1F3),
        thickness: 1,
        space: 1,
      ),
```

Di `dark()`, ganti baris `txt` dengan:

```dart
    final txt = _text(
        base.textTheme, const Color(0xFFF3F4F6), const Color(0xFF9CA3AF));
```

Di `copyWith` milik `dark()`: tambahkan `pageTransitionsTheme: _pageTransitions,` dan ubah `dividerTheme` menjadi:

```dart
      dividerTheme: const DividerThemeData(
        color: Color(0xFF252836),
        thickness: 1,
        space: 1,
      ),
```

- [ ] **Step 4: AppBar, field, tombol**

Di `_appBar`, ganti baris `backgroundColor` dan `titleTextStyle`:

```dart
        backgroundColor: dark ? const Color(0xFF0F1117) : Colors.white,
```

```dart
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: dark ? Colors.white : const Color(0xFF111827),
        ),
```

Ganti seluruh `_input`:

```dart
  static InputDecorationTheme _input(bool dark) {
    final radius = BorderRadius.circular(12);
    final error = dark ? AppColors.errorSoft : AppColors.error;
    return InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF1F2233) : const Color(0xFFF3F4F6),
      border:
          OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      enabledBorder:
          OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: dark ? const Color(0xFF60A5FA) : _primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        color: dark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
      ),
      // #6B7280 on #F3F4F6 is 4.39:1, below AA.
      hintStyle: GoogleFonts.inter(
        fontSize: 15,
        color: dark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
      ),
      floatingLabelStyle: GoogleFonts.inter(
        fontSize: 13,
        color: dark ? const Color(0xFF60A5FA) : _primary,
      ),
    );
  }
```

Ganti `_elevatedBtn` dan `_textBtn`:

```dart
  static ElevatedButtonThemeData _elevatedBtn() => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle:
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );

  static TextButtonThemeData _textBtn() => TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle:
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );
```

- [ ] **Step 5: Status bar ikut tema aktual (juga mode "Ikuti sistem")**

Di `MyApp.build`, hapus:

```dart
        final isDark = themeMode == ThemeMode.dark;
        SystemChrome.setSystemUIOverlayStyle(
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        );
```

dan tambahkan argumen `builder` pada `MaterialApp` setelah `darkTheme: dark(),`:

```dart
          // Resolved brightness, so ThemeMode.system also gets the right icons.
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: Theme.of(context).brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: child!,
          ),
```

Import `package:flutter/services.dart` tetap dipakai (`SystemUiOverlayStyle`).

- [ ] **Step 6: Jalankan test, pastikan lulus**

Run: `/c/flutter/bin/flutter test test/theme_test.dart`
Expected: PASS (8 test)

- [ ] **Step 7: Koreksi spec**

Di `docs/superpowers/specs/2026-11-19-ui-refresh-design.md`, ganti baris tabel:

```
| Buka halaman | fade maju | 300ms | `FadeForwardsPageTransitionsBuilder` di `pageTransitionsTheme` (ada di SDK lokal) |
```

dengan:

```
| Buka halaman | fade maju | 450ms (tetap, bawaan builder) | `FadeForwardsPageTransitionsBuilder` di `pageTransitionsTheme` (ada di SDK lokal) |
```

- [ ] **Step 8: Analyze, test, cek visual**

Run: `/c/flutter/bin/flutter analyze && /c/flutter/bin/flutter test`
Expected: 9 issue (baseline); 90 test lulus.

Cek manual di emulator (`/c/flutter/bin/flutter run`): Beranda, form invoice, form struk, Pengaturan, di mode terang dan gelap. Catat di laporan task layar yang teksnya terpotong atau bertumpuk setelah `bodyMedium` 14→15 atau latar jadi putih (perbaikan per layar dilakukan di tahap layar itu, kecuali teks benar-benar tidak terbaca: perbaiki di task ini).

- [ ] **Step 9: Commit**

```bash
git add lib/main.dart test/theme_test.dart docs/superpowers/specs/2026-11-19-ui-refresh-design.md
git commit -m "feat: unify type scale, fields and buttons in theme" -m "Six text sizes via textTheme, 48dp buttons, borderless filled fields with AA hint color, 1px dividers, white light background, built-in fade-forwards page transition. Status bar icons follow the resolved theme so system mode works."
```

---

### Task 4: Pindah tab dengan fade, tanpa swipe

Swipe `PageView` dimatikan hanya di tab Pengingat (`main_navigation.dart:26`); di Riwayat, geser ganti tab berebut dengan geser-hapus. `PageView` default membuang halaman di luar layar, jadi halaman sudah dibangun ulang tiap kunjungan; `AnimatedSwitcher` mempertahankan perilaku itu.

**Files:**
- Modify: `lib/pages/main_navigation.dart` (`MainNavigation`, `_MainNavigationState`)
- Modify: `lib/pages/dashboard_page.dart:484-491` (`_navigateToSettings`)

**Interfaces:**
- Produces: `static void MainNavigation.goToTab(BuildContext context, int index)`, dipakai `dashboard_page.dart`.

- [ ] **Step 1: Ganti state navigasi**

Di `lib/pages/main_navigation.dart`, dalam `class MainNavigation`, tambahkan:

```dart
  /// Switch tab from a page inside MainNavigation (e.g. dashboard banner).
  static void goToTab(BuildContext context, int index) => context
      .findAncestorStateOfType<_MainNavigationState>()
      ?._onNavTap(index);
```

Dalam `_MainNavigationState`, hapus: `late final PageController _pageCtrl;`, konstanta `_swipeDisabledTabs` beserta komentarnya, `_pageCtrl = PageController();` di `initState`, seluruh override `dispose()` (isinya hanya `_pageCtrl.dispose()` dan `super.dispose()`), dan method `_onPageChanged`. Ganti `_onNavTap`:

```dart
  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    if (index == 0 || index == 2) _loadDueCount();
  }
```

Tambahkan di `_MainNavigationState`:

```dart
  static const _pages = [
    DashboardPage(),
    HistoryPage(),
    ReminderPage(),
    SettingsPage(),
  ];
```

- [ ] **Step 2: Ganti `PageView` dengan `AnimatedSwitcher`**

Di `build`, ganti `body: PageView(` sampai penutup `),` setelah `children: const [...]` dengan:

```dart
      body: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        switchInCurve: Easing.emphasizedDecelerate,
        switchOutCurve: Easing.emphasizedAccelerate,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            // ~8px rise on a phone-height page.
            position: Tween(begin: const Offset(0, 0.01), end: Offset.zero)
                .animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
```

- [ ] **Step 3: Perbaiki lompatan dari Beranda ke Pengaturan**

Di `lib/pages/dashboard_page.dart`, ganti seluruh method `_navigateToSettings` (termasuk dua baris komentarnya):

```dart
  void _navigateToSettings() => MainNavigation.goToTab(context, 3);
```

dan tambahkan `import 'main_navigation.dart';` di blok import relatif.

Run: `grep -rn "PageView\|_pageCtrl\|PageController\|_swipeDisabledTabs" lib/pages/main_navigation.dart lib/pages/dashboard_page.dart`
Expected: tidak ada output.

- [ ] **Step 4: Analyze dan test**

Run: `/c/flutter/bin/flutter analyze && /c/flutter/bin/flutter test`
Expected: 9 issue (baseline), 90 test lulus. Jika muncul `unused_import` baru, hapus import itu.

- [ ] **Step 5: Cek manual di emulator**

Run: `/c/flutter/bin/flutter run`
- Tap keempat tab: isi berganti dengan fade singkat; geser horizontal tidak berpindah tab.
- Riwayat: geser item menghapus item, tidak berpindah tab.
- Badge pengingat di nav ter-update setelah membuka tab Beranda/Pengingat.
- Banner toko di Beranda membuka tab Pengaturan.
- Opsi developer "Skala animasi transisi: nonaktif" / aksesibilitas "Hapus animasi": tab berganti tanpa animasi.

- [ ] **Step 6: Commit**

```bash
git add lib/pages/main_navigation.dart lib/pages/dashboard_page.dart
git commit -m "feat: fade between tabs instead of swiping" -m "Horizontal swipe on the tab PageView competed with swipe-to-delete in History. Tabs now switch with a 200ms fade that respects reduce-motion. Dashboard jumps to Settings through MainNavigation.goToTab instead of looking up the PageView."
```

---

### Task 5: Verifikasi akhir tahap 1

**Files:** tidak ada perubahan kode.

- [ ] **Step 1: Analyze dan test penuh**

Run: `/c/flutter/bin/flutter analyze && /c/flutter/bin/flutter test`
Expected: 9 issue (semua dari baseline), 90 test lulus.

- [ ] **Step 2: Cek manual alur yang dibetulkan (emulator)**

- Buat invoice dengan nama pembeli → Generate → "Selesai": dialog "Atur Pengingat?" muncul; setelah dijawab, kembali ke halaman utama.
- Buat struk → Generate → "Selesai": dialog pengingat muncul, lalu kembali ke halaman utama.
- Riwayat → buka dokumen → preview → "Selesai": kembali ke Riwayat, aplikasi tidak menutup.
- Preview → back sistem: kembali ke form, form tidak tertutup.
- Mode gelap: label tombol generate invoice/struk dan simpan pengaturan berwarna gelap di atas biru/hijau muda.
- Pengaturan → tema "Ikuti sistem" dengan sistem gelap: ikon status bar terang.

- [ ] **Step 3: Review diff**

Run: `git diff --stat main...HEAD -- lib test`
Setiap file yang berubah tercantum di tabel File Structure. Tidak ada `print`/`debugPrint` baru, kode yang dikomentari, atau TODO tanpa pemilik.
