import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/revenue.dart';

class RevenueService {
  final String baseUrl = "https://completely-notable-killdeer.ngrok-free.app/api";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

 Future<List<Revenue>> getRevenues(String token) async {
  final tokenn = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/revenues'),
      headers: {
        'Accept': '*/*',
        'Authorization': 'Bearer $tokenn',
      },
    );
    print(response.body);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Revenue.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load revenues');
    }
  }
  
  Future<bool> deleteRevenue(int id) async {
    final token = await _getToken();

    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/revenues/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 204; // Assuming 204 No Content for successful deletion
  }

  Future<bool> createRevenue(String hoursWorked, String currDay, String currency, int categoryId) async {
    final token = await _getToken();
    
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/revenues'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'hoursWorked': hoursWorked,
        'currDay': currDay,
        'currency': currency,
        'category_id': categoryId,
      }),
    );

    return response.statusCode == 200;
  }
  Future<bool> updateRevenueCategory(int revenueId, String categoryName) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/revenues/$revenueId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'newRevenueName': categoryName,
      }),
    );

    return response.statusCode == 200; // Assuming 200 is returned for successful update
  }
}
