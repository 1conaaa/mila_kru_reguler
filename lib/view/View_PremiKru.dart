import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:mila_kru_reguler/models/setoranKru_model.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/services/penjualan_tiket_service.dart';
import 'package:mila_kru_reguler/services/premi_harian_kru_service.dart';
import 'package:mila_kru_reguler/services/setoranKru_service.dart';
import 'package:mila_kru_reguler/services/tag_transaksi_service.dart';
import 'package:mila_kru_reguler/services/data_pusher_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';

class PremiKru extends StatefulWidget {
  @override
  _PremiKruState createState() => _PremiKruState();
}

class _PremiKruState extends State<PremiKru> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  final PremiHarianKruService premiHarianKruService = PremiHarianKruService();
  final SetoranKruService setoranKruService = SetoranKruService();
  final TagTransaksiService tagTransaksiService = TagTransaksiService();
  final DataPusherService dataPusherService = DataPusherService();

  List<Map<String, dynamic>> listPremiHarianKru = [];
  late Future<List<SetoranKru>> setoranKruData;
  bool _isPushingData = false;
  double _pushDataProgress = 0.0;
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

  // Method untuk mendapatkan semua data tag transaksi
  Future<List<TagTransaksi>> _getAllTagTransaksi() async {
    try {
      return await tagTransaksiService.getAllTagTransaksi();
    } catch (e) {
      print('Error getting tag transaksi: $e');
      return [];
    }
  }

  // Method untuk mendapatkan nama tag dari list berdasarkan idTagTransaksi
  String _getNamaTagFromList(int? idTagTransaksi, List<TagTransaksi> tagList) {
    if (idTagTransaksi == null) return '-';

    try {
      final tag = tagList.firstWhere(
            (tag) => tag.id == idTagTransaksi,
        orElse: () => TagTransaksi(id: 0, kategoriTransaksi: '', nama: 'Tag Tidak Ditemukan'),
      );

      return tag.nama ?? 'Tag $idTagTransaksi';
    } catch (e) {
      return 'Tag $idTagTransaksi';
    }
  }

  void _updateUploadProgress(double progress) {
    setState(() {
      _uploadProgress = progress;
    });
  }

  Future<void> _loadLastPremiKru() async {
    await databaseHelper.initDatabase();
    await _getListPremiKru();
    await databaseHelper.closeDatabase();
  }

  Future<void> _getListPremiKru() async {
    List<Map<String, dynamic>> premiKruData = await premiHarianKruService.getPremiHarianKruWithKruBis();
    setState(() {
      listPremiHarianKru = premiKruData;
    });
    if (listPremiHarianKru.isEmpty) {
      print('Tidak ada data dalam tabel Premi Harian Kru.');
    } else {
      print('Data ditemukan dalam tabel Premi Harian Kru.');
    }
  }

  // Method untuk refresh data setoran kru
  Future<void> _refreshSetoranKruData() async {
    setState(() {
      setoranKruData = setoranKruService.getAllSetoran();
    });
  }

  Future<void> _pushDataPremiHarianKru() async {
    if (_selectedDate == null) {
      print("Silakan pilih tanggal terlebih dahulu.");
      _showAlertDialog(context, "Silakan pilih tanggal terlebih dahulu.");
      return;
    }

    setState(() {
      _isPushingData = true;
      _uploadProgress = 0.0;
    });

    try {
      // 1️⃣ Kirim premi harian kru
      await dataPusherService.pushDataPremiHarianKru(
        selectedDate: _selectedDate!,
        onProgress: _updateUploadProgress,
        onSuccess: () {
          _getListPremiKru();
          _refreshSetoranKruData();
        },
      );

      // 2️⃣ Ambil token dan idTransaksi dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      String? idTransaksi = prefs.getString('idTransaksi');

      if (idTransaksi == null) {
        // fallback generate
        idTransaksi = "KEUBIS${DateTime.now().millisecondsSinceEpoch}";
        prefs.setString('idTransaksi', idTransaksi);
        print("Using fallback transaction ID: $idTransaksi");
      }

      // 3️⃣ Ambil data setoran kru lokal yang status 'N'
      final List<SetoranKru> setoranKruToSend =
      await SetoranKruService().getAllSetoran();
      final List<SetoranKru> filteredSetoran =
      setoranKruToSend.where((e) => e.status == 'N').toList();

      if (filteredSetoran.isEmpty) {
        print('Tidak ada data setoran kru untuk dikirim.');
        return;
      }

      // 4️⃣ Persiapkan rows JSON
      final List<Map<String, dynamic>> rowsList = filteredSetoran.map((d) {
        return {
          'tgl_transaksi': d.tglTransaksi,
          'km_pulang': d.kmPulang ?? '',
          'rit': d.rit,
          'no_pol': d.noPol,
          'id_bus': d.idBus,
          'kode_trayek': d.kodeTrayek,
          'id_personil': d.idPersonil,
          'id_group': d.idGroup,
          'jumlah': d.jumlah ?? '',
          'coa': d.coa ?? '',
          'nilai': d.nilai,
          'id_tag_transaksi': d.idTagTransaksi,
          'status': d.status,
          'keterangan': d.keterangan ?? '',
          // jika mau file diikutkan bisa ditambahkan url/file path
        };
      }).toList();

      // 5️⃣ Definisikan callback untuk update status
      Future<void> updateStatusCallback(String idTransaksi) async {
        print('🔄 Memulai update status untuk id_transaksi: $idTransaksi');
        for (var s in filteredSetoran) {
          try {
            await SetoranKruService().updateSetoran(s.copyWith(status: 'Y'));
            print('✅ Status updated untuk setoran ID: ${s.id}');
          } catch (e) {
            print('❌ Gagal update status untuk setoran ID: ${s.id} - Error: $e');
          }
        }
        print('✅ Semua status berhasil diupdate ke Y');
      }

      // 6️⃣ Kirim data ke API dengan callback
      final response = await kirimSetoranKruMobile(
        idTransaksi: idTransaksi,
        token: token!,
        rows: rowsList,
        files: filteredSetoran,
        onSuccessCallback: updateStatusCallback, // Tambahkan callback di sini
      );

      print('Setoran kru berhasil dikirim: $response');

      // 7️⃣ Tidak perlu update status lagi di sini karena sudah dilakukan di callback
      print('✅ Data berhasil dikirim dan status sudah diupdate via callback');

    } catch (e) {
      print('Error pushing data: $e');
      _showAlertDialog(context, "Terjadi kesalahan saat mengirim data: $e");
    } finally {
      setState(() {
        _isPushingData = false;
        _uploadProgress = 0.0;
      });
    }
  }

