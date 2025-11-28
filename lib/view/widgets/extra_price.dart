double hitungPenambahanHarga({
  required double jarakAwal,
  required double selisihJarak,
  required String jenisTrayek,
  required String kelasBus,
  required String namaTrayek,
}) {
  // Jika jarakAwal tidak valid → tidak ada tambahan harga
  if (jarakAwal == 0) return 0;

  double tambahan = 0;

  switch (kelasBus) {
    case 'Ekonomi':
      switch (jenisTrayek) {
        case 'AKAP':
          switch (namaTrayek) {
            case 'YOGYAKARTA - BANYUWANGI':
            case 'BANYUWANGI - YOGYAKARTA':
            // Hanya trayek ini yang memakai pola tambahan harga
              if (selisihJarak >= 550)
                tambahan = 13000;
              else if (selisihJarak >= 500)
                tambahan = 11000;
              else if (selisihJarak >= 450)
                tambahan = 14000;
              else if (selisihJarak >= 400)
                tambahan = 10000;
              else if (selisihJarak >= 350)
                tambahan = 14000;
              else if (selisihJarak >= 300)
                tambahan = 13000;
              else if (selisihJarak >= 200)
                tambahan = 12000;
              else if (selisihJarak >= 150)
                tambahan = 8000;
              else if (selisihJarak >= 100)
                tambahan = 9000;
              else if (selisihJarak >= 50)
                tambahan = 11000;
              else if (selisihJarak >= 0)
                tambahan = 7000;

              break;

            default:
            // Trayek lain di bawah Ekonomi–AKAP → tidak ada tambahan harga
              tambahan = 0;
          }
          break;

        default:
        // Jenis trayek lain → tidak ada tambahan harga
          tambahan = 0;
      }
      break;

    default:
    // Kelas bus lain → tidak ada tambahan harga
      tambahan = 0;
  }

  return tambahan;
}
