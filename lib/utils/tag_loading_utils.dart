import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/models/user.dart';
import 'package:mila_kru_reguler/services/user_service.dart';
import 'package:mila_kru_reguler/services/tag_transaksi_service.dart';

class TagLoadingUtils {
  static const Set<String> _trayekTanpaBiayaTol = {
    '3471351001',
    '3471351002',
    '3471352901',
  };

  static List<TagTransaksi> filterTagByTrayek({
    required List<TagTransaksi> tags,
    required User userData,
  }) {
    print('=== [DEBUG] START CALCULATION ===');
    print('Kelas Bus: ${userData.kelasBus}');
    print('Jenis Trayek: ${userData.jenisTrayek}');
    print('Kode Trayek: ${userData.kodeTrayek}');
    print('Nama Trayek: ${userData.namaTrayek}');
    // 🔕 Sembunyikan Biaya Tol (ID 15) untuk trayek tertentu
    if (_trayekTanpaBiayaTol.contains(userData.kodeTrayek)) {
      return tags.where((tag) => tag.id != 15).toList();
    }

    return tags;
  }

  static Future<Map<String, List<TagTransaksi>>> loadTagTransactions({
    required UserService userService,
    required TagTransaksiService tagTransaksiService,
  }) async {
    final users = await userService.getUsersRaw();
    if (users.isEmpty) {
      return {
        'pendapatan': [],
        'pengeluaran': [],
        'premi': [],
        'bersihSetoran': [],
      };
    }

    final firstUser = users.first;

    // 🔹 BUAT OBJECT USER (WAJIB UNTUK FILTER)
    final User userData = User.fromMap(firstUser);

    final String? tagPendapatanStr =
    firstUser['tag_transaksi_pendapatan']?.toString();
    final String? tagPengeluaranStr =
    firstUser['tag_transaksi_pengeluaran']?.toString();

    if ((tagPendapatanStr == null || tagPendapatanStr.isEmpty) &&
        (tagPengeluaranStr == null || tagPengeluaranStr.isEmpty)) {
      return {
        'pendapatan': [],
        'pengeluaran': [],
        'premi': [],
        'bersihSetoran': [],
      };
    }

    List<int> idPendapatan = tagPendapatanStr
        ?.split(',')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((id) => id > 0)
        .toList() ??
        [];

    List<int> idPengeluaran = tagPengeluaranStr
        ?.split(',')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((id) => id > 0)
        .toList() ??
        [];

    final List<int> allIds = {...idPendapatan, ...idPengeluaran}.toList();
    if (allIds.isEmpty) {
      return {
        'pendapatan': [],
        'pengeluaran': [],
        'premi': [],
        'bersihSetoran': [],
      };
    }

    final allTags = await tagTransaksiService.getTagTransaksiByIds(allIds);

    List<TagTransaksi> tagPendapatan = [];
    List<TagTransaksi> tagPengeluaran = [];
    List<TagTransaksi> tagPremi = [];
    List<TagTransaksi> tagBersihSetoran = [];

    for (final tag in allTags) {
      int kategori =
          int.tryParse(tag.kategoriTransaksi?.toString() ?? '2') ?? 2;

      switch (kategori) {
        case 1:
          tagPendapatan.add(tag);
          break;
        case 2:
          tagPengeluaran.add(tag);
          break;
        case 3:
          tagPremi.add(tag);
          break;
        case 4:
          tagBersihSetoran.add(tag);
          break;
        default:
          tagPengeluaran.add(tag);
      }
    }

    // =====================================================
    // 🔕 FILTER TAG BERDASARKAN TRAYEK (FIX UTAMA)
    // =====================================================
    tagPengeluaran = filterTagByTrayek(
      tags: tagPengeluaran,
      userData: userData,
    );

    return {
      'pendapatan': tagPendapatan,
      'pengeluaran': tagPengeluaran, // ⬅️ SUDAH DIFILTER
      'premi': tagPremi,
      'bersihSetoran': tagBersihSetoran,
    };
  }


  // ⬇️ INI YANG MENGGANTIKAN FILTER DI UI
  static List<TagTransaksi> buildVisibleTabs({
    required List<TagTransaksi> pendapatan,
    required List<TagTransaksi> pengeluaran,
    required List<TagTransaksi> premi,
    required List<TagTransaksi> bersihSetoran,
    required String kelasLayanan,
  }) {
    final List<TagTransaksi> result = [];

    // 1️⃣ TAB PENDAPATAN (WAJIB)
    result.addAll(pendapatan);

    // 2️⃣ TAB PENGELUARAN (WAJIB)
    result.addAll(pengeluaran);

    // 3️⃣ TAB PREMI (KONDISIONAL)
    if (_showPremi(kelasLayanan)) {
      result.addAll(premi);
    }

    // 4️⃣ TAB BERSIH / SETORAN (OPSIONAL)
    if (bersihSetoran.isNotEmpty) {
      result.addAll(bersihSetoran);
    }

    return result;
  }

  static bool _showPremi(String kelasLayanan) {
    // contoh logika sesuai kasus kamu
    return kelasLayanan.contains('extra') ||
        kelasLayanan.contains('premium');
  }
}