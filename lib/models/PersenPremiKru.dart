// models/PersenPremiKru.dart

class ListPersenPremiKru {
  int? id;
  String? kodeTrayek;
  int? idJenisPremi;
  int? idPosisiKru;
  dynamic nilai; // Bisa String, int, atau double
  String? aktif;

  ListPersenPremiKru({
    this.id,
    this.kodeTrayek,
    this.idJenisPremi,
    this.idPosisiKru,
    this.nilai,
    this.aktif,
  });

  // ================================
  // 1️⃣ Factory utama untuk database/local
  // ================================
  factory ListPersenPremiKru.fromMap(Map<String, dynamic> map) {
    return ListPersenPremiKru(
      id: _parseInt(map['id']),
      kodeTrayek: map['kode_trayek']?.toString(),
      idJenisPremi: _parseInt(map['id_jenis_premi']),
      idPosisiKru: _parseInt(map['id_posisi_kru']),
      nilai: map['nilai'],
      aktif: map['aktif']?.toString(),
    );
  }

  // ================================
  // 2️⃣ Factory khusus parsing API
  // ================================
  factory ListPersenPremiKru.fromApiResponse(Map<String, dynamic> map) {
    try {
      return ListPersenPremiKru(
        id: _parseInt(map['id']),
        kodeTrayek: map['kode_trayek']?.toString(),
        idJenisPremi: _parseInt(map['id_jenis_premi']),
        idPosisiKru: _parseInt(map['id_posisi_kru']),
        nilai: map['nilai'], // flexible
        aktif: map['aktif']?.toString(),
      );
    } catch (e) {
      print("ERROR parsing fromApiResponse: $e → map=$map");
      return ListPersenPremiKru();
    }
  }

  // ================================
  // 3️⃣ To Map (untuk simpan ke DB)
  // ================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode_trayek': kodeTrayek,
      'id_jenis_premi': idJenisPremi,
      'id_posisi_kru': idPosisiKru,
      'nilai': nilai?.toString(),
      'aktif': aktif,
    };
  }

  // ================================
  // 4️⃣ Helper parsing nilai
  // ================================
  double get nilaiAsDouble {
    try {
      if (nilai == null) return 0;
      if (nilai is num) return (nilai as num).toDouble();
      return double.tryParse(nilai.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ================================
  // 5️⃣ Helper global parse int aman
  // ================================
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
