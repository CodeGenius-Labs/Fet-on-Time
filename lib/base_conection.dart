import 'package:mysql1/mysql1.dart';

Future<MySqlConnection> getConnection() async {
  final settings = ConnectionSettings(
    host: 'db4free.net',
    port: 3306,
    user: 'marlon123',
    password: 'marlon123',
    db: 'asistenciafet',
  );

  return await MySqlConnection.connect(settings);
}

