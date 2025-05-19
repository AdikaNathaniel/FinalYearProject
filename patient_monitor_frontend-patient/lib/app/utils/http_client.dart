import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpClient {
  static const String baseUrl = 'http://localhost:3100';

  static Future post(String endpoint, dynamic body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('POST failed: ${response.statusCode}');
    }
  }

  static Future get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('GET failed: ${response.statusCode}');
    }
  }

  static Future delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('DELETE failed: ${response.statusCode}');
    }
  }
}
