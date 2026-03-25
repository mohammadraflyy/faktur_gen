class ContactModel {
  final String id;
  String nama;
  String npwp;
  String alamat;
  String telepon;

  ContactModel({
    required this.id,
    this.nama = '',
    this.npwp = '',
    this.alamat = '',
    this.telepon = '',
  });

  bool get isEmpty => nama.trim().isEmpty;

  /// Cocokkan berdasarkan nama (case-insensitive).
  bool matchesName(String name) =>
      nama.trim().toLowerCase() == name.trim().toLowerCase();

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'npwp': npwp,
        'alamat': alamat,
        'telepon': telepon,
      };

  factory ContactModel.fromMap(Map<String, dynamic> map) => ContactModel(
        id: map['id'] as String? ?? '',
        nama: map['nama'] as String? ?? '',
        npwp: map['npwp'] as String? ?? '',
        alamat: map['alamat'] as String? ?? '',
        telepon: map['telepon'] as String? ?? '',
      );
}
