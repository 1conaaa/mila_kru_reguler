class TagTransaksi {
  final int id;
  final String? kategoriTransaksi;
  final String? nama;

  TagTransaksi({
    required this.id,
    this.kategoriTransaksi,
    this.nama,
  });

  /// Factory untuk parsing JSON API
  factory TagTransaksi.fromJson(Map<String, dynamic> json) {
    return TagTransaksi(
      id: json['id'],
      kategoriTransaksi: json['kategori_transaksi']?.toString(),
      nama: json['nama']?.toString(),
    );
  }

  /// Factory untuk parsing Map dari database
  factory TagTransaksi.fromMap(Map<String, dynamic> map) {
    return TagTransaksi(
      id: map['id'],
      kategoriTransaksi: map['kategori_transaksi']?.toString(),
      nama: map['nama']?.toString(),
    );
  }

  /// Convert ke Map (untuk database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kategori_transaksi': kategoriTransaksi,
      'nama': nama,
    };
  }
}
