import 'package:flutter/material.dart';
import '../base_conection.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EliminarPage extends StatefulWidget {
  final int idClase;
  const EliminarPage({super.key, required this.idClase});
  @override
  _EliminarPageState createState() => _EliminarPageState();
}

class _EliminarPageState extends State<EliminarPage> {
  MySqlConnection? _connection;
  String jornada = ' ';
  String nombre_viejo = ' ';

  @override
  void initState() {
    print("clase eliminar: ${widget.idClase}");
    super.initState();
    _getnombre_clase().then((value) {
      setState(() {
        nombre_viejo = value;
      });
    });
    _getjornada().then((value) {
      setState(() {
        jornada = value;
      });
    });
    getConnection().then((connection) {
      setState(() {
        _connection = connection;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eliminar Clase'),
        backgroundColor: const Color.fromARGB(255, 40, 140, 1), // Cambia el color del AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('¿Está seguro de que desea eliminar esta clase?'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_connection != null) {
                  try {
                    print(
                        'DELETE FROM clases WHERE idClases = ${widget.idClase} AND jornada = $jornada');
                    // Realizar la eliminación de la clase en la base de datos
                    await _connection!.query(
                      'DELETE FROM clases WHERE idClases = ? AND jornada = ?',
                      [widget.idClase, jornada],
                    );
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    prefs.setString('status', 'calendar');
                    // Muestra un SnackBar para indicar que la clase se eliminó correctamente
                    const snackBar = SnackBar(
                      content: Text('La clase se eliminó correctamente.'),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(snackBar);

                    // Cierra la pantalla de eliminación después de eliminar la clase
                    Navigator.of(context).pop();
                  } catch (e) {
                    // Manejar cualquier error que pueda ocurrir durante la eliminación
                    print('Error al eliminar la clase: $e');
                    // Puedes mostrar un mensaje de error al usuario si es necesario
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error en la conexion, vuelve a intentarlo.'),
                    ),
                  );
                  print('No se ha establecido una conexión a la base de datos.');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 40, 140, 1), // Cambia el color del botón
              ),
              child: const Text('Eliminar Clase'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getnombre_clase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('nombre_clase') ?? '';
  }

  Future<String> _getjornada() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jornada') ?? '';
  }
}
