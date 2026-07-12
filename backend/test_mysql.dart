import 'package:mysql1/mysql1.dart';

void main() async {
  print('Testing MySQL connection...');
  final settings = ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'root123',
  );

  try {
    final conn = await MySqlConnection.connect(settings);
    print('✅ Successfully connected to MySQL!');
    
    final results = await conn.query('SHOW DATABASES');
    print('Databases:');
    for (var row in results) {
      print(' - ${row[0]}');
    }
    
    await conn.close();
  } catch (e) {
    print('❌ Failed to connect to MySQL: $e');
  }
}
