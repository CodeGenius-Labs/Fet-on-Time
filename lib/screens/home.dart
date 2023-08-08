import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class home extends StatelessWidget {
  const home({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getDirectorType(), // Llama a la función que obtiene el tipo de director
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Muestra un indicador de carga mientras se obtiene el tipo de director
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          // Maneja el error si ocurre
          return Center(child: Text('Error al obtener el tipo de director'));
        } else {
          // Si todo va bien, muestra el contenido de la pantalla de inicio
          final directorType = snapshot.data ?? '';

          return Scaffold(
            appBar: null,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Tipo de Director: $directorType'),
                  ElevatedButton(
                    onPressed: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      prefs.setBool('isLoggedIn', false); // Elimina el indicador de autenticación
                      // Agrega aquí la lógica para limpiar cualquier otro dato de autenticación si es necesario

                      Navigator.pushReplacementNamed(context, 'loadinglogin'); // Vuelve a la pantalla de inicio de sesión
                    },
                    child: Text('Cerrar Sesión'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  // Función para obtener el tipo de director desde las shared_preferences
  Future<String> _getDirectorType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('directorType') ?? '';
  }
}