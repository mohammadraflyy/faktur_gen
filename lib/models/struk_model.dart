// The form shows one "Kartu" segment for debit and kredit; see
// paymentSegment.
enum MetodeBayar { tunai, transfer, debit, kredit, qris }

extension MetodeBayarExt on MetodeBayar {
  String get label {
    switch (this) {
      case MetodeBayar.tunai:
        return 'Tunai';
      case MetodeBayar.transfer:
        return 'Transfer';
      case MetodeBayar.debit:
        return 'Kartu Debit';
      case MetodeBayar.kredit:
        return 'Kartu Kredit';
      case MetodeBayar.qris:
        return 'QRIS';
    }
  }
}

class ItemStruk {
  String nama;
  String deskripsi;
  double kuantitas;
  String satuan;
  double hargaSatuan;
  double diskon; // nominal discount per item

  ItemStruk({
    this.nama = '',
    this.deskripsi = '',
    this.kuantitas = 1,
    this.satuan = 'pcs',
    this.hargaSatuan = 0,
    this.diskon = 0,
  });

  double get subtotal => (kuantitas * hargaSatuan) - diskon;
}

class StrukModel {
  // Info Toko
  String namaToko;
  String alamatToko;
  String teleponToko;

  // Info Struk
  String nomorStruk;
  DateTime tanggal;
  String namaKasir;

  // Items
  List<ItemStruk> items;

  // Pembayaran
  double diskon; // nominal global discount
  MetodeBayar metodeBayar;
  double jumlahBayar; // untuk hitung kembalian (tunai)

  String catatan;

  StrukModel({
    this.namaToko = '',
    this.alamatToko = '',
    this.teleponToko = '',
    this.nomorStruk = '',
    DateTime? tanggal,
    this.namaKasir = '',
    List<ItemStruk>? items,
    this.diskon = 0,
    this.metodeBayar = MetodeBayar.tunai,
    this.jumlahBayar = 0,
    this.catatan = '',
  })  : tanggal = tanggal ?? DateTime.now(),
        items = items ?? [ItemStruk()];

  double get subtotal => items.fold(0, (s, i) => s + i.subtotal);
  double get total => subtotal - diskon;
  double get kembalian =>
      metodeBayar == MetodeBayar.tunai && jumlahBayar >= total
          ? jumlahBayar - total
          : 0;
}

/// Change for a cash payment. Negative means the customer is still short;
/// null until an amount has been entered.
double? cashChange({required double total, required double paid}) =>
    paid > 0 ? paid - total : null;

/// Segment highlighted in the receipt form. Debit and kredit share one
/// "Kartu" segment whose value is debit.
MetodeBayar paymentSegment(MetodeBayar m) =>
    m == MetodeBayar.kredit ? MetodeBayar.debit : m;
