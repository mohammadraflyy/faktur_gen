import 'settings_model.dart';

class ItemFaktur {
  String namaBarang;
  String deskripsi;
  double kuantitas;
  String satuan;
  double hargaSatuan;

  ItemFaktur({
    this.namaBarang = '',
    this.deskripsi = '',
    this.kuantitas = 1,
    this.satuan = 'Unit',
    this.hargaSatuan = 0,
  });

  double get jumlah => kuantitas * hargaSatuan;
}

class FakturModel {
  String nomorFaktur;
  DateTime tanggal;
  DateTime? jatuhTempo;

  // Penjual (dari settings)
  String namaPenjual;
  String npwpPenjual;
  String alamatPenjual;
  String teleponPenjual;
  String emailPenjual;
  String websitePenjual;

  // Pembeli
  String namaPembeli;
  String npwpPembeli;
  String alamatPembeli;
  String teleponPembeli;

  List<ItemFaktur> items;
  String catatan;
  List<BankAccount> bankAccounts;

  // Tax & Currency
  double taxRate; // percentage, e.g. 11
  String currency;

  FakturModel({
    this.nomorFaktur = '',
    DateTime? tanggal,
    this.jatuhTempo,
    this.namaPenjual = '',
    this.npwpPenjual = '',
    this.alamatPenjual = '',
    this.teleponPenjual = '',
    this.emailPenjual = '',
    this.websitePenjual = '',
    this.namaPembeli = '',
    this.npwpPembeli = '',
    this.alamatPembeli = '',
    this.teleponPembeli = '',
    List<ItemFaktur>? items,
    this.catatan = '',
    List<BankAccount>? bankAccounts,
    this.taxRate = 11,
    this.currency = 'IDR',
  })  : tanggal = tanggal ?? DateTime.now(),
        items = items ?? [ItemFaktur()],
        bankAccounts = bankAccounts ?? [];

  double get totalDpp => items.fold(0, (sum, item) => sum + item.jumlah);
  double get totalPpn => totalDpp * (taxRate / 100);
  double get totalTagihan => totalDpp + totalPpn;
}
