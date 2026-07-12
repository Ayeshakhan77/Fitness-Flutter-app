import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../lib/db_service.dart';
import '../lib/chatbot_engine.dart';

// Middlewares
Middleware _authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.url.path.contains('auth/')) {
        return innerHandler(request);
      }

      final authHeader = request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.unauthorized(jsonEncode({'error': 'Unauthorized'}));
      }

      final token = authHeader.substring(7);
      try {
        final jwt = JWT.verify(token, SecretKey('my-secret-key'));
        // Safely parse userId as int
        final userId = int.tryParse(jwt.payload['id'].toString());
        
        if (userId == null) {
          print('❌ Auth ERROR: Invalid userId in token: ${jwt.payload['id']}');
          return Response.unauthorized(jsonEncode({'error': 'Invalid user ID'}));
        }

        // Add userId to context
        final updatedRequest = request.change(context: {'userId': userId});
        return innerHandler(updatedRequest);
      } catch (e) {
        print('❌ Auth ERROR: $e');
        return Response.unauthorized(jsonEncode({'error': 'Invalid token'}));
      }
    };
  };
}

/// Safely converts MySQL row values to JSON-encodable types.
/// Handles cases where TEXT columns are returned as 'Blob' objects.
dynamic _fixValue(dynamic value) {
  if (value == null) return null;
  if (value.runtimeType.toString() == 'Blob') {
    return String.fromCharCodes(value.bytes);
  }
  return value;
}

Map<String, dynamic> _fixRow(dynamic row) {
  final Map<String, dynamic> result = {};
  for (var key in row.fields.keys) {
    result[key] = _fixValue(row[key]);
  }
  return result;
}

