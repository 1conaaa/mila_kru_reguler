import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mila_kru_reguler/database/database_helper.dart';

class ApiHelperInspectionItems {
  static Future<void> addListInspectionItemsAPI(String token) async {
    final response = await http.get(
      Uri.parse('https://apimila.sysconix.id/api/inspectionitems'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('cek response status: ${response.statusCode}');
    print('cek response body: ${response.body}');

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse is Map<String, dynamic>) {
        ApiResponseListInspectionItems apiResponse = ApiResponseListInspectionItems
            .fromJson(jsonResponse);

        if (apiResponse.success == 1) {
          print('Data Inspection Items API berhasil diambil: $apiResponse');
          List<InspectionItems> inspectionItemsData = apiResponse.inspectionitems;

          DatabaseHelper databaseHelper = DatabaseHelper();
          await databaseHelper.initDatabase();

          try {
            for (var inspectionItem in inspectionItemsData) {
              await databaseHelper.insertInspectionItem(inspectionItem.toMap());
            }
            print('Data Inspection Items berhasil disimpan');

            // Panggil fungsi untuk menampilkan data dari tabel m_inspection_items
            await getInspectionItemsFromDB();
          } catch (e) {
            print('Error menyimpan data: $e');
          } finally {
            await databaseHelper.closeDatabase();
          }
        } else {
          print('Gagal menyimpan data Inspection Items. Silakan coba lagi.');
        }
      } else if (jsonResponse is List) {
        print('Respons berupa List, memproses data sebagai List.');
        List<InspectionItems> inspectionItemsList = jsonResponse
            .map((item) => InspectionItems.fromJson(item))
            .toList();

        DatabaseHelper databaseHelper = DatabaseHelper();
        await databaseHelper.initDatabase();

        try {
          for (var inspectionItem in inspectionItemsList) {
            await databaseHelper.insertInspectionItem(inspectionItem.toMap());
            print('Data item ${inspectionItem.name} berhasil disimpan.');
          }
          print('Data Inspection Items berhasil disimpan dari List');

          // Panggil fungsi untuk menampilkan data dari tabel m_inspection_items
          await getInspectionItemsFromDB();
        } catch (e) {
          print('Error menyimpan data dari List: $e');
        } finally {
          await databaseHelper.closeDatabase();
        }
      } else {
        print('Format respons API tidak sesuai, diharapkan Map atau List');
      }
    } else {
      print('Gagal mengambil data Inspection Items dari API');
    }
  }

  // Fungsi untuk mengambil dan menampilkan data dari tabel m_inspection_items
  static Future<void> getInspectionItemsFromDB() async {
    DatabaseHelper databaseHelper = DatabaseHelper();
    await databaseHelper.initDatabase();

    try {
      List<Map<String, dynamic>> inspectionItems = await databaseHelper.getAllInspectionItems();
      print('Data Inspection Items dari tabel m_inspection_items: $inspectionItems');
    } catch (e) {
      print('Error mengambil data dari database: $e');
    } finally {
      await databaseHelper.closeDatabase();
    }
  }
}

class InspectionItems {
  final int id;
  final String name;
  final String description;

  InspectionItems({required this.id, required this.name, required this.description});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_name': name,
      'description': description,
    };
  }

  factory InspectionItems.fromJson(Map<String, dynamic> json) {
    return InspectionItems(
      id: json['id'],
      name: json['item_name'] ?? '',  // Ubah sesuai struktur JSON
      description: json['description'] ?? '',
    );
  }
}

class ApiResponseListInspectionItems {
  final int success;
  final List<InspectionItems> inspectionitems;

  ApiResponseListInspectionItems({required this.success, required this.inspectionitems});

  factory ApiResponseListInspectionItems.fromJson(Map<String, dynamic> json) {
    var list = json['inspectionitems'] as List;
    List<InspectionItems> inspectionItemsList =
    list.map((i) => InspectionItems.fromJson(i)).toList();

    return ApiResponseListInspectionItems(
      success: json['success'],
      inspectionitems: inspectionItemsList,
    );
  }
}
