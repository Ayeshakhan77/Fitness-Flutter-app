import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';
  static String? _token;
  static String? _userId;

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userId = prefs.getString('user_id');
    _initialized = true;
    print('🔑 ApiService initialized. Token: ${_token != null ? "exists" : "none"}, UserID: $_userId');
  }

  static Future<void> _ensureInitialized() async {
    if (!_initialized) await init();
  }

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print('✅ TOKEN SAVED: "$token"');
  }

  static Future<void> setUserId(String userId) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    print('✅ USER ID SAVED: $userId');
  }

  static Future<void> clearAuth() async {
    _token = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    print('🚿 Auth cleared');
  }

  static String? getToken() {
    return _token;
  }

  static String? getUserId() {
    return _userId;
  }

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    return headers;
  }

  static Future<Map<String, dynamic>> signIn(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/signin');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await setToken(data['token']);
      await setUserId(data['userId'].toString());
      return data;
    }
    
    return {'error': 'Signin failed', 'statusCode': response.statusCode};
  }

  static Future<Map<String, dynamic>> signUp(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/signup');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'email': email, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await setToken(data['token']);
      await setUserId(data['userId'].toString());
      return data;
    }
    
    return {'error': 'Signup failed'};
  }

  static Future<List<dynamic>> getChatMessages() async {
    final url = Uri.parse('$baseUrl/chat/messages');
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        if (response.body.isEmpty) return [];
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> sendChatMessage(String message) async {
    final url = Uri.parse('$baseUrl/chat/send');
    final response = await http.post(
      url,
      headers: _headers,
      body: json.encode({'message': message}),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {'error': 'Failed to send message'};
  }

  static Future<Map<String, dynamic>> clearChatMessages() async {
    final url = Uri.parse('$baseUrl/chat/clear');
    final response = await http.delete(url, headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {'error': 'Failed to clear messages'};
  }

  // Workouts
  static Future<List<dynamic>> getWorkouts() async {
    final url = Uri.parse('$baseUrl/workouts');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<Map<String, dynamic>> addWorkout(String name, int duration, int calories, String date) async {
    final url = Uri.parse('$baseUrl/workouts');
    final response = await http.post(
      url,
      headers: _headers,
      body: json.encode({
        'name': name,
        'duration': duration,
        'caloriesBurned': calories,
        'workoutDate': date,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {'error': 'Failed to add workout'};
  }

  // Meals
  static Future<List<dynamic>> getMeals() async {
    final url = Uri.parse('$baseUrl/meals');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<Map<String, dynamic>> addMeal(String name, String type, int calories, String time, String date) async {
    final url = Uri.parse('$baseUrl/meals');
    final response = await http.post(
      url,
      headers: _headers,
      body: json.encode({
        'name': name,
        'type': type,
        'calories': calories,
        'mealTime': time,
        'mealDate': date,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {'error': 'Failed to add meal'};
  }

  // Stats
  static Future<Map<String, dynamic>> getStats() async {
    final url = Uri.parse('$baseUrl/stats');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {};
  }
}