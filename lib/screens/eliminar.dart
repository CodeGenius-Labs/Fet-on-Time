import 'package:flutter/material.dart';
import '../base_conection.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EliminarPage extends StatefulWidget {
  final int idClase;
  final String nombreClase;
  const EliminarPage({super.key, required this.idClase, required this.nombreClase,});
  @override
  _EliminarPageState createState() => _EliminarPageState();
}

class _EliminarPageState extends State<EliminarPage> {
  MySqlConnection? _connection;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final connection = await getConnection();

      if (mounted) {
        setState(() {
          _connection = connection;
        });
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al inicializar: $e');
      }
    }
  }

  Future<void> _eliminarClase() async {
    setState(() => _isLoading = true);

    // Intentar conectar hasta 3 veces
    int intentos = 0;
    final maxIntentos = 3;

    while (intentos < maxIntentos) {
      try {
        // Si no hay conexión, intentar establecerla
        if (_connection == null) {
          print('Intento de conexión ${intentos + 1}/$maxIntentos');
          _connection = await getConnection();
        }

        // Intentar eliminar la clase
        await _connection!.query(
          'DELETE FROM clases WHERE idClases = ?',
          [widget.idClase],
        );

        // Si llegamos aquí, la eliminación fue exitosa
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('status', 'calendar');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La clase se eliminó correctamente')),
          );
          Navigator.of(context).pop();
        }
        return; // Salir de la función si todo fue exitoso

      } catch (e) {
        print('Error en intento ${intentos + 1}: $e');
        intentos++;
        _connection = null; // Resetear la conexión para el siguiente intento

        if (intentos < maxIntentos) {
          // Esperar antes del siguiente intento
          await Future.delayed(Duration(seconds: 2));
        } else {
          // Si ya agotamos los intentos, mostrar error
          _mostrarError('No se pudo eliminar la clase después de $maxIntentos intentos');
        }
      }
    }

    // Asegurarnos de que _isLoading se establezca en false al final
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    }
    debugPrint(mensaje);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eliminar Clase'),
        backgroundColor: const Color.fromARGB(255, 40, 140, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Está seguro de que desea eliminar la clase "${widget.nombreClase}"?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: _eliminarClase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 40, 140, 1),
                    ),
                    child: const Text('Eliminar Clase'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}