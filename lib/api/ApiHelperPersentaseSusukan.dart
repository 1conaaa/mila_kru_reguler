import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiHelperPersentaseSusukan {
  static const String _baseUrl = 'https://apimila.milaberkah.com/api/persensusukan';

  static Future<Map<String, dynamic>?> fetchFromApi(String token) async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('API STATUS: ${response.statusCode}');
      print('API BODY: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ API Error: $e');
      return null;
    }
  }
}
