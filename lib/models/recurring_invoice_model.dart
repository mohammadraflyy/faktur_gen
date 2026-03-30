import 'reminder_model.dart';

class RecurringInvoiceModel {
  final String id;
  String contactId;
  String contactName;
  String contactPhone;
  String contactAddress;
  String contactNpwp;
  RepeatInterval interval;
  DateTime nextDate;
  DateTime? lastGenerated;
  bool isActive;
  String catatan;

  // Invoice template data
  String invoicePrefix;
  String currency;
  double taxRate;
  List<RecurringItem> items;

  final DateTime createdAt;

  RecurringInvoiceModel({
    required this.id,
    this.contactId = '',
    required this.contactName,
    this.contactPhone = '',
    this.contactAddress = '',
    this.contactNpwp = '',
    required this.interval,
    required this.nextDate,
    this.lastGenerated,
    this.isActive = true,
    this.catatan = '',
    this.invoicePrefix = 'INV',
    this.currency = 'IDR',
    this.taxRate = 11,
    this.items = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  void advanceToNext() {
    lastGenerated = nextDate;
    final months = interval.months;
    nextDate = DateTime(
      nextDate.year,
      nextDate.month + months,
      nextDate.day,
    );
  }

  bool get isDue =>
      isActive &&
      (nextDate.isBefore(DateTime.now()) ||
          nextDate.isAtSameMomentAs(DateTime(
              DateTime.now().year, DateTime.now().month, DateTime.now().day)));

  Map<String, dynamic> toMap() => {
        'id': id,
        'contactId': contactId,
        'contactName': contactName,
        'contactPhone': contactPhone,
        'contactAddress': contactAddress,
        'contactNpwp': contactNpwp,
        'interval': interval.index,
        'nextDate': nextDate.millisecondsSinceEpoch,
        'lastGenerated': lastGenerated?.millisecondsSinceEpoch,
        'isActive': isActive,
        'catatan': catatan,
        'invoicePrefix': invoicePrefix,
        'currency': currency,
        'taxRate': taxRate,
        'items': items.map((i) => i.toMap()).toList(),
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory RecurringInvoiceModel.fromMap(Map<String, dynamic> map) =>
      RecurringInvoiceModel(
        id: map['id'] as String,
        contactId: map['contactId'] as String? ?? '',
        contactName: map['contactName'] as String? ?? '',
        contactPhone: map['contactPhone'] as String? ?? '',
        contactAddress: map['contactAddress'] as String? ?? '',
        contactNpwp: map['contactNpwp'] as String? ?? '',
        interval: RepeatInterval.values[map['interval'] as int? ?? 1],
        nextDate:
            DateTime.fromMillisecondsSinceEpoch(map['nextDate'] as int),
        lastGenerated: map['lastGenerated'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lastGenerated'] as int)
            : null,
        isActive: map['isActive'] as bool? ?? true,
        catatan: map['catatan'] as String? ?? '',
        invoicePrefix: map['invoicePrefix'] as String? ?? 'INV',
        currency: map['currency'] as String? ?? 'IDR',
        taxRate: (map['taxRate'] as num?)?.toDouble() ?? 11,
        items: (map['items'] as List?)
                ?.map(
                    (e) => RecurringItem.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: map['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
            : null,
      );
}

class RecurringItem {
  final String nama;
  final String deskripsi;
  final double kuantitas;
  final String satuan;
  final double hargaSatuan;

  RecurringItem({
    required this.nama,
    this.deskripsi = '',
    this.kuantitas = 1,
    this.satuan = 'Unit',
    this.hargaSatuan = 0,
  });

  Map<String, dynamic> toMap() => {
        'nama': nama,
        'deskripsi': deskripsi,
        'kuantitas': kuantitas,
        'satuan': satuan,
        'hargaSatuan': hargaSatuan,
      };

  factory RecurringItem.fromMap(Map<String, dynamic> map) => RecurringItem(
        nama: map['nama'] as String? ?? '',
        deskripsi: map['deskripsi'] as String? ?? '',
        kuantitas: (map['kuantitas'] as num?)?.toDouble() ?? 1,
        satuan: map['satuan'] as String? ?? 'Unit',
        hargaSatuan: (map['hargaSatuan'] as num?)?.toDouble() ?? 0,
      );
}
