enum ReminderStatus { pending, done, dismissed }

enum RepeatInterval { none, monthly, bimonthly, quarterly, semiannual, annual }

enum ReminderDocType { invoice, struk }

extension RepeatIntervalExt on RepeatInterval {
  String get label {
    switch (this) {
      case RepeatInterval.none:
        return 'Tidak Berulang';
      case RepeatInterval.monthly:
        return 'Setiap 1 Bulan';
      case RepeatInterval.bimonthly:
        return 'Setiap 2 Bulan';
      case RepeatInterval.quarterly:
        return 'Setiap 3 Bulan';
      case RepeatInterval.semiannual:
        return 'Setiap 6 Bulan';
      case RepeatInterval.annual:
        return 'Setiap 1 Tahun';
    }
  }

  int get months {
    switch (this) {
      case RepeatInterval.none:
        return 0;
      case RepeatInterval.monthly:
        return 1;
      case RepeatInterval.bimonthly:
        return 2;
      case RepeatInterval.quarterly:
        return 3;
      case RepeatInterval.semiannual:
        return 6;
      case RepeatInterval.annual:
        return 12;
    }
  }
}

class ReminderItem {
  final String nama;
  final double kuantitas;
  final String satuan;
  final double hargaSatuan;

  ReminderItem({
    required this.nama,
    this.kuantitas = 1,
    this.satuan = 'Unit',
    this.hargaSatuan = 0,
  });

  Map<String, dynamic> toMap() => {
        'nama': nama,
        'kuantitas': kuantitas,
        'satuan': satuan,
        'hargaSatuan': hargaSatuan,
      };

  factory ReminderItem.fromMap(Map<String, dynamic> map) => ReminderItem(
        nama: map['nama'] as String? ?? '',
        kuantitas: (map['kuantitas'] as num?)?.toDouble() ?? 1,
        satuan: map['satuan'] as String? ?? 'Unit',
        hargaSatuan: (map['hargaSatuan'] as num?)?.toDouble() ?? 0,
      );
}

class ReminderModel {
  final String id;
  String contactName;
  String contactId;
  String contactPhone;
  String contactAddress;
  String serviceName;
  String notes;
  DateTime reminderDate;
  int reminderHour;
  int reminderMinute;
  ReminderStatus status;
  RepeatInterval repeatInterval;
  ReminderDocType? docType;
  List<ReminderItem> lastItems;
  final DateTime createdAt;

  ReminderModel({
    required this.id,
    required this.contactName,
    this.contactId = '',
    this.contactPhone = '',
    this.contactAddress = '',
    required this.serviceName,
    this.notes = '',
    required this.reminderDate,
    this.reminderHour = 8,
    this.reminderMinute = 0,
    this.status = ReminderStatus.pending,
    this.repeatInterval = RepeatInterval.none,
    this.docType,
    this.lastItems = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get notificationId => id.hashCode.abs() % 2147483647;

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Pengingat jatuh tempo hari ini
  bool get isDue {
    if (status != ReminderStatus.pending) return false;
    final today = _startOfDay(DateTime.now());
    final rDate = _startOfDay(reminderDate);
    return rDate.isAtSameMomentAs(today);
  }

  /// Pengingat sudah terlewat (sebelum hari ini)
  bool get isOverdue {
    if (status != ReminderStatus.pending) return false;
    final today = _startOfDay(DateTime.now());
    final rDate = _startOfDay(reminderDate);
    return rDate.isBefore(today);
  }

  bool get isRepeating => repeatInterval != RepeatInterval.none;

  bool get hasLastItems => lastItems.isNotEmpty;

  void advanceToNext() {
    if (!isRepeating) return;
    final months = repeatInterval.months;
    reminderDate = DateTime(
      reminderDate.year,
      reminderDate.month + months,
      reminderDate.day,
    );
    status = ReminderStatus.pending;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'contactName': contactName,
        'contactId': contactId,
        'contactPhone': contactPhone,
        'contactAddress': contactAddress,
        'serviceName': serviceName,
        'notes': notes,
        'reminderDate': reminderDate.millisecondsSinceEpoch,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'status': status.index,
        'repeatInterval': repeatInterval.index,
        'docType': docType?.index,
        'lastItems': lastItems.map((i) => i.toMap()).toList(),
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory ReminderModel.fromMap(Map<String, dynamic> map) => ReminderModel(
        id: map['id'] as String,
        contactName: map['contactName'] as String? ?? '',
        contactId: map['contactId'] as String? ?? '',
        contactPhone: map['contactPhone'] as String? ?? '',
        contactAddress: map['contactAddress'] as String? ?? '',
        serviceName: map['serviceName'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        reminderDate:
            DateTime.fromMillisecondsSinceEpoch(map['reminderDate'] as int),
        reminderHour: map['reminderHour'] as int? ?? 8,
        reminderMinute: map['reminderMinute'] as int? ?? 0,
        status: ReminderStatus.values[map['status'] as int? ?? 0],
        repeatInterval:
            RepeatInterval.values[map['repeatInterval'] as int? ?? 0],
        docType: map['docType'] != null
            ? ReminderDocType.values[map['docType'] as int]
            : null,
        lastItems: (map['lastItems'] as List?)
                ?.map((e) => ReminderItem.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );
}
