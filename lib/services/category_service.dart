import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pontare/models/category.dart';
import 'package:pontare/models/rate.dart';
import 'package:pontare/models/rate_dto.dart';

class CategoryService {
  final String baseUrl = "https://completely-notable-killdeer.ngrok-free.app/api";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<List<Category>> getCategories() async {
    final token = await _getToken();
    
    if (token == null) {
      throw Exception('No token found');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> categoriesJson = json.decode(response.body);
      return categoriesJson.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories: ${response.body}');
    }
  }

  Future<bool> createCategory(String categoryName) async {
    final token = await _getToken();
    
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'categoryName': categoryName}),
    );
    print(response.body);

    return response.statusCode == 200;
  }

  Future<bool> updateCategory(int id, String newCategoryName) async {
    final token = await _getToken();
    
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: newCategoryName,
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteCategory(int id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    return response.statusCode == 204;
  }

Future<Rate?> getRateForCategory(int id) async {
  final token = await _getToken();
    final response = await http.get(Uri.parse('$baseUrl/rates/$id'),
     headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },);

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return Rate.fromJson(json);
    } else if (response.statusCode == 404) {
      // Handle 404 not found
      return null;
    } else {
      throw Exception('Failed to load rate');
    }
  }
  Future<bool> setRateForCategory(RateDTO rateDTO) async {
    final token = await _getToken();

    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/rates'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(rateDTO.toJson()),
    );

    return response.statusCode == 200;
  }
}
