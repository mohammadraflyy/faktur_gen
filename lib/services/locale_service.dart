import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  id('Bahasa Indonesia', 'ID'),
  en('English', 'EN');

  final String label;
  final String code;
  const AppLanguage(this.label, this.code);
}

class LocaleService {
  static const _kLanguage = 's_language';
  static final languageNotifier = ValueNotifier<AppLanguage>(AppLanguage.id);

  static AppLanguage get current => languageNotifier.value;
  static bool get isEn => current == AppLanguage.en;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLanguage);
    languageNotifier.value = code == 'en' ? AppLanguage.en : AppLanguage.id;
  }

  static Future<void> setLanguage(AppLanguage lang) async {
    languageNotifier.value = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, lang.code.toLowerCase());
  }
}

/// Translate a key. Returns English or Indonesian based on current locale.
String tr(String key) => _strings[key]?[LocaleService.isEn ? 1 : 0] ?? key;

/// [Indonesian, English] pairs
const _strings = <String, List<String>>{
  // ─── Navigation ──────────────────────────────────────────────────────────
  'nav.dashboard': ['Dashboard', 'Dashboard'],
  'nav.history': ['Riwayat', 'History'],
  'nav.notifications': ['Notifikasi', 'Notifications'],
  'nav.settings': ['Pengaturan', 'Settings'],

  // ─── Dashboard ───────────────────────────────────────────────────────────
  'dashboard.title': ['Faktura', 'Faktura'],
  'dashboard.subtitle': ['Invoice & struk profesional', 'Professional invoices & receipts'],
  'dashboard.summary': ['Ringkasan', 'Summary'],
  'dashboard.this_month': ['Bulan Ini', 'This Month'],
  'dashboard.last_month': ['Bulan Lalu', 'Last Month'],
  'dashboard.documents': ['dokumen', 'documents'],
  'dashboard.invoice': ['Invoice', 'Invoice'],
  'dashboard.receipt': ['Struk', 'Receipt'],
  'dashboard.this_month_short': ['bulan ini', 'this month'],
  'dashboard.unpaid': ['Belum Lunas', 'Unpaid'],
  'dashboard.revenue_chart': ['Pendapatan 6 Bulan Terakhir', 'Revenue Last 6 Months'],
  'dashboard.upcoming_reminders': ['Pengingat Mendatang', 'Upcoming Reminders'],
  'dashboard.no_data': ['Belum ada data', 'No data yet'],
  'dashboard.no_data_sub': ['Buat invoice atau struk pertamamu\ndengan menekan tombol + di bawah', 'Create your first invoice or receipt\nby tapping the + button below'],
  'dashboard.setup_store': ['Atur profil toko', 'Set up store profile'],
  'dashboard.setup_store_sub': ['Tambahkan nama, alamat, dan logo', 'Add name, address, and logo'],
  'dashboard.overdue': ['Terlewat', 'Overdue'],
  'dashboard.today': ['Hari ini', 'Today'],
  'dashboard.total': ['Total', 'Total'],

  // ─── Create Sheet ────────────────────────────────────────────────────────
  'create.title': ['Buat Dokumen', 'Create Document'],
  'create.invoice': ['Invoice', 'Invoice'],
  'create.invoice_sub': ['Faktur + PPN', 'Invoice + Tax'],
  'create.receipt': ['Struk', 'Receipt'],
  'create.receipt_sub': ['Struk kasir', 'Cash receipt'],

  // ─── History ─────────────────────────────────────────────────────────────
  'history.title': ['Riwayat', 'History'],
  'history.search': ['Cari dokumen...', 'Search documents...'],
  'history.all': ['Semua', 'All'],
  'history.invoice': ['Invoice', 'Invoice'],
  'history.receipt': ['Struk', 'Receipt'],
  'history.unpaid': ['Belum Lunas', 'Unpaid'],
  'history.paid': ['Lunas', 'Paid'],
  'history.empty': ['Belum ada riwayat', 'No history yet'],
  'history.empty_sub': ['Dokumen yang dibuat akan muncul di sini', 'Created documents will appear here'],
  'history.delete_title': ['Hapus Dokumen?', 'Delete Document?'],
  'history.export_csv': ['Export CSV', 'Export CSV'],
  'history.export_fail': ['Gagal export', 'Export failed'],
  'history.duplicate': ['Buat Ulang Dokumen', 'Duplicate Document'],
  'history.tap_to_change': ['Tap untuk ubah', 'Tap to change'],

  // ─── Reminders ───────────────────────────────────────────────────────────
  'reminder.title': ['Pengingat Layanan', 'Service Reminders'],
  'reminder.active': ['Aktif', 'Active'],
  'reminder.done': ['Selesai', 'Done'],
  'reminder.empty_pending': ['Belum ada pengingat', 'No reminders yet'],
  'reminder.empty_done': ['Belum ada pengingat selesai', 'No completed reminders'],
  'reminder.add_hint': ['Tap + untuk menambah pengingat', 'Tap + to add a reminder'],
  'reminder.add_title': ['Tambah Pengingat', 'Add Reminder'],
  'reminder.edit_title': ['Edit Pengingat', 'Edit Reminder'],
  'reminder.detail_title': ['Detail Pengingat', 'Reminder Details'],
  'reminder.customer': ['Pelanggan', 'Customer'],
  'reminder.customer_name': ['Nama Pelanggan', 'Customer Name'],
  'reminder.service': ['Layanan', 'Service'],
  'reminder.service_type': ['Jenis Layanan', 'Service Type'],
  'reminder.service_hint': ['cth: Cuci AC, Service Mesin', 'e.g. AC Service, Machine Service'],
  'reminder.date': ['Tanggal', 'Date'],
  'reminder.time': ['Jam', 'Time'],
  'reminder.repeat': ['Ulangi', 'Repeat'],
  'reminder.notes': ['Catatan', 'Notes'],
  'reminder.notes_hint': ['cth: Unit outdoor lantai 2', 'e.g. Outdoor unit 2nd floor'],
  'reminder.notes_optional': ['Catatan (opsional)', 'Notes (optional)'],
  'reminder.status': ['Status', 'Status'],
  'reminder.mark_done': ['Tandai Selesai', 'Mark as Done'],
  'reminder.marked_done': ['ditandai selesai', 'marked as done'],
  'reminder.reschedule': ['Jadwal Ulang', 'Reschedule'],
  'reminder.send_wa': ['Kirim WhatsApp', 'Send WhatsApp'],
  'reminder.no_phone': ['Nomor telepon tidak tersedia', 'Phone number not available'],
  'reminder.wa_fail': ['Tidak dapat membuka WhatsApp', 'Cannot open WhatsApp'],
  'reminder.create_invoice': ['Buat Invoice', 'Create Invoice'],
  'reminder.create_receipt': ['Buat Struk', 'Create Receipt'],
  'reminder.delete_title': ['Hapus Pengingat?', 'Delete Reminder?'],
  'reminder.save': ['Simpan Pengingat', 'Save Reminder'],
  'reminder.save_edit': ['Simpan Perubahan', 'Save Changes'],
  'reminder.pick_contact': ['Pilih dari kontak', 'Pick from contacts'],
  'reminder.phone': ['No. Telepon / WhatsApp', 'Phone / WhatsApp'],
  'reminder.phone_hint': ['cth: 08123456789', 'e.g. 08123456789'],
  'reminder.address': ['Alamat (opsional)', 'Address (optional)'],
  'reminder.overdue': ['Terlewat', 'Overdue'],
  'reminder.due_today': ['Jatuh tempo hari ini', 'Due today'],
  'reminder.waiting': ['Menunggu', 'Waiting'],

  // ─── Contacts ────────────────────────────────────────────────────────────
  'contact.title': ['Kontak', 'Contacts'],
  'contact.search': ['Cari nama atau telepon...', 'Search name or phone...'],
  'contact.add': ['Tambah', 'Add'],
  'contact.add_title': ['Tambah Kontak', 'Add Contact'],
  'contact.edit_title': ['Edit Kontak', 'Edit Contact'],
  'contact.delete_title': ['Hapus Kontak?', 'Delete Contact?'],
  'contact.empty': ['Belum ada kontak', 'No contacts yet'],
  'contact.not_found': ['Tidak ditemukan', 'Not found'],
  'contact.name': ['Nama', 'Name'],

  // ─── Settings ────────────────────────────────────────────────────────────
  'settings.title': ['Pengaturan', 'Settings'],
  'settings.general': ['UMUM', 'GENERAL'],
  'settings.documents': ['DOKUMEN', 'DOCUMENTS'],
  'settings.app': ['APLIKASI', 'APP'],
  'settings.store_profile': ['Profil Toko', 'Store Profile'],
  'settings.contact': ['Kontak', 'Contact'],
  'settings.payment_info': ['Informasi Pembayaran', 'Payment Info'],
  'settings.tax_doc': ['Pajak & Dokumen', 'Tax & Documents'],
  'settings.receipt_settings': ['Pengaturan Struk', 'Receipt Settings'],
  'settings.signature': ['Tanda Tangan', 'Signature'],
  'settings.template': ['Template Dokumen', 'Document Templates'],
  'settings.appearance': ['Tampilan', 'Appearance'],
  'settings.language': ['Bahasa', 'Language'],
  'settings.backup': ['Backup & Restore', 'Backup & Restore'],
  'settings.sandbox': ['Sandbox', 'Sandbox'],
  'settings.about': ['Tentang', 'About'],
  'settings.not_set': ['Belum diatur', 'Not set'],
  'settings.already_set': ['Sudah diatur', 'Set'],
  'settings.accounts': ['rekening', 'accounts'],
  'settings.save': ['Simpan', 'Save'],
  'settings.saved': ['Disimpan', 'Saved'],
  'settings.store_name': ['Nama Toko / Perusahaan', 'Store / Company Name'],
  'settings.address': ['Alamat Lengkap', 'Full Address'],
  'settings.phone': ['No. Telepon / WhatsApp', 'Phone / WhatsApp'],
  'settings.email': ['Email', 'Email'],
  'settings.website': ['Website', 'Website'],
  'settings.npwp': ['NPWP', 'Tax ID (NPWP)'],
  'settings.footer_receipt': ['Pesan Footer Struk', 'Receipt Footer Message'],
  'settings.tax_rate': ['Tarif Pajak (%)', 'Tax Rate (%)'],
  'settings.currency': ['Mata Uang', 'Currency'],
  'settings.prefix_invoice': ['Prefix Invoice', 'Invoice Prefix'],
  'settings.prefix_receipt': ['Prefix Struk', 'Receipt Prefix'],
  'settings.add_logo': ['Tambah Logo', 'Add Logo'],
  'settings.tap_change_logo': ['Tap untuk ganti logo', 'Tap to change logo'],
  'settings.gallery': ['Galeri Foto', 'Photo Gallery'],
  'settings.camera': ['Kamera', 'Camera'],
  'settings.delete_logo': ['Hapus Logo', 'Delete Logo'],
  'settings.sign_tap': ['Tap untuk membuat tanda tangan', 'Tap to create signature'],
  'settings.sign_note': ['Tanda tangan akan ditampilkan pada invoice', 'Signature will appear on invoices'],
  'settings.account_n': ['Rekening', 'Account'],
  'settings.bank_name': ['Nama Bank', 'Bank Name'],
  'settings.account_number': ['Nomor Rekening', 'Account Number'],
  'settings.account_holder': ['Nama Pemilik Rekening', 'Account Holder'],
  'settings.export_backup': ['Export Backup', 'Export Backup'],
  'settings.export_backup_sub': ['Simpan semua data ke file JSON', 'Save all data to JSON file'],
  'settings.import_backup': ['Import Backup', 'Import Backup'],
  'settings.import_backup_sub': ['Pulihkan data dari file backup', 'Restore data from backup file'],
  'settings.import_confirm': ['Import Backup?', 'Import Backup?'],
  'settings.import_warn': ['Data saat ini akan ditimpa dengan data dari backup. Lanjutkan?', 'Current data will be overwritten with backup data. Continue?'],
  'settings.import_success': ['Backup berhasil di-import! Restart aplikasi.', 'Backup imported successfully! Restart the app.'],
  'settings.import_invalid': ['File backup tidak valid', 'Invalid backup file'],
  'settings.backup_note': ['Backup mencakup pengaturan, kontak, riwayat dokumen, dan pengingat.', 'Backup includes settings, contacts, document history, and reminders.'],

  // ─── Appearance ──────────────────────────────────────────────────────────
  'appearance.title': ['Tampilan', 'Appearance'],
  'appearance.light': ['Terang', 'Light'],
  'appearance.dark': ['Gelap', 'Dark'],
  'appearance.system': ['Ikuti Sistem', 'Follow System'],

  // ─── Template ────────────────────────────────────────────────────────────
  'template.title': ['Template Dokumen', 'Document Templates'],
  'template.invoice_design': ['DESAIN INVOICE', 'INVOICE DESIGN'],
  'template.receipt_design': ['DESAIN STRUK', 'RECEIPT DESIGN'],
  'template.customize': ['KUSTOMISASI', 'CUSTOMIZATION'],
  'template.primary_color': ['WARNA UTAMA', 'PRIMARY COLOR'],
  'template.show_logo': ['Tampilkan Logo', 'Show Logo'],
  'template.logo_center': ['Logo di Tengah', 'Center Logo'],
  'template.logo_center_off': ['Off = logo di kiri', 'Off = logo on left'],
  'template.show_signature': ['Tampilkan Tanda Tangan', 'Show Signature'],
  'template.show_bank': ['Tampilkan Info Bank', 'Show Bank Info'],
  'template.show_npwp': ['Tampilkan NPWP', 'Show Tax ID'],

  // ─── Forms ───────────────────────────────────────────────────────────────
  'form.invoice_title': ['Buat Invoice', 'Create Invoice'],
  'form.receipt_title': ['Buat Struk', 'Create Receipt'],
  'form.generate_invoice': ['Generate Invoice', 'Generate Invoice'],
  'form.generate_receipt': ['Generate Struk', 'Generate Receipt'],
  'form.exit_title': ['Keluar?', 'Leave?'],
  'form.exit_message': ['Form belum disimpan. Yakin ingin keluar?', 'Unsaved changes. Are you sure you want to leave?'],

  // ─── Sandbox ─────────────────────────────────────────────────────────────
  'sandbox.title': ['Sandbox', 'Sandbox'],
  'sandbox.notif_status': ['Status Notifikasi', 'Notification Status'],
  'sandbox.active_reminders': ['Pengingat aktif', 'Active reminders'],
  'sandbox.scheduled_notifs': ['Notifikasi terjadwal', 'Scheduled notifications'],
  'sandbox.last_backup': ['Auto-backup terakhir', 'Last auto-backup'],
  'sandbox.backup_note': ['Auto-backup otomatis setiap 7 hari ke penyimpanan internal', 'Auto-backup runs every 7 days to internal storage'],
  'sandbox.test_actions': ['AKSI TEST', 'TEST ACTIONS'],
  'sandbox.test_notif': ['Test Notifikasi', 'Test Notification'],
  'sandbox.test_notif_sub': ['Kirim notifikasi test untuk memastikan sistem berjalan', 'Send test notification to verify system is working'],
  'sandbox.test_sent': ['Test notifikasi dikirim!', 'Test notification sent!'],
  'sandbox.reschedule_all': ['Reschedule Semua Notifikasi', 'Reschedule All Notifications'],
  'sandbox.reschedule_sub': ['Jadwal ulang semua notifikasi pengingat yang aktif', 'Reschedule all active reminder notifications'],
  'sandbox.rescheduled': ['Semua notifikasi dijadwal ulang', 'All notifications rescheduled'],
  'sandbox.cancel_all': ['Batalkan Semua Notifikasi', 'Cancel All Notifications'],
  'sandbox.cancel_sub': ['Hapus semua notifikasi yang terjadwal', 'Remove all scheduled notifications'],
  'sandbox.cancel_confirm': ['Batalkan Semua?', 'Cancel All?'],
  'sandbox.cancel_warn': ['Semua notifikasi terjadwal akan dihapus. Lanjutkan?', 'All scheduled notifications will be removed. Continue?'],
  'sandbox.cancel_yes': ['Ya, Hapus', 'Yes, Remove'],
  'sandbox.cancelled': ['Semua notifikasi dibatalkan', 'All notifications cancelled'],
  'sandbox.never': ['Belum pernah', 'Never'],

  // ─── About ───────────────────────────────────────────────────────────────
  'about.title': ['Tentang', 'About'],
  'about.subtitle': ['Invoice & Struk Profesional', 'Professional Invoices & Receipts'],
  'about.features': ['Fitur Utama', 'Key Features'],
  'about.features_desc': ['Buat invoice & struk profesional, pengingat layanan, manajemen kontak, template, dan katalog item', 'Create professional invoices & receipts, service reminders, contact management, templates, and item catalog'],
  'about.print': ['Format Cetak', 'Print Format'],
  'about.print_desc': ['Invoice A4 dengan PPN, struk thermal 80mm', 'A4 invoice with tax, 80mm thermal receipt'],
  'about.data': ['Keamanan Data', 'Data Security'],
  'about.data_desc': ['Auto-backup mingguan, export/import manual, data tersimpan lokal di perangkat', 'Weekly auto-backup, manual export/import, data stored locally on device'],
  'about.theme': ['Tampilan', 'Appearance'],
  'about.theme_desc': ['Mode terang, gelap, dan ikuti sistem', 'Light, dark, and system mode'],
  'about.made_with': ['Dibuat dengan \u2764', 'Made with \u2764'],
  'about.version': ['Versi {version}', 'Version {version}'],

  // ─── Update ──────────────────────────────────────────────────────────────
  'update.check': ['Periksa pembaruan', 'Check for updates'],
  'update.check_sub': ['Unduh versi terbaru dari GitHub', 'Download the latest version from GitHub'],
  'update.checking': ['Memeriksa pembaruan rilis…', 'Checking for updates…'],
  'update.latest': ['Aplikasi Sudah Versi Terbaru', 'App Is Up to Date'],
  'update.latest_desc': ['Faktura Anda (v{version}) sudah merupakan versi paling mutakhir.', 'Your Faktura (v{version}) is the latest version.'],
  'update.check_failed': ['Gagal Memeriksa', 'Check Failed'],
  'update.check_failed_desc': ['Tidak dapat terhubung ke server rilis GitHub. Pastikan perangkat terhubung ke internet.', 'Could not reach the GitHub release server. Make sure the device is connected to the internet.'],
  'update.title': ['Pembaruan {name}', 'Update {name}'],
  'update.new_version': ['Versi baru tersedia: v{latest} (versi saat ini: v{current})', 'New version available: v{latest} (current version: v{current})'],
  'update.changelog': ['Catatan Perubahan:', 'Changelog:'],
  'update.later': ['Nanti saja', 'Not now'],
  'update.download': ['Unduh & Perbarui', 'Download & Update'],
  'update.downloading': ['Mengunduh… {percent}%', 'Downloading… {percent}%'],
  'update.downloading_plain': ['Mengunduh…', 'Downloading…'],
  'update.download_failed': ['Gagal mengunduh file update', 'Failed to download the update'],
  'update.available': ['Pembaruan v{version} tersedia!', 'Update v{version} available!'],
  'update.now': ['Perbarui Sekarang', 'Update Now'],
  'update.dismiss': ['Tutup notifikasi', 'Dismiss'],

  // ─── Subscription ────────────────────────────────────────────────────────
  'sub.pro': ['Faktura Pro', 'Faktura Pro'],
  'sub.free': ['Faktura Free', 'Faktura Free'],
  'sub.upgrade': ['Upgrade', 'Upgrade'],
  'sub.unlock_all': ['Buka semua fitur premium', 'Unlock all premium features'],
  'sub.subscribe': ['Berlangganan', 'Subscribe'],
  'sub.restore': ['Pulihkan Pembelian', 'Restore Purchases'],
  'sub.restore_done': ['Pembelian dipulihkan', 'Purchases restored'],
  'sub.restore_error': ['Gagal memulihkan', 'Restore failed'],
  'sub.purchase_error': ['Gagal membeli', 'Purchase failed'],
  'sub.not_available': ['Langganan belum tersedia', 'Subscription not available yet'],
  'sub.redeem': ['Kode Redeem', 'Redeem Code'],
  'sub.redeem_code': ['Masukkan kode', 'Enter code'],
  'sub.redeem_activate': ['Aktifkan', 'Activate'],
  'sub.redeem_success': ['Pro Lifetime berhasil diaktifkan!', 'Pro Lifetime activated!'],
  'sub.redeem_invalid': ['Kode tidak valid atau sudah digunakan', 'Invalid or already used code'],
  'sub.unlimited': ['Dokumen tak terbatas', 'Unlimited documents'],
  'sub.no_watermark': ['Tanpa watermark', 'No watermark'],
  'sub.qris': ['QRIS QR Code', 'QRIS QR Code'],
  'sub.recurring': ['Invoice berulang', 'Recurring invoices'],
  'sub.multicurrency': ['Konversi mata uang', 'Currency conversion'],
  'sub.client_numbering': ['Penomoran per klien', 'Per-client numbering'],
  'sub.docs_remaining': ['dokumen tersisa bulan ini', 'documents remaining this month'],

  // ─── Recurring ──────────────────────────────────────────────────────────
  'recurring.title': ['Invoice Berulang', 'Recurring Invoices'],
  'recurring.subtitle': ['Otomatis buat invoice berkala', 'Auto-generate periodic invoices'],
  'recurring.empty': ['Belum ada invoice berulang', 'No recurring invoices'],
  'recurring.empty_sub': ['Tap + untuk menambah', 'Tap + to add'],
  'recurring.add_title': ['Tambah Invoice Berulang', 'Add Recurring Invoice'],
  'recurring.edit_title': ['Edit Invoice Berulang', 'Edit Recurring Invoice'],
  'recurring.delete_title': ['Hapus Invoice Berulang?', 'Delete Recurring Invoice?'],
  'recurring.client': ['Klien', 'Client'],
  'recurring.client_required': ['Nama klien wajib diisi', 'Client name is required'],
  'recurring.interval': ['Interval', 'Interval'],
  'recurring.next_date': ['Tanggal Berikutnya', 'Next Date'],
  'recurring.next': ['Berikutnya', 'Next'],
  'recurring.items': ['Item', 'Items'],
  'recurring.add_item': ['Tambah Item', 'Add Item'],
  'recurring.item_name': ['Nama', 'Name'],
  'recurring.qty': ['Qty', 'Qty'],
  'recurring.price': ['Harga', 'Price'],
  'recurring.notes': ['Catatan', 'Notes'],
  'recurring.save': ['Simpan', 'Save'],
  'recurring.save_edit': ['Simpan Perubahan', 'Save Changes'],
  'recurring.active': ['Aktif', 'Active'],
  'recurring.paused': ['Dijeda', 'Paused'],
  'recurring.pause': ['Jeda', 'Pause'],
  'recurring.activate': ['Aktifkan', 'Activate'],

  // ─── Settings (new) ─────────────────────────────────────────────────────
  'settings.qris': ['QRIS Payment', 'QRIS Payment'],
  'settings.qris_desc': ['Masukkan ID Merchant QRIS Anda. QR code akan muncul di invoice untuk pembayaran langsung.', 'Enter your QRIS Merchant ID. A QR code will appear on invoices for direct payment.'],
  'settings.qris_id': ['QRIS Merchant ID', 'QRIS Merchant ID'],

  // ─── Share ──────────────────────────────────────────────────────────────
  'share.whatsapp': ['Kirim WhatsApp', 'Send WhatsApp'],
  'share.no_phone': ['Nomor telepon klien tidak tersedia', 'Client phone number not available'],

  // ─── Dashboard (new) ───────────────────────────────────────────────────
  'dashboard.payment_overview': ['Ringkasan Pembayaran', 'Payment Overview'],
  'dashboard.paid': ['Lunas', 'Paid'],
  'dashboard.total_receivables': ['Total Piutang', 'Total Receivables'],
  'dashboard.overdue_amount': ['Tertunggak', 'Overdue'],
  'dashboard.collected_month': ['Diterima Bulan Ini', 'Collected This Month'],
  'dashboard.overdue_invoices': ['Invoice Tertunggak', 'Overdue Invoices'],
  'dashboard.days_overdue': ['hari', 'days'],

  // ─── Auth ─────────────────────────────────────────────────────────────────
  'auth.sign_in': ['Masuk dengan Google', 'Sign in with Google'],
  'auth.sign_out': ['Keluar', 'Sign Out'],
  'auth.skip': ['Lewati, gunakan offline', 'Skip, use offline'],
  'auth.sign_in_subtitle': ['Masuk untuk menyimpan data ke cloud', 'Sign in to save data to the cloud'],
  'auth.signing_in': ['Sedang masuk...', 'Signing in...'],
  'auth.sign_out_confirm': ['Keluar dari akun?', 'Sign out?'],
  'auth.sign_out_warn': ['Data tetap tersimpan di cloud', 'Data remains saved in cloud'],
  'auth.migration_progress': ['Menyinkronkan data...', 'Syncing data...'],
  'auth.account': ['Akun', 'Account'],
  'auth.not_signed_in': ['Belum masuk', 'Not signed in'],
  'auth.sign_in_failed': ['Gagal masuk', 'Sign in failed'],

  // ─── Common ──────────────────────────────────────────────────────────────
  'common.cancel': ['Batal', 'Cancel'],
  'common.delete': ['Hapus', 'Delete'],
  'common.edit': ['Edit', 'Edit'],
  'common.close': ['Tutup', 'Close'],
  'common.save': ['Simpan', 'Save'],
  'common.undo': ['Undo', 'Undo'],
  'common.deleted': ['dihapus', 'deleted'],
  'common.export_fail': ['Gagal export', 'Export failed'],
  'common.import_fail': ['Gagal import', 'Import failed'],
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
};
