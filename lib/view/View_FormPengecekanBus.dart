import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kru_reguler/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FormPengecekanBus extends StatefulWidget {
  @override
  _FormPengecekanBusState createState() => _FormPengecekanBusState();
}

class _FormPengecekanBusState extends State<FormPengecekanBus> {
  List<Map<String, dynamic>> inspectionItems = [];
  Map<int, String?> selectedItems = {}; // Untuk menyimpan status dropdown
  Map<int, String> comments = {}; // Untuk menyimpan komentar dari TextField
  late int idUser;
  int? idGarasi;
  int idBus = 0;
  String? noPol;
  late String token;

  DatabaseHelper databaseHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _getInspectionItems();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        idUser = prefs.getInt('idUser') ?? 0;
        idGarasi = prefs.getInt('idGarasi');
        idBus = prefs.getInt('idBus') ?? 0;
        noPol = prefs.getString('noPol');
        token = prefs.getString('token') ?? '';
      });
    });
  }

  Future<void> _getInspectionItems() async {
    await databaseHelper.initDatabase();
    List<Map<String, dynamic>> items = await databaseHelper.getAllInspectionItems();
    await databaseHelper.closeDatabase();
    print('object items : $items');
    setState(() {
      inspectionItems = items;
      selectedItems = {for (var item in items) item['id']: 'G'}; // default G
    });
  }

  void _submitForm() async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    final dbHelper = DatabaseHelper.instance;
    Database db = await dbHelper.database;

    // Simpan hasil pengecekan yang telah di-check
    for (var item in inspectionItems) {
      if (selectedItems[item['id']] != null) {
        await db.insert('t_inspection_results', {
          'id_form': '${idBus}-${idUser}-${formattedDate}', // Perbaikan penggabungan string
          'inspections_item_id': item['id'],
          'id_bus': idBus,
          'no_pol': noPol,
          'status': selectedItems[item['id']]!,
          'remarks': comments[item['id']] ?? '',
          'id_kru': idUser,
          'tgl_periksa': formattedDate,
          'status_qc': 'N',
        });
      }
    }

    Fluttertoast.showToast(msg: "Pengecekan berhasil disimpan");
    Navigator.pop(context); // Kembali ke halaman sebelumnya
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: inspectionItems.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: inspectionItems.length,
              itemBuilder: (context, index) {
                var item = inspectionItems[index];
                return ListTile(
                  title: Text(
                    item['item_name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Menentukan teks menjadi tebal
                    ),
                  ),
                  trailing: DropdownButton<String>(
                    value: selectedItems[item['id']],
                    hint: Text('Status'),
                    items: [
                      DropdownMenuItem(value: 'G', child: Text('G')),
                      DropdownMenuItem(value: 'NG', child: Text('NG')),
                      DropdownMenuItem(value: 'NA', child: Text('NA')),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedItems[item['id']] = newValue;
                      });
                    },
                  ),
                  subtitle: TextField(
                    onChanged: (text) {
                      setState(() {
                        comments[item['id']] = text;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Keterangan',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 1,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 80), // Memberikan jarak untuk tombol FAB
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submitForm,
        child: Icon(Icons.save),
        tooltip: 'Simpan Pengecekan',
      ),
    );
  }
}
