class UserData {
  final int idUser;
  final int idGroup;
  final int idCompany;
  final int idGarasi;
  final int idBus;
  final String noPol;
  final String namaTrayek;
  final String jenisTrayek;
  final String kelasBus;
  final String keydataPremiextra;
  final String premiExtra;
  final String keydataPremikru;
  final String persenPremikru;
  final String coaPendapatanBus;
  final String coaPengeluaranBus;
  final String coaUtangPremi;
  final String noKontak;

  UserData({
    required this.idUser,
    required this.idGroup,
    required this.idCompany,
    required this.idGarasi,
    required this.idBus,
    required this.noPol,
    required this.namaTrayek,
    required this.jenisTrayek,
    required this.kelasBus,
    required this.keydataPremiextra,
    required this.premiExtra,
    required this.keydataPremikru,
    required this.persenPremikru,
    required this.coaPendapatanBus,
    required this.coaPengeluaranBus,
    required this.coaUtangPremi,
    required this.noKontak,
  });

  // Factory constructor untuk membuat UserData dari Map
  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      idUser: map['id_user'] ?? 0,
      idGroup: map['id_group'] ?? 0,
      idCompany: map['id_company'] ?? 0,
      idGarasi: map['id_garasi'] ?? 0,
      idBus: map['id_bus'] ?? 0,
      noPol: map['no_pol'] ?? '',
      namaTrayek: map['nama_trayek'] ?? '',
      jenisTrayek: map['jenis_trayek'] ?? '',
      kelasBus: map['kelas_bus'] ?? '',
      keydataPremiextra: map['keydataPremiextra'] ?? '',
      premiExtra: map['premiExtra'] ?? '',
      keydataPremikru: map['keydataPremikru'] ?? '',
      persenPremikru: map['persenPremikru'] ?? '',
      coaPendapatanBus: map['coaPendapatanBus'] ?? '',
      coaPengeluaranBus: map['coaPengeluaranBus'] ?? '',
      coaUtangPremi: map['coaUtangPremi'] ?? '',
      noKontak: map['noKontak'] ?? '',
    );
  }

  // Method untuk membuat UserData kosong
  static UserData empty() {
    return UserData(
      idUser: 0,
      idGroup: 0,
      idCompany: 0,
      idGarasi: 0,
      idBus: 0,
      noPol: '',
      namaTrayek: '',
      jenisTrayek: '',
      kelasBus: '',
      keydataPremiextra: '',
      premiExtra: '0',
      keydataPremikru: '',
      persenPremikru: '0',
      coaPendapatanBus: '',
      coaPengeluaranBus: '',
      coaUtangPremi: '',
      noKontak: '',
    );
  }

  @override
  String toString() {
    return 'UserData{idUser: $idUser, namaTrayek: $namaTrayek, jenisTrayek: $jenisTrayek, premiExtra: $premiExtra, persenPremikru: $persenPremikru, coaPendapatanBus: $coaPendapatanBus, coaPengeluaranBus: $coaPengeluaranBus, coaUtangPremi: $coaUtangPremi}';
  }
}