class Api {
  Router get router {
    final router = Router();

    // --- Auth Routes ---
    router.post('/api/auth/signup', (Request request) async {
      final payload = jsonDecode(await request.readAsString());
      final name = payload['name'];
      final email = payload['email'];
      final password = payload['password'];

      // Check if user exists
      final existing = await DBService.getUserByEmail(email);
      if (existing.isNotEmpty) {
        return Response.badRequest(body: jsonEncode({'error': 'User already exists'}));
      }

      // Hash password (basic hex for simplicity here)
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();
      
      final result = await DBService.createUser(name, email, hashedPassword);
      final userId = result.insertId!;

      final token = JWT({'id': userId}).sign(SecretKey('my-secret-key'));

      return Response.ok(jsonEncode({
        'success': true,
        'token': token,
        'userId': userId.toString(),
        'name': name,
        'email': email,
      }));
    });

    router.post('/api/auth/signin', (Request request) async {
      final payload = jsonDecode(await request.readAsString());
      final email = payload['email'];
      final password = payload['password'];

      final results = await DBService.getUserByEmail(email);
      if (results.isEmpty) {
        return Response.forbidden(jsonEncode({'error': 'Invalid credentials'}));
      }

      final user = results.first;
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();

      if (user['password'] != hashedPassword) {
        return Response.forbidden(jsonEncode({'error': 'Invalid credentials'}));
      }

      final token = JWT({'id': user['id']}).sign(SecretKey('my-secret-key'));

      return Response.ok(jsonEncode({
        'success': true,
        'token': token,
        'userId': user['id'].toString(),
        'name': user['name'],
        'email': user['email'],
      }));
    });

    // --- Workout Routes ---
    router.get('/api/workouts', (Request request) async {
      final userId = request.context['userId'] as int;
      final results = await DBService.getWorkouts(userId);
      
      final workouts = results.map((row) {
        final fixed = _fixRow(row);
        return {
          'workoutId': fixed['id'].toString(),
          'name': fixed['name'],
          'duration': fixed['duration'],
          'caloriesBurned': fixed['calories_burned'],
          'workoutDate': fixed['workout_date'].toString().split(' ')[0],
        };
      }).toList();

      return Response.ok(jsonEncode(workouts));
    });

    router.post('/api/workouts', (Request request) async {
      try {
        final userId = request.context['userId'] as int;
        final payload = jsonDecode(await request.readAsString());
        
        print('🏋️ Adding workout for User $userId: ${payload['name']}');
        
        await DBService.addWorkout(
          userId,
          payload['name'],
          payload['duration'],
          payload['caloriesBurned'],
          payload['workoutDate'],
        );

        return Response.ok(jsonEncode({'success': true}));
      } catch (e, stack) {
        print('❌ Workout Storage Error: $e\n$stack');
        return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
      }
    });

    // --- Meal Routes ---
    router.get('/api/meals', (Request request) async {
      final userId = request.context['userId'] as int;
      final results = await DBService.getMeals(userId);
      
      final meals = results.map((row) {
        final fixed = _fixRow(row);
        return {
          'mealId': fixed['id'].toString(),
          'name': fixed['name'],
          'type': fixed['type'],
          'calories': fixed['calories'],
          'mealTime': fixed['meal_time'].toString(),
          'mealDate': fixed['meal_date'].toString().split(' ')[0],
        };
      }).toList();

      return Response.ok(jsonEncode(meals));
    });

    router.post('/api/meals', (Request request) async {
      try {
        final userId = request.context['userId'] as int;
        final payload = jsonDecode(await request.readAsString());
        
        print('🥗 Adding meal for User $userId: ${payload['name']}');
        
        await DBService.addMeal(
          userId,
          payload['name'],
          payload['type'],
          payload['calories'],
          payload['mealTime'],
          payload['mealDate'],
        );

        return Response.ok(jsonEncode({'success': true}));
      } catch (e, stack) {
        print('❌ Meal Storage Error: $e\n$stack');
        return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
      }
    });

    // --- Chat Routes ---
    router.get('/api/chat/messages', (Request request) async {
      final userId = request.context['userId'] as int;
      final results = await DBService.getChatMessages(userId);
      
      final messages = results.map((row) {
        final fixed = _fixRow(row);
        return {
          'messageId': fixed['id'].toString(),
          'message': fixed['message'],
          'isUser': fixed['is_user'] == 1,
          'createdAt': fixed['created_at'].toString(),
        };
      }).toList();

      return Response.ok(jsonEncode(messages));
    });

    router.post('/api/chat/send', (Request request) async {
      try {
        final userId = request.context['userId'] as int;
        final payload = jsonDecode(await request.readAsString());
        final userMessage = payload['message'];

        if (userMessage == null || userMessage.toString().isEmpty) {
          return Response.badRequest(body: jsonEncode({'error': 'Message is required'}));
        }

        print('💬 Chat message from User $userId: $userMessage');

        // Save user message
        await DBService.addChatMessage(userId, userMessage, true);

        // Generate bot response
        final botMessage = await ChatbotEngine.generateResponse(userId, userMessage);
        
        print('🤖 Bot response for User $userId: $botMessage');

        // Save bot message
        await DBService.addChatMessage(userId, botMessage, false);

        return Response.ok(jsonEncode({
          'success': true,
          'reply': botMessage,
        }));
      } catch (e, stack) {
        print('❌ Chat Error: $e\n$stack');
        return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
      }
    });

    router.delete('/api/chat/clear', (Request request) async {
      final userId = request.context['userId'] as int;
      await DBService.clearChatMessages(userId);
      return Response.ok(jsonEncode({'success': true}));
    });

    // --- Stats Routes ---
    router.get('/api/stats', (Request request) async {
      final userId = request.context['userId'] as int;
      final results = await DBService.getStats(userId);
      final stats = results.first;

      // Also calculate today's calories from meals and workouts
      final workouts = await DBService.getWorkouts(userId);
      final meals = await DBService.getMeals(userId);
      
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      
      final todayBurned = workouts
          .where((w) => w['workout_date'].toString().startsWith(todayStr))
          .fold(0, (sum, w) => sum + (w['calories_burned'] as int));
          
      final todayConsumed = meals
          .where((m) => m['meal_date'].toString().startsWith(todayStr))
          .fold(0, (sum, m) => sum + (m['calories'] as int));

      return Response.ok(jsonEncode({
        'userId': stats['user_id'].toString(),
        'steps': stats['steps'],
        'weight': stats['weight'],
        'todayCaloriesBurned': todayBurned,
        'todayCaloriesConsumed': todayConsumed,
      }));
    });

    return router;
  }
}

void main() async {
  DBService.init();
  
  final api = Api();
  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(_authMiddleware())
      .addMiddleware(logRequests())
      .addHandler(api.router);

  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  print('🚀 Server running on port ${server.port}');
}
