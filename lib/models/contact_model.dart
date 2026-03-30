class ContactModel {
  final String id;
  String nama;
  String npwp;
  String alamat;
  String telepon;
  String clientCode;

  ContactModel({
    required this.id,
    this.nama = '',
    this.npwp = '',
    this.alamat = '',
    this.telepon = '',
    this.clientCode = '',
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
        'clientCode': clientCode,
      };

  factory ContactModel.fromMap(Map<String, dynamic> map) => ContactModel(
        id: map['id'] as String? ?? '',
        nama: map['nama'] as String? ?? '',
        npwp: map['npwp'] as String? ?? '',
        alamat: map['alamat'] as String? ?? '',
        telepon: map['telepon'] as String? ?? '',
        clientCode: map['clientCode'] as String? ?? '',
      );
}
