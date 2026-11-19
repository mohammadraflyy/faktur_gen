# UI refresh Faktura: desain minimalis dan lebih halus

Tanggal: 2026-11-19
Status: disetujui user, siap dibuat rencana implementasi
Mockup: `docs/mockups/00-06*.svg`

## Tujuan

Membuat app lebih rapi, minimalis, dan terasa halus tanpa mengganti identitas (biru Faktura, hijau struk) atau fitur. Refresh terarah, bukan redesign penuh: struktur 4 tab + tombol "Buat" di tengah tetap.

Kriteria berhasil:
- Semua pasangan teks lulus WCAG AA (4.5:1), termasuk mode gelap.
- Semua elemen yang bisa ditekan punya area sentuh minimal 48dp.
- Form invoice dan struk tidak lagi membangun ulang seluruh halaman setiap ketikan.
- Mode English menerjemahkan seluruh alur buat dokumen.
- Tidak ada package baru.

## Masalah yang diperbaiki (hasil audit)

| Masalah | Lokasi |
|---|---|
| `textTheme` tidak dipakai; 188 `GoogleFonts.*()` langsung, ~15 ukuran font | seluruh `lib/pages` |
| Kotak kartu ditulis ulang manual, radius campur (4, 10, 12, 14) | `dashboard_page.dart:343`, `faktur_page.dart:776,905`, `history_page.dart:445` |
| Teks putih di tombol mode gelap: #60A5FA 2.5:1, #34D399 1.9:1; hijau terang #059669 3.77:1 | `faktur_page.dart:1124`, `settings_page.dart:727`, `struk_page.dart` |
| Teks abu alpha 0.2–0.4 (~2:1) | `history_page.dart:351-366` dan lainnya |
| Tombol item naik/turun/hapus 18–24dp | `faktur_page.dart:931-956` |
| Form invoice: 5 field per item sekaligus | `faktur_page.dart:961-1023` |
| `setState` seluruh halaman tiap ketik qty/harga | `faktur_page.dart:987,1015` |
| `faktur_page`, `struk_page`, `onboarding_page` tidak memakai `tr()` (~164 teks) | file tersebut |
| Gagal muat data jatuh ke tampilan kosong tanpa pesan | `dashboard_page.dart:56-58`, `history_page.dart` |
| Hapus item struk tanpa konfirmasi atau undo | `struk_page.dart:777-780` |
| Swipe ganti tab berebut dengan geser-hapus di Riwayat | `main_navigation.dart:26,146` |
| Menu Sandbox terlihat di build rilis | `settings_page.dart:177-183` |
| `showPdfActionSheet` (WhatsApp/cetak/unduh) tidak pernah dipanggil | `widgets/pdf_action_sheet.dart:7` |

Dugaan bug (belum direproduksi; diverifikasi di tahap 1 sebelum diperbaiki):
- "Selesai" di preview PDF menutup dua layar (`pdf_preview_page.dart:35-37`), sehingga tawaran pengingat di `faktur_page.dart:357-358` tidak muncul.
- Preview dibuka dari Riwayat (`history_page.dart:897,932`): "Selesai" ikut menutup halaman utama.

## Sistem desain (mockup 00)

Warna (kontras diukur dengan `contrast-check.py`):

| Peran | Terang | Gelap |
|---|---|---|
| Latar | #FFFFFF | #0F1117 |
| Teks utama | #111827 | #F3F4F6 |
| Teks sekunder | #6B7280 (4.83:1) | #9CA3AF (7.43:1) |
| Aksen / tombol utama | #2563EB, teks putih (5.17:1) | #60A5FA, teks #0F1117 (7.42:1) |
| Tombol struk | #047857, teks putih (5.48:1) | #34D399, teks #0F1117 (9.82:1) |
| Tombol sekunder | #EFF6FF, teks #1D4ED8 (6.16:1) | |
| Field | #F3F4F6, placeholder #4B5563 | |
| Garis pemisah | #F0F1F3, 1px | |
| Status | Lewat #B91C1C (6.47:1), Belum dibayar #B45309 (5.02:1), Lunas #047857 (5.48:1) | |

