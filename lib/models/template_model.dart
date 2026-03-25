class TemplateItem {
  final String nama;
  final String deskripsi;
  final double kuantitas;
  final String satuan;
  final double hargaSatuan;

  TemplateItem({
    required this.nama,
    this.deskripsi = '',
    required this.kuantitas,
    required this.satuan,
    required this.hargaSatuan,
  });

  Map<String, dynamic> toMap() => {
        'nama': nama,
        'deskripsi': deskripsi,
        'kuantitas': kuantitas,
        'satuan': satuan,
        'hargaSatuan': hargaSatuan,
      };

  factory TemplateItem.fromMap(Map<String, dynamic> m) => TemplateItem(
        nama: m['nama'] as String? ?? '',
        deskripsi: m['deskripsi'] as String? ?? '',
        kuantitas: (m['kuantitas'] as num?)?.toDouble() ?? 1,
        satuan: m['satuan'] as String? ?? 'Unit',
        hargaSatuan: (m['hargaSatuan'] as num?)?.toDouble() ?? 0,
      );
}

class TemplateModel {
  final String id;
  String name;
  String namaPembeli;
  String npwpPembeli;
  String alamatPembeli;
  String teleponPembeli;
  String catatan;
  List<TemplateItem> items;

  TemplateModel({
    required this.id,
    required this.name,
    this.namaPembeli = '',
    this.npwpPembeli = '',
    this.alamatPembeli = '',
    this.teleponPembeli = '',
    this.catatan = '',
    this.items = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'namaPembeli': namaPembeli,
        'npwpPembeli': npwpPembeli,
        'alamatPembeli': alamatPembeli,
        'teleponPembeli': teleponPembeli,
        'catatan': catatan,
        'items': items.map((e) => e.toMap()).toList(),
      };

  factory TemplateModel.fromMap(Map<String, dynamic> m) => TemplateModel(
        id: m['id'] as String,
        name: m['name'] as String,
        namaPembeli: m['namaPembeli'] as String? ?? '',
        npwpPembeli: m['npwpPembeli'] as String? ?? '',
        alamatPembeli: m['alamatPembeli'] as String? ?? '',
        teleponPembeli: m['teleponPembeli'] as String? ?? '',
        catatan: m['catatan'] as String? ?? '',
        items: (m['items'] as List?)
                ?.map((e) => TemplateItem.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
