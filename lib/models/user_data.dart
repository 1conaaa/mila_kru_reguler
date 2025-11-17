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
  });

  @override
  String toString() {
    return 'UserData{idUser: $idUser, namaTrayek: $namaTrayek, jenisTrayek: $jenisTrayek, premiExtra: $premiExtra, persenPremikru: $persenPremikru}';
  }
}