Aturan:
- Latar putih, tanpa kartu bergaris. Bagian dipisah jarak + garis 1px.
- Aksen hanya untuk tombol utama, tautan, tab aktif. Satu tombol utama per layar.
- Status = titik + teks berwarna, tidak pernah warna saja.
- Teks: 6 ukuran via `textTheme` (32/700 angka utama, 22/700 judul halaman, 17/600 judul bagian, 15/400 isi, 13/400 keterangan, 12/600 label minimum). Font tetap Inter. Judul bagian sentence case, bukan huruf besar.
- Radius: 12 tombol dan field, 20 sheet (atas). Padding samping 16–20 seragam.

Implementasi: semua di `ThemeData` (`main.dart`, `MyApp._light/_dark`) + `AppColors` yang sudah ada. Widget bersama baru hanya bila dipakai ≥2 layar: `AppSection` (judul + isi + pemisah), `AppField` (label di atas + field), `StatusLabel` (titik + teks). Widget pribadi yang sekarang terduplikasi di `faktur_page`/`struk_page` (`_card`, `_field`, `_ItemCtrls`, `_CatalogPickerSheet`, leave dialog) dipindah ke `lib/widgets/` dan dipakai keduanya.

## Layar

### Beranda (mockup 01)
Urutan: tanggal + nama toko → "Belum dibayar" (angka besar, jumlah lewat jatuh tempo merah) → maksimal 2 invoice lewat jatuh tempo + "Lihat semua" → bulan ini vs bulan lalu (bulan disebut) + mini bar 6 bulan → pengingat berikutnya.
- Grid 2×2 kartu statistik dihapus.
- Banner toko dihapus dari Beranda (lompatan via `PageView` di `dashboard_page.dart:484-490` ikut hilang).
- Reload otomatis setelah dokumen dibuat (callback/notifier dari alur buat dokumen, bukan pull-to-refresh saja).
- Kosong: "Belum ada invoice. Buat yang pertama" + tombol. Gagal: "Data tidak bisa dimuat. Periksa koneksi" + Coba lagi.

### Form invoice, pola A (mockup 02, 03 kiri)
- Satu halaman. Klien, jatuh tempo, pajak/catatan tampil sebagai baris teks; tap membuka sheet edit.
- Jatuh tempo: chip 7/14/30 hari + tanggal lain.
- Item = baris teks (nama, `qty × harga`, subtotal). Tap = sheet edit item (nama, deskripsi opsional, stepper jumlah 48dp, satuan, harga, tombol "Simpan · subtotal", "Hapus item"). Geser = hapus + snackbar Urungkan.
- Bar bawah menempel: total + "Buat PDF".
- State per item via `ValueNotifier`; total via `ValueListenableBuilder`. Tidak ada `setState` halaman saat mengetik.

### Setelah PDF jadi (mockup 03 kanan)
- Thumbnail PDF, centang sukses, "Invoice siap", klien + total.
- Aksi: Kirim lewat WhatsApp (utama), Bagikan, Cetak, Simpan. Pakai ulang `showPdfActionSheet`.
- Toggle "Ingatkan saat jatuh tempo" menggantikan dialog pengingat.
- "Selesai" menutup satu layar.

### Form struk (mockup 05 kiri)
- Pola sama dengan invoice. Jumlah diubah langsung di baris (stepper).
- Metode bayar: segmented control Tunai/Transfer/QRIS.
- Tunai: field uang diterima + nominal cepat (Uang pas, 50rb, 100rb), kembalian otomatis.
- Diskon dan catatan di baris yang bisa dibuka. Tombol "Buat struk" hijau #047857.
- Hapus item: geser + Urungkan (sekarang tanpa undo).

### Riwayat (mockup 04)
- Daftar polos dikelompokkan per tanggal; klien jadi judul, nomor dokumen di bawah, nominal + status di kanan.
- Filter jadi tab bergaris bawah (Semua, Invoice, Struk, Belum dibayar); area sentuh 48dp.
- Ekspor CSV jadi tombol teks.
- Geser hapus + Urungkan (4 detik) menggantikan dialog konfirmasi.
- Kosong karena filter: pesan + "Hapus filter". Gagal: pesan + Coba lagi.

