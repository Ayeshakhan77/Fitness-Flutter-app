import 'package:mysql1/mysql1.dart';

void main() async {
  final settings = ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'root123',
    db: 'fitness_app',
  );

  try {
    final conn = await MySqlConnection.connect(settings);
    print('✅ Connected to fitness_app');
    
    final users = await conn.query('SELECT COUNT(*) FROM users');
    print('Users count: ${users.first[0]}');
    
    final workouts = await conn.query('SELECT COUNT(*) FROM workouts');
    print('Workouts count: ${workouts.first[0]}');
    
    final meals = await conn.query('SELECT COUNT(*) FROM meals');
    print('Meals count: ${meals.first[0]}');
    
    final chat = await conn.query('SELECT COUNT(*) FROM chat_messages');
    print('Chat messages count: ${chat.first[0]}');
    
    await conn.close();
  } catch (e) {
    print('❌ Error: $e');
  }
}
