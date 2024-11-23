import 'dart:developer';
import 'package:mysql1/mysql1.dart';

Future<MySqlConnection> getConnection() async {
  final settings = ConnectionSettings(
    host: 'db4free.net',
    port: 3306,
    user: 'marlon123',
    password: 'marlon123',
    db: 'asistenciafet',
  );

  try {
    return await MySqlConnection.connect(settings);
  } catch (e) {
    log('Connection Error: $e');
    rethrow; // Vuelve a lanzar el error si necesitas manejarlo en otro lado
  }
}
