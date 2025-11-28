import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:mila_kru_reguler/models/setoranKru_model.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';

import 'package:mila_kru_reguler/services/premi_harian_kru_service.dart';
import 'package:mila_kru_reguler/services/setoranKru_service.dart';
import 'package:mila_kru_reguler/services/tag_transaksi_service.dart';
import 'package:mila_kru_reguler/services/data_pusher_service.dart';

import 'package:mila_kru_reguler/database/database_helper.dart';

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

  final DatabaseHelper databaseHelper = DatabaseHelper();

  List<Map<String, dynamic>> listPremiHarianKru = [];
  late Future<List<SetoranKru>> setoranKruData;

  bool _isPushingData = false;
  double _uploadProgress = 0.0;

  NumberFormat formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp');
  DateTime? _selectedDate;

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
    List<Map<String, dynamic>> premiKruData =
    await premiHarianKruService.getPremiHarianKruWithKruBis();

    setState(() {
      listPremiHarianKru = premiKruData;
    });

    if (premiKruData.isEmpty) {
      print("Tidak ada data premi harian kru.");
    } else {
      print("Data premi harian kru ditemukan.");
    }
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
      // 1. Push premi harian kru
      await dataPusherService.pushDataPremiHarianKru(
        selectedDate: _selectedDate!,
        onProgress: _updateUploadProgress,
        onSuccess: () {
          _getListPremiKru();
          _refreshSetoranKruData();
        },
      );

      // 2. Load token & idTransaksi
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final int? idBus = prefs.getInt('idBus');
      String? idTransaksi = prefs.getString('idTransaksi');

      if (idTransaksi == null) {
        idTransaksi = "KEUBIS${idBus}${DateTime.now().millisecondsSinceEpoch}";
        prefs.setString('idTransaksi', idTransaksi);
      }

      // 3. Ambil setoran kru yang status N
      final allSetoran = await setoranKruService.getAllSetoran();
      final filtered = allSetoran.where((e) => e.status == "N").toList();

      if (filtered.isEmpty) {
        print("Tidak ada data setoran kru untuk dikirim.");
        return;
      }

      // 4. Siapkan rows
      final rowsList = filtered.map((d) {
        return {
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
        };
      }).toList();

      // 5. Callback update status
      Future<void> updateStatusCallback(String idTransaksi) async {
        for (var s in filtered) {
          try {
            await setoranKruService.updateSetoran(s.copyWith(status: "Y"));
          } catch (e) {
            print("Gagal update status: $e");
          }
        }
      }

      // 6. Kirim API
      final response = await kirimSetoranKruMobile(
        idTransaksi: idTransaksi,
        token: token!,
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

      body: SingleChildScrollView(
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
                              rows: setoranList.map((s) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(s.id?.toString() ?? "-")),
                                    DataCell(Text(_getNamaTagFromList(s.idTagTransaksi, tagList))),
                                    DataCell(Text(s.nilai != null ? formatter.format(s.nilai!) : "-")),
                                    DataCell(Text(s.keterangan ?? "-")),
                                    DataCell(Text(s.status ?? "-")),
                                  ],
                                );
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
          ],
        ),
      ),
    );
  }
}