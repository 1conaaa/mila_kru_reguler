import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:mila_kru_reguler/api/ApiPersenPremiKru..dart';
import 'package:mila_kru_reguler/models/PersenPremiKru.dart';
import 'package:mila_kru_reguler/services/persen_premi_kru_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:mila_kru_reguler/models/setoranKru_model.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';

import 'package:mila_kru_reguler/services/premi_harian_kru_service.dart';
import 'package:mila_kru_reguler/services/setoranKru_service.dart';
import 'package:mila_kru_reguler/services/tag_transaksi_service.dart';
import 'package:mila_kru_reguler/services/data_pusher_service.dart';
import 'package:mila_kru_reguler/services/user_service.dart';

import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class PremiKru extends StatefulWidget {
  @override
  _PremiKruState createState() => _PremiKruState();
}

class _PremiKruState extends State<PremiKru> {
  // Services
  final PremiHarianKruService premiHarianKruService = PremiHarianKruService();
  final SetoranKruService setoranKruService = SetoranKruService();
  final TagTransaksiService tagTransaksiService = TagTransaksiService();
  final DataPusherService dataPusherService = DataPusherService();

  final DatabaseHelper databaseHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> listPremiHarianKru = [];
  late Future<List<SetoranKru>> setoranKruData;

  bool _isPushingData = false;
  double _uploadProgress = 0.0;

  NumberFormat formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp');
  DateTime? _selectedDate;