### Pengaturan (mockup 05 kanan)
- Atas: avatar, nama toko, paket + kuota (`freeMonthlyLimit` = 30, `subscription_service.dart:15`) sebagai bar tipis, tautan Pro.
- Grup Toko / Dokumen / Aplikasi sebagai daftar polos, nilai saat ini di kanan. Label "Pro" tertulis.
- Sandbox hanya saat `kDebugMode`.
- Invoice berulang ditambah ke sheet "Buat" (tetap ada di Pengaturan).
- 11 sub-halaman privat di `settings_page.dart` dipindah ke `lib/pages/settings/` satu file per halaman; `_SettingsSubPageMixin` ikut dipindah agar bisa dipakai bersama. Perilaku tidak berubah.

### Pengingat, onboarding, login, splash
Tidak ditata ulang; hanya ikut sistem desain (tema, teks, kontras, `tr()`).

## Gerak dan kehalusan (mockup 06)

| Momen | Gerak | Durasi | Cara |
|---|---|---|---|
| Pindah tab | fade + naik 8px | 200ms | `AnimatedSwitcher`; swipe `PageView` dimatikan di semua tab |
| Buka halaman | fade maju | 450ms (tetap, bawaan builder) | `FadeForwardsPageTransitionsBuilder` di `pageTransitionsTheme` (ada di SDK lokal) |
| Sheet | naik, tarik untuk tutup | 250ms | `showModalBottomSheet` |
| Tambah/hapus item | tinggi membuka/menutup | 200ms | `AnimatedList` + `SizeTransition` |
| Total berubah | fade silang | 150ms | `AnimatedSwitcher` |
| Buat PDF | tombol jadi "Membuat…" + spinner kecil, disabled | sampai selesai | tanpa layar loading |
| PDF jadi | centang scale 0.8→1 + haptic ringan | 200ms | `ScaleTransition`, `HapticFeedback.lightImpact` |
| Memuat daftar | tidak tampil apa pun 300ms pertama, lalu teks memuat | — | cegah kedip spinner |

- Kurva: `Easing.emphasizedDecelerate` masuk, `Easing.emphasizedAccelerate` keluar.
- `MediaQuery.disableAnimationsOf(context)` true → durasi 0.
- Tidak ada animasi berulang tanpa pemicu.

Performa: ukur dengan DevTools (profile mode, form 10 item, ketik qty dan harga) sebelum dan sesudah tahap 2. Target: tidak ada frame > 16ms saat mengetik. Angka sebelum dicatat di PR tahap 2; tanpa pengukuran, klaim "lebih halus" tidak dipakai.

## Bahasa

Semua teks baru dan teks di `faktur_page`, `struk_page`, `onboarding_page`, `splash_page`, `pdf_preview_page`, `pdf_action_sheet` lewat `tr()` (`locale_service.dart`, format `{key: [id, en]}`).

## Tahap implementasi

Setiap tahap bisa dirilis sendiri dan diverifikasi di emulator (terang, gelap, English, font besar 200%).

1. **Fondasi**: tema + `textTheme` + warna kontras; widget bersama; `pageTransitionsTheme`; matikan swipe tab + `AnimatedSwitcher`; reproduksi lalu perbaiki dua bug "Selesai".
2. **Form invoice**: pola A, sheet item, layar setelah PDF jadi, `ValueNotifier`, `tr()`. Ukur performa sebelum/sesudah.
3. **Form struk**: pola sama + pembayaran dan kembalian, undo hapus, `tr()`.
4. **Beranda + Riwayat**: tata letak baru, kondisi kosong/gagal, reload otomatis, geser hapus + Urungkan.
5. **Pengaturan**: pecah file, daftar polos, Sandbox debug saja, invoice berulang di sheet "Buat".

## Verifikasi

- `flutter analyze` bersih dan `flutter test` lulus setiap tahap.
- Widget test untuk logika baru yang bercabang: hitung total + PPN dari `ValueNotifier`, kembalian struk, undo hapus item.
- Cek manual per tahap: mode terang/gelap, bahasa Indonesia/English, skala teks 200%, TalkBack membaca label tombol ikon.
- Kontras warna baru dicek dengan `contrast-check.py` sebelum dipakai.

## Di luar cakupan

- Tidak ganti font, warna merek, atau struktur navigasi 4 tab.
- Tidak ada package baru (termasuk `animations`).
- Tidak mengubah format PDF, model data, atau sinkronisasi Firebase.
- Tidak menata ulang Pengingat dan Onboarding.
