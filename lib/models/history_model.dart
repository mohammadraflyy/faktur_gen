enum DocType { invoice, struk }

enum PaymentStatus { unpaid, paid }

class HistoryItem {
  final String nama;
  final String deskripsi;
  final double kuantitas;
  final String satuan;
  final double hargaSatuan;
  final double subtotal;
  final double diskon;

  HistoryItem({
    required this.nama,
    this.deskripsi = '',
    required this.kuantitas,
    required this.satuan,
    required this.hargaSatuan,
    required this.subtotal,
    this.diskon = 0,
  });

  Map<String, dynamic> toMap() => {
        'nama': nama,
        'deskripsi': deskripsi,
        'kuantitas': kuantitas,
        'satuan': satuan,
        'hargaSatuan': hargaSatuan,
        'subtotal': subtotal,
        'diskon': diskon,
      };

  factory HistoryItem.fromMap(Map<String, dynamic> map) => HistoryItem(
        nama: map['nama'] as String? ?? '',
        deskripsi: map['deskripsi'] as String? ?? '',
        kuantitas: (map['kuantitas'] as num?)?.toDouble() ?? 0,
        satuan: map['satuan'] as String? ?? '',
        hargaSatuan: (map['hargaSatuan'] as num?)?.toDouble() ?? 0,
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
        diskon: (map['diskon'] as num?)?.toDouble() ?? 0,
      );
}

class HistoryEntry {
  final String id;
  final DocType docType;
  final String nomorDokumen;
  final String namaKlien;
  final double totalAmount;
  final DateTime tanggalDokumen;
  final DateTime createdAt;
  PaymentStatus paymentStatus;

  // Detail fields
  final List<HistoryItem> items;
  final String catatan;

  // Invoice-specific
  final String? namaPenjual;
  final String? alamatPembeli;
  final String? npwpPembeli;
  final String? teleponPembeli;
  final double? totalDpp;
  final double? totalPpn;
  final DateTime? jatuhTempo;
  final double? taxRate;
  final String? currency;

  // Struk-specific
  final String? namaToko;
  final String? alamatToko;
  final String? namaKasir;
  final double? diskon;
  final String? metodeBayar;
  final double? jumlahBayar;
  final double? kembalian;

  HistoryEntry({
    required this.id,
    required this.docType,
    required this.nomorDokumen,
    required this.namaKlien,
    required this.totalAmount,
    required this.tanggalDokumen,
    required this.createdAt,
    this.paymentStatus = PaymentStatus.unpaid,
    this.items = const [],
    this.catatan = '',
    this.namaPenjual,
    this.alamatPembeli,
    this.npwpPembeli,
    this.teleponPembeli,
    this.totalDpp,
    this.totalPpn,
    this.jatuhTempo,
    this.taxRate,
    this.currency,
    this.namaToko,
    this.alamatToko,
    this.namaKasir,
    this.diskon,
    this.metodeBayar,
    this.jumlahBayar,
    this.kembalian,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'docType': docType.index,
        'nomorDokumen': nomorDokumen,
        'namaKlien': namaKlien,
        'totalAmount': totalAmount,
        'tanggalDokumen': tanggalDokumen.millisecondsSinceEpoch,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'paymentStatus': paymentStatus.index,
        'items': items.map((e) => e.toMap()).toList(),
        'catatan': catatan,
        'namaPenjual': namaPenjual,
        'alamatPembeli': alamatPembeli,
        'npwpPembeli': npwpPembeli,
        'teleponPembeli': teleponPembeli,
        'totalDpp': totalDpp,
        'totalPpn': totalPpn,
        'jatuhTempo': jatuhTempo?.millisecondsSinceEpoch,
        'taxRate': taxRate,
        'currency': currency,
        'namaToko': namaToko,
        'alamatToko': alamatToko,
        'namaKasir': namaKasir,
        'diskon': diskon,
        'metodeBayar': metodeBayar,
        'jumlahBayar': jumlahBayar,
        'kembalian': kembalian,
      };

  factory HistoryEntry.fromMap(Map<String, dynamic> map) => HistoryEntry(
        id: map['id'] as String,
        docType: DocType.values[map['docType'] as int],
        nomorDokumen: map['nomorDokumen'] as String,
        namaKlien: map['namaKlien'] as String? ?? '',
        totalAmount: (map['totalAmount'] as num).toDouble(),
        tanggalDokumen:
            DateTime.fromMillisecondsSinceEpoch(map['tanggalDokumen'] as int),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        paymentStatus: map['paymentStatus'] != null
            ? PaymentStatus.values[map['paymentStatus'] as int]
            : PaymentStatus.unpaid,
        items: (map['items'] as List?)
                ?.map((e) => HistoryItem.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        catatan: map['catatan'] as String? ?? '',
        namaPenjual: map['namaPenjual'] as String?,
        alamatPembeli: map['alamatPembeli'] as String?,
        npwpPembeli: map['npwpPembeli'] as String?,
        teleponPembeli: map['teleponPembeli'] as String?,
        totalDpp: (map['totalDpp'] as num?)?.toDouble(),
        totalPpn: (map['totalPpn'] as num?)?.toDouble(),
        jatuhTempo: map['jatuhTempo'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['jatuhTempo'] as int)
            : null,
        taxRate: (map['taxRate'] as num?)?.toDouble(),
        currency: map['currency'] as String?,
        namaToko: map['namaToko'] as String?,
        alamatToko: map['alamatToko'] as String?,
        namaKasir: map['namaKasir'] as String?,
        diskon: (map['diskon'] as num?)?.toDouble(),
        metodeBayar: map['metodeBayar'] as String?,
        jumlahBayar: (map['jumlahBayar'] as num?)?.toDouble(),
        kembalian: (map['kembalian'] as num?)?.toDouble(),
      );
}