  get kodeTrayek => null;

  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    setoranKruData = setoranKruService.getAllSetoran();
    _getListPremiKru();
    _loadLastPremiKru();
  }

  //----------------------------------------------------------------------
  // LOAD DATA
  //----------------------------------------------------------------------

  Future<void> _loadLastPremiKru() async {
    await databaseHelper.initDatabase();
    await _getListPremiKru();
    await databaseHelper.closeDatabase();
  }

  Future<void> _getListPremiKru() async {
    print("🔍 Memulai query premi harian kru...");

    List<Map<String, dynamic>> premiKruData =
    await premiHarianKruService.getPremiHarianKruWithKruBis();

    print("📊 Jumlah data hasil query: ${premiKruData.length}");

    if (premiKruData.isEmpty) {
      print("⚠️ Tidak ada data premi harian kru.");
    } else {
      print("✅ Data premi harian kru ditemukan:");

      // Print tiap baris hasil query
      for (int i = 0; i < premiKruData.length; i++) {
        print("➡️ Row ${i + 1}: ${premiKruData[i]}");
      }
    }

    setState(() {
      listPremiHarianKru = premiKruData;
    });
  }


  Future<void> _refreshSetoranKruData() async {
    setState(() {
      setoranKruData = setoranKruService.getAllSetoran();
    });
  }

  //----------------------------------------------------------------------
  // TAG TRANSAKSI
  //----------------------------------------------------------------------

  Future<List<TagTransaksi>> _getAllTagTransaksi() async {
    try {
      return await tagTransaksiService.getAllTagTransaksi();
    } catch (e) {
      print("Error load tag transaksi: $e");
      return [];
    }
  }

  String _getNamaTagFromList(int? idTagTransaksi, List<TagTransaksi> tags) {
    if (idTagTransaksi == null) return "-";

    try {
      final tag = tags.firstWhere(
            (tag) => tag.id == idTagTransaksi,
        orElse: () => TagTransaksi(id: 0, nama: "Tag Tidak Ditemukan", kategoriTransaksi: ""),
      );

      return tag.nama ?? "Tag $idTagTransaksi";
    } catch (_) {
      return "Tag $idTagTransaksi";
    }
  }

  void _updateUploadProgress(double progress) {
    setState(() => _uploadProgress = progress);
  }

  //----------------------------------------------------------------------
  // PUSH DATA
  //----------------------------------------------------------------------

  Future<void> _pushDataPremiHarianKru() async {
    if (_selectedDate == null) {
      _showAlertDialog(context, "Silakan pilih tanggal terlebih dahulu.");
      return;
    }

    setState(() {
      _isPushingData = true;
      _uploadProgress = 0.0;
    });

    try {
      await dataPusherService.pushDataPremiHarianKru(
        selectedDate: _selectedDate!,
        onProgress: _updateUploadProgress,
        onSuccess: () {
          _getListPremiKru();
          _refreshSetoranKruData();
        },
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final String? idTransaksi = prefs.getString('idTransaksi');

      if (token == null || idTransaksi == null || idTransaksi.isEmpty) {
        throw Exception('Token atau ID Transaksi tidak valid.');
      }

      final allSetoran = await setoranKruService.getAllSetoran();
      final filtered = allSetoran.where((e) => e.status == "N").toList();

      if (filtered.isEmpty) {
        print("Tidak ada data setoran kru untuk dikirim.");
        return;
      }

      final rowsList = filtered.map((d) => {
        "tgl_transaksi": d.tglTransaksi,
        "km_pulang": d.kmPulang ?? "",
        "rit": d.rit,
        "no_pol": d.noPol,
        "id_bus": d.idBus,
        "kode_trayek": d.kodeTrayek,
        "id_personil": d.idPersonil,
        "id_group": d.idGroup,
        "jumlah": d.jumlah ?? "",
        "coa": d.coa ?? "",
        "nilai": d.nilai,
        "id_tag_transaksi": d.idTagTransaksi,
        "status": d.status,
        "keterangan": d.keterangan ?? "",
      }).toList();

      Future<void> updateStatusCallback(String idTransaksi) async {
        for (var s in filtered) {
          await setoranKruService.updateSetoran(s.copyWith(status: "Y"));
        }
      }

      final response = await kirimSetoranKruMobile(
        idTransaksi: idTransaksi,
        token: token,
        rows: rowsList,
        files: filtered,
        onSuccessCallback: updateStatusCallback,
      );

      print("Setoran kru berhasil dikirim: $response");
    } catch (e) {
      _showAlertDialog(context, "Gagal push data: $e");
    } finally {
      setState(() {
        _isPushingData = false;
        _uploadProgress = 0.0;
      });
    }
  }

  //----------------------------------------------------------------------
  // MULTIPART API KIRIM SETORAN
  //----------------------------------------------------------------------

  Future<Map<String, dynamic>> kirimSetoranKruMobile({
    required String idTransaksi,
    required String token,
    required List<Map<String, dynamic>> rows,
    required List<SetoranKru> files,
    required Function(String) onSuccessCallback,
  }) async {
    const String apiUrl = "https://apimila.milaberkah.com/api/simpansetorankrumobile";

    try {
      var request = http.MultipartRequest("POST", Uri.parse(apiUrl));
      request.headers["Authorization"] = "Bearer $token";
      request.fields["id_transaksi"] = idTransaksi;

      // Filter hanya status N
      final unsentRows = rows.where((r) => r["status"] == "N").toList();

      if (unsentRows.isEmpty) {
        return {"success": true, "message": "Tidak ada data baru", "skipped": true};
      }

      // Tambahkan id transaksi & cleaning null
      List<Map<String, dynamic>> cleanedRows = [];

      for (var row in unsentRows) {
        Map<String, dynamic> clean = {};
        row.forEach((k, v) {
          if (v != null) clean[k] = v;
        });
        clean["id_transaksi"] = idTransaksi;
        cleanedRows.add(clean);
      }

      request.fields["rows"] = jsonEncode(cleanedRows);

      // FILE ATTACH
      int fileCounter = 0;

      for (int i = 0; i < files.length; i++) {
        final d = files[i];

        if (d.fupload != null && d.fupload!.isNotEmpty) {
          final file = File(d.fupload!);

          if (await file.exists()) {
            final multipartFile = await http.MultipartFile.fromPath(
              "file_name_$i",
              d.fupload!,
            );
            request.files.add(multipartFile);
            fileCounter++;
          }
        }
      }

      var streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
      );

      var response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData["success"] == true) {
        await onSuccessCallback(idTransaksi);
        return responseData;
      }

      throw Exception("Error API: ${response.body}");
    } catch (e) {
      print("Error kirimSetoranKruMobile: $e");
      rethrow;
    }
  }

  //----------------------------------------------------------------------
  // PILIH TANGGAL
  //----------------------------------------------------------------------

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDate: _selectedDate ?? DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  //----------------------------------------------------------------------
  // ALERT DIALOG
  //----------------------------------------------------------------------

  void _showAlertDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Pemberitahuan"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          )
        ],
      ),
    );
  }

  //----------------------------------------------------------------------
  // EXPORT TO PDF (SIMPLE VERSION)
  //----------------------------------------------------------------------
  Future<void> _exportToPDF() async {
    try {
      final setoranList = await setoranKruService.getAllSetoran();
      final tagList = await _getAllTagTransaksi();
      final users = await _userService.getAllUsers();
      final user = users.isNotEmpty ? users.first : null;

      if (setoranList.isEmpty) {
        _showAlertDialog(context, "Tidak ada data setoran kru untuk diekspor.");
        return;
      }

      // Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text("Membuat PDF..."),
            ],
          ),
        ),
      );

      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormat = DateFormat('dd-MM-yyyy HH:mm');
      final fileNameFormat = DateFormat('yyyyMMdd_HHmmss');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            // ===== GROUPING DATA =====
            final Map<String, List<dynamic>> groupedData = {};

            for (var item in setoranList) {
              final key =
                  '${item.noPol}_${item.tglTransaksi}_${item.kodeTrayek}';

              groupedData.putIfAbsent(key, () => []);
              groupedData[key]!.add(item);
            }

            // ===== AMBIL TANGGAL LAPORAN DARI DATA =====
            String tanggalLaporan = "-";
            if (groupedData.isNotEmpty) {
              final firstGroup = groupedData.values.first.first;
              tanggalLaporan = firstGroup.tglTransaksi ?? "-";
              if (tanggalLaporan.length > 10) {
                tanggalLaporan = tanggalLaporan.substring(0, 10);
              }
            }

            return [
              // ================= HEADER =================
              pw.Text(
                'LAPORAN SETORAN KRU',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),

              // ===== DATA KRU / BUS =====
              if (user != null) ...[
                _pdfRow("No Pol", user.noPol ?? "-"),
                _pdfRow("Nama Kru", user.namaLengkap ?? "-"),
                _pdfRow("Trayek", user.namaTrayek ?? "-"),
                _pdfRow("Jenis Trayek", user.jenisTrayek ?? "-"),
                _pdfRow("Kelas Bus", user.kelasBus ?? "-"),
              ],

              // ===== TANGGAL OPERASIONAL =====
              _pdfRow("Tanggal", tanggalLaporan),

              pw.Divider(),

              // ================= LIST GROUP =================
              ...groupedData.entries.map((entry) {
                final items = entry.value;
                final first = items.first;

                String tgl = first.tglTransaksi ?? '-';
                if (tgl.length > 10) tgl = tgl.substring(0, 10);

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [

                      // ===== LIST TAG TRANSAKSI =====
                      ...items.map((data) {
                        final bool isPremiAtas =
                            data.idTagTransaksi == 27;

                        final String namaTag = isPremiAtas
                            ? "Premi Atas"
                            : _getNamaTagFromList(
                          data.idTagTransaksi,
                          tagList,
                        );

                        return pw.Padding(
                          padding:
                          const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Row(
                            mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                "- $namaTag",
                                style:
                                const pw.TextStyle(fontSize: 9),
                              ),
                              pw.Text(
                                formatter.format(data.nilai ?? 0),
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }).toList(),

              pw.Divider(),
              pw.Text(
                'Dibuat oleh: Aplikasi Mila KRU Reguler',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'setoran_kru_${fileNameFormat.format(now)}.pdf';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      Navigator.pop(context);
      await _showPDFSuccessDialog(filePath, fileName);
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showAlertDialog(context, "Error membuat PDF: $e");
    }
  }

  pw.Widget _pdfRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.Text(": ", style: const pw.TextStyle(fontSize: 9)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPDFSuccessDialog(String filePath, String fileName) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("PDF Berhasil Dibuat"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "File telah disimpan sebagai:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              fileName,
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
            SizedBox(height: 10),
            Text(
              "Lokasi:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              filePath,
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            SizedBox(height: 15),
            Text(
              "Pilih aksi:",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_open, size: 18),
                SizedBox(width: 5),
                Text("Buka File"),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, size: 18),
                SizedBox(width: 5),
                Text("Download Ulang"),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 0),
            child: Text("Tutup"),
          ),
        ],
      ),
    );

    switch (result) {
      case 1:
      // Buka file dengan aplikasi default
        await OpenFile.open(filePath);
        break;
      case 2:
      // Download ulang ke folder Downloads jika ada
        await _saveToDownloads(filePath, fileName);
        break;
    }
  }

  Future<void> _saveToDownloads(String sourcePath, String fileName) async {
    try {
      // Coba akses folder Downloads
      final downloadsDirectory = await getDownloadsDirectory();

      if (downloadsDirectory != null) {
        final destPath = '${downloadsDirectory.path}/$fileName';
        final sourceFile = File(sourcePath);
        final destFile = File(destPath);

        await sourceFile.copy(destFile.path);

        _showAlertDialog(
          context,
          "File berhasil disalin ke folder Downloads:\n$fileName",
        );

        // Buka file setelah disalin
        await OpenFile.open(destPath);
      } else {
        // Fallback ke Documents directory
        final documents = await getApplicationDocumentsDirectory();
        final destPath = '${documents.path}/$fileName';
        final sourceFile = File(sourcePath);
        final destFile = File(destPath);

        await sourceFile.copy(destFile.path);

        _showAlertDialog(
          context,
          "File disalin ke:\n$destPath",
        );
      }
    } catch (e) {
      _showAlertDialog(context, "Error menyimpan file: $e");
    }
  }

  //----------------------------------------------------------------------
  // BUILD UI
  //----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isPushingData) {
      return Stack(
        children: [
          Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: _uploadProgress),
                  SizedBox(height: 16),
                  Text("Sedang mengirim data..."),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Data Premi Disetor Harian Kru"),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            tooltip: "Export to PDF",
            onPressed: _exportToPDF,
          ),
          IconButton(
            icon: Icon(Icons.calendar_today),
            tooltip: "Pilih Tanggal",
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: Icon(Icons.send),
            tooltip: "Kirim Data",
            onPressed: _pushDataPremiHarianKru,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: _refreshSetoranKruData,
          ),
        ],
      ),

      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ------------------- TABLE PREMI KRU -------------------
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Kru")),
                    DataColumn(label: Text("%")),
                    DataColumn(label: Text("Nominal"), numeric: true),
                    DataColumn(label: Text("Status")),
                  ],
                  rows: listPremiHarianKru.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(Text(item["nama_kru"].toString())),
                        DataCell(Text(item["persen_premi"].toString())),
                        DataCell(Text(formatter.format(item["nominal_premi_disetor"]))),
                        DataCell(Text(item["status"].toString())),
                      ],
                    );
                  }).toList(),
                ),
              ),

              SizedBox(height: 30),

              // ------------------- SETORAN KRU -------------------
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Data Setoran Kru",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),

                    FutureBuilder(
                      future: setoranKruData,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Text("Tidak ada data setoran kru");
                        }

                        List<SetoranKru> setoranList = snapshot.data!;

                        return FutureBuilder<List<TagTransaksi>>(
                          future: _getAllTagTransaksi(),
                          builder: (context, tagSnap) {
                            if (!tagSnap.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }

                            final tagList = tagSnap.data!;

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text("ID")),
                                  DataColumn(label: Text("Nama Tag")),
                                  DataColumn(label: Text("Nilai"), numeric: true),
                                  DataColumn(label: Text("Keterangan")),
                                  DataColumn(label: Text("Status")),
                                ],
                                rows: setoranList.expand((s) {
                                  List<DataRow> rows = [];

                                  bool isPremiAtas = s.idTagTransaksi == 27;
                                  bool isTag61 = s.idTagTransaksi == 61;
                                  String namaTag = isPremiAtas
                                      ? "Premi Atas"
                                      : _getNamaTagFromList(s.idTagTransaksi, tagList);

                                  // ====== ROW UTAMA ======
                                  rows.add(
                                    DataRow(
                                      cells: [
                                        // ID Cell
                                        DataCell(Text(
                                          s.id?.toString() ?? "-",
                                          style: isTag61
                                              ? TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                          )
                                              : null,
                                        )),

                                        // Nama Tag Cell - BOLD & BESAR untuk ID 61
                                        DataCell(Text(
                                          namaTag,
                                          style: isTag61
                                              ? TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red[800],
                                          )
                                              : null,
                                        )),

                                        // Nilai Cell - BOLD & BESAR untuk ID 61
                                        DataCell(Text(
                                          s.nilai != null ? formatter.format(s.nilai) : "-",
                                          style: isTag61
                                              ? TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[800],
                                          )
                                              : TextStyle(
                                            fontWeight: isTag61 ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        )),

                                        // Keterangan Cell
                                        DataCell(Text(
                                          s.keterangan ?? "-",
                                          style: isTag61
                                              ? TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            fontStyle: FontStyle.italic,
                                          )
                                              : null,
                                        )),

                                        // Status Cell - BOLD untuk ID 61
                                        DataCell(
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black, // background selalu hitam
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.black, // border hitam
                                                width: 1,            // bisa disesuaikan
                                              ),
                                            ),
                                            child: Text(
                                              s.status ?? "-",      // tetap tampil status atau "-"
                                              style: TextStyle(
                                                fontSize: 12,       // ukuran font standar
                                                fontWeight: FontWeight.normal, // font biasa
                                                color: Colors.white, // teks putih agar terlihat di background hitam
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  // ====== JIKA PREMI ATAS, TAMBAHKAN DETAIL PEMBAGIAN PER KRU ======
                                  if (isPremiAtas && listPremiHarianKru.isNotEmpty) {
                                    // Header
                                    rows.add(
                                      const DataRow(
                                        cells: [
                                          DataCell(Text("")),
                                          DataCell(Text("🔽 Pembagian Premi Atas")),
                                          DataCell(Text("")),
                                          DataCell(Text("")),
                                          DataCell(Text("")),
                                        ],
                                      ),
                                    );

                                    rows.add(
                                      DataRow(
                                        cells: [
                                          const DataCell(Text("")),

                                          /// === DATA CELL UTAMA ===
                                          DataCell(
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width * 0.6,
                                              child: FutureBuilder<List<ListPersenPremiKru>>(
                                                future: PersenPremiKruService.instance.getByKodeTrayek(
                                                  s.kodeTrayek ?? "",
                                                  idJenisPremi: 1,
                                                  onDataFetchedFromApi: (apiSuccess) {
                                                    if (apiSuccess && mounted) {
                                                      Future.delayed(
                                                        const Duration(milliseconds: 200),
                                                            () => setState(() {}),
                                                      );
                                                    }
                                                  },
                                                ),
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                                    return Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: const [
                                                        SizedBox(
                                                          width: 14,
                                                          height: 14,
                                                          child: CircularProgressIndicator(strokeWidth: 2),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text("Memuat data...", style: TextStyle(fontSize: 12)),
                                                      ],
                                                    );
                                                  }

                                                  if (snapshot.hasError) {
                                                    return Text(
                                                      "Error: ${snapshot.error}",
                                                      style: const TextStyle(fontSize: 12),
                                                    );
                                                  }

                                                  final persenList = snapshot.data ?? [];

                                                  if (persenList.isEmpty) {
                                                    return Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text("⚠️ Data tidak ditemukan", style: TextStyle(fontSize: 12)),
                                                        const SizedBox(height: 4),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            textStyle: const TextStyle(fontSize: 11),
                                                          ),
                                                          onPressed: () async {
                                                            final prefs = await SharedPreferences.getInstance();
                                                            final token = prefs.getString('token');

                                                            if (token != null) {
                                                              await ApiHelperPersenPremiKru
                                                                  .requestListPersenPremiAPI(token, s.kodeTrayek);
                                                              if (mounted) setState(() {});
                                                            }
                                                          },
                                                          child: const Text("Ambil Data"),
                                                        ),
                                                      ],
                                                    );
                                                  }

                                                  final totalPersen = persenList.fold<double>(
                                                    0,
                                                        (sum, item) => sum + item.nilaiAsDouble,
                                                  );

                                                  /// === LIST PEMBAGIAN (NO OVERFLOW) ===
                                                  return Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: persenList.map((p) {
                                                      final persen = p.nilaiAsDouble;
                                                      final nominal = totalPersen > 0
                                                          ? (persen / totalPersen) * (s.nilai ?? 0)
                                                          : 0;

                                                      final namaKru =
                                                          listPremiHarianKru.firstWhere(
                                                                (k) => k["id_posisi_kru"] == p.idPosisiKru,
                                                            orElse: () => {"nama_kru": "Kru #${p.idPosisiKru}"},
                                                          )["nama_kru"] ??
                                                              "Kru #${p.idPosisiKru}";

                                                      return Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    namaKru,
                                                                    maxLines: 1,
                                                                    overflow: TextOverflow.ellipsis,
                                                                    style: const TextStyle(fontSize: 12),
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 6),
                                                                Text(
                                                                  formatter.format(nominal),
                                                                  style: const TextStyle(
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: Colors.green[50],
                                                                borderRadius: BorderRadius.circular(3),
                                                              ),
                                                              child: Text(
                                                                "${persen.toStringAsFixed(1)}%",
                                                                style: const TextStyle(fontSize: 10),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }).toList(),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),

                                          const DataCell(Text("")),
                                          const DataCell(Text("")),
                                          const DataCell(Text("")),
                                        ],
                                      ),
                                    );
                                  }

                                  return rows;
                                }).toList(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Padding bawah untuk memberi jarak dengan navbar
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}