// ===========================================
// Fungsi kirim data ke API Lumen
// ===========================================
  Future<Map<String, dynamic>> kirimSetoranKruMobile({
    required String idTransaksi,
    required String token,
    required List<Map<String, dynamic>> rows,
    required List<SetoranKru> files,
    required Function(String) onSuccessCallback,
  }) async {
    const String apiUrl = 'https://apimila.sysconix.id/api/simpansetorankrumobile';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add Authorization
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Kirim id_transaksi
      request.fields['id_transaksi'] = idTransaksi;

      // Kirim rows sebagai JSON string - pastikan format benar
      List<Map<String, dynamic>> cleanedRows = [];
      for (var row in rows) {
        // Bersihkan data dari nilai null atau format yang tidak diinginkan
        Map<String, dynamic> cleanedRow = {};
        row.forEach((key, value) {
          if (value != null) {
            cleanedRow[key] = value;
          }
        });
        cleanedRows.add(cleanedRow);
      }

      request.fields['rows'] = jsonEncode(cleanedRows);

      // Debug: Print data yang dikirim
      print('📤 Data yang dikirim ke API:');
      print('ID Transaksi: $idTransaksi');
      print('Jumlah rows: ${cleanedRows.length}');
      print('Rows JSON: ${jsonEncode(cleanedRows)}');

      // Kirim file jika ada - PERBAIKI BAGIAN INI
      for (int i = 0; i < files.length; i++) {
        final d = files[i];
        if (d.fupload != null && d.fupload!.isNotEmpty && File(d.fupload!).existsSync()) {
          try {
            var multipartFile = await http.MultipartFile.fromPath(
                'file_name[$i]',
                d.fupload!
            );
            request.files.add(multipartFile);
            print('📎 File $i dilampirkan: ${d.fupload}');
          } catch (e) {
            print('⚠️  Gagal melampirkan file $i: ${d.fupload} - Error: $e');
          }
        } else {
          print('⚠️  File $i tidak valid atau tidak ditemukan: ${d.fupload}');
        }
      }

      print('🚀 Mengirim ${cleanedRows.length} data ke API...');

      // Tambahkan timeout
      var streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timeout setelah 30 detik');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        throw Exception('Gagal parsing response JSON: ${response.body}');
      }

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          print('✅ Berhasil mengirim data setoran kru');

          // Panggil callback untuk update status = 'Y'
          try {
            await onSuccessCallback(idTransaksi);
            print('✅ Status berhasil diupdate ke Y untuk id_transaksi: $idTransaksi');
          } catch (e) {
            print('⚠️  Berhasil kirim data tapi gagal update status: $e');
            // Tidak rethrow error update status, karena data sudah berhasil dikirim ke server
          }

          return responseData;
        } else {
          // Handle case where status code 200 but success: false
          String errorMessage = responseData['message'] ?? 'Unknown error from API';
          throw Exception('API response success: false - $errorMessage');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Token mungkin expired atau tidak valid');
      } else if (response.statusCode == 422) {
        // Validasi error - berikan informasi lebih detail
        String validationError = responseData['message'] ?? 'Data validation failed';
        String errorDetails = responseData['errors'] != null
            ? ' - Details: ${responseData['errors']}'
            : '';
        throw Exception('Validasi gagal: $validationError$errorDetails');
      } else if (response.statusCode == 500) {
        throw Exception('Server error (500) - Silakan coba lagi nanti');
      } else {
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException catch (e) {
      print('❌ Timeout: $e');
      throw Exception('Timeout - Koneksi terlalu lama, periksa koneksi internet Anda');
    } on SocketException catch (e) {
      print('❌ Socket Error: $e');
      throw Exception('Koneksi jaringan terputus - Periksa koneksi internet Anda');
    } catch (e) {
      print('❌ Error dalam kirimSetoranKruMobile: $e');
      rethrow;
    }
  }

  Future<void> updateStatusSetoranKru(String idTransaksi) async {
    final db = await DatabaseHelper().database;

    try {
      // Update status menjadi 'Y' hanya untuk field yang ada di database
      int updatedRows = await db.update(
        't_setoran_kru',
        {
          'status': 'Y',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id_transaksi = ? AND status = ?',
        whereArgs: [idTransaksi, 'N'], // Hanya update yang belum terkirim
      );

      print('✅ Updated $updatedRows rows dengan status Y untuk id_transaksi: $idTransaksi');

      if (updatedRows == 0) {
        print('⚠️  Tidak ada data yang diupdate - mungkin sudah berstatus Y');
      }
    } catch (e) {
      print('❌ Gagal update status di database: $e');

      // Fallback: coba update tanpa field yang problematic
      try {
        int updatedRows = await db.update(
          't_setoran_kru',
          {'status': 'Y'},
          where: 'id_transaksi = ?',
          whereArgs: [idTransaksi],
        );
        print('✅ Fallback update berhasil: $updatedRows rows');
      } catch (e2) {
        print('❌ Fallback update juga gagal: $e2');
        throw e; // Tetap throw error original
      }
    }
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate)
      setState(() {
        _selectedDate = pickedDate;
      });
  }

  void _showAlertDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Pemberitahuan"),
          content: Text(message),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isPushingData) {
      return Stack(
        children: [
          Container(
            color: Colors.grey.withOpacity(0.5),
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
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('Data Premi Disetor Harian Kru'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () {
                _selectDate(context);
              },
              tooltip: 'Pilih Tanggal',
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                _pushDataPremiHarianKru();
              },
              tooltip: 'Kirim Data',
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                _refreshSetoranKruData();
              },
              tooltip: 'Refresh Data Setoran',
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Tabel Data Premi Harian Kru
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(
                      label: Expanded(
                        child: Center(
                          child: Text('Kru', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Center(
                          child: Text('%', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Center(
                        child: Text('Nominal', style: TextStyle(fontSize: 18)),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Center(
                        child: Text('Status', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                  rows: listPremiHarianKru.map(
                        (item) => DataRow(
                      cells: [
                        DataCell(
                          Text(
                            item['nama_kru'].toString(),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        DataCell(
                          Text(
                            item['persen_premi'].toString(),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        DataCell(
                          Text(
                            formatter.format(item['nominal_premi_disetor']),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        DataCell(
                          Text(
                            item['status'].toString(),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ).toList(),
                ),
              ),
              SizedBox(height: 20),

              // Data Setoran Kru dari Service
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Setoran Kru',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    FutureBuilder<List<SetoranKru>>(
                      future: setoranKruData,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          List<SetoranKru> setoranData = snapshot.data!;

                          return FutureBuilder<List<TagTransaksi>>(
                            future: _getAllTagTransaksi(),
                            builder: (context, tagSnapshot) {
                              if (tagSnapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              } else if (tagSnapshot.hasError) {
                                return Center(child: Text('Error loading tags'));
                              } else {
                                List<TagTransaksi> tagList = tagSnapshot.data ?? [];

                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: [
                                      DataColumn(label: Text('ID')),
                                      DataColumn(label: Text('Nama Tag')),
                                      DataColumn(label: Text('Nilai'), numeric: true),
                                      DataColumn(label: Text('Keterangan')),
                                      DataColumn(label: Text('Status')),
                                    ],
                                    rows: setoranData.map(
                                          (setoran) => DataRow(
                                        cells: [
                                          DataCell(Text(setoran.id?.toString() ?? '-')),
                                          DataCell(Text(
                                              _getNamaTagFromList(setoran.idTagTransaksi, tagList)
                                          )),
                                          DataCell(Text(
                                              setoran.nilai != null
                                                  ? formatter.format(setoran.nilai!)
                                                  : '-'
                                          )),
                                          DataCell(Text(setoran.keterangan ?? '-')),
                                          DataCell(Text(setoran.status ?? '-')),
                                        ],
                                      ),
                                    ).toList(),
                                  ),
                                );
                              }
                            },
                          );
                        } else {
                          return Center(
                            child: Text('Tidak ada data setoran kru'),
                          );
                        }
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
}