class CatalogItem {
  final String id;
  String nama;
  String deskripsi;
  String satuan;
  double hargaSatuan;

  CatalogItem({
    required this.id,
    this.nama = '',
    this.deskripsi = '',
    this.satuan = 'Unit',
    this.hargaSatuan = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'deskripsi': deskripsi,
        'satuan': satuan,
        'hargaSatuan': hargaSatuan,
      };

  factory CatalogItem.fromMap(Map<String, dynamic> m) => CatalogItem(
        id: m['id'] as String,
        nama: m['nama'] as String? ?? '',
        deskripsi: m['deskripsi'] as String? ?? '',
        satuan: m['satuan'] as String? ?? 'Unit',
        hargaSatuan: (m['hargaSatuan'] as num?)?.toDouble() ?? 0,
      );
}
