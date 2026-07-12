import 'package:mysql1/mysql1.dart';

class DBService {
  static late ConnectionSettings settings;
  static MySqlConnection? _connection;

  static void init() {
    settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',
      password: 'root123',
      db: 'fitness_app',
    );
  }

  static Future<MySqlConnection> get connection async {
    if (_connection == null) {
      _connection = await MySqlConnection.connect(settings);
    }
    return _connection!;
  }

  // Auth Queries
  static Future<Results> getUserByEmail(String email) async {
    final conn = await connection;
    return await conn.query('SELECT * FROM users WHERE email = ?', [email]);
  }

  static Future<Results> createUser(String name, String email, String password) async {
    final conn = await connection;
    return await conn.query(
      'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
      [name, email, password],
    );
  }

  // Workout Queries
  static Future<Results> getWorkouts(int userId) async {
    final conn = await connection;
    return await conn.query(
      'SELECT * FROM workouts WHERE user_id = ? ORDER BY workout_date DESC',
      [userId],
    );
  }

  static Future<Results> addWorkout(int userId, String name, int duration, int caloriesBurned, String date) async {
    final conn = await connection;
    return await conn.query(
      'INSERT INTO workouts (user_id, name, duration, calories_burned, workout_date) VALUES (?, ?, ?, ?, ?)',
      [userId, name, duration, caloriesBurned, date],
    );
  }

  // Meal Queries
  static Future<Results> getMeals(int userId) async {
    final conn = await connection;
    return await conn.query(
      'SELECT * FROM meals WHERE user_id = ? ORDER BY meal_date DESC, meal_time DESC',
      [userId],
    );
  }

  static Future<Results> addMeal(int userId, String name, String type, int calories, String time, String date) async {
    final conn = await connection;
    return await conn.query(
      'INSERT INTO meals (user_id, name, type, calories, meal_time, meal_date) VALUES (?, ?, ?, ?, ?, ?)',
      [userId, name, type, calories, time, date],
    );
  }

  // Chat Queries
  static Future<Results> getChatMessages(int userId) async {
    final conn = await connection;
    return await conn.query(
      'SELECT * FROM chat_messages WHERE user_id = ? ORDER BY created_at ASC',
      [userId],
    );
  }

  static Future<Results> addChatMessage(int userId, String message, bool isUser) async {
    final conn = await connection;
    return await conn.query(
      'INSERT INTO chat_messages (user_id, message, is_user) VALUES (?, ?, ?)',
      [userId, message, isUser],
    );
  }

  static Future<void> clearChatMessages(int userId) async {
    final conn = await connection;
    await conn.query('DELETE FROM chat_messages WHERE user_id = ?', [userId]);
  }

  // Stats Queries
  static Future<Results> getStats(int userId) async {
    final conn = await connection;
    final results = await conn.query('SELECT * FROM user_stats WHERE user_id = ?', [userId]);
    if (results.isEmpty) {
      // Create default stats if not exists
      await conn.query('INSERT INTO user_stats (user_id) VALUES (?)', [userId]);
      return await conn.query('SELECT * FROM user_stats WHERE user_id = ?', [userId]);
    }
    return results;
  }

  static Future<void> updateStats(int userId, {int? steps, double? weight}) async {
    final conn = await connection;
    if (steps != null) {
      await conn.query('UPDATE user_stats SET steps = ? WHERE user_id = ?', [steps, userId]);
    }
    if (weight != null) {
      await conn.query('UPDATE user_stats SET weight = ? WHERE user_id = ?', [weight, userId]);
    }
  }
}
