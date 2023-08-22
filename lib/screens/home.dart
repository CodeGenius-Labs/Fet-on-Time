import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class home extends StatelessWidget {
  const home({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getDirectorType(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error al obtener el tipo de director'));
        } else {
          final directorType = snapshot.data ?? '';

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Color.fromARGB(255, 40, 140, 1), // Color de fondo gris
              toolbarHeight: 120, // Ajusta esta altura a tu preferencia
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logofet.png', // Ruta de tu imagen del logo en la carpeta "assets"
                    width: 120, // Ancho deseado del logo
                    height: 120, // Alto deseado del logo
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Tipo de Director: $directorType', // Texto en la barra
                    style: const TextStyle(fontSize: 17), // Tamaño de fuente
                  ),
                ],
              ),
              centerTitle: true, // Centra el título en la barra
            ),
            body: Container(
              color: const Color.fromARGB(120,40,140,1), // Color de fondo gris para la parte blanca
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 19.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 20.0,
                          mainAxisSpacing: 20.0,
                        ),
                        itemCount: 11,
                        itemBuilder: (context, index) {
                          int semesterNumber = index + 1;
                          String semesterText = 'SEMESTRE\n$semesterNumber';
                          if (semesterNumber == 10) {
                            return Visibility(
                              visible: false,
                              child: Container(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pushNamed(context, 'calendar');
                                    SharedPreferences prefs = await SharedPreferences.getInstance();
                                    prefs.setString('semestreType', '$semesterNumber');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green, // Color de fondo verde
                                  ),
                                  child: Text(
                                    semesterText,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            );
                          } else if (semesterNumber == 11) {
                            String semesterText = 'SEMESTRE\n10';
                            return ElevatedButton(
                              onPressed: () async {
                                Navigator.pushNamed(context, 'calendar');
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                prefs.setString('semestreType', '10');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green, // Color de fondo verde
                                padding: EdgeInsets.all(0),
                              ),
                              child: Center(
                                child: Text(
                                  semesterText,
                                  style: const TextStyle(fontSize: 17),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          return ElevatedButton(
                            onPressed: () async {
                              Navigator.pushNamed(context, 'calendar');
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              prefs.setString('semestreType', '$semesterNumber');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, // Color de fondo verde
                              padding: EdgeInsets.all(0),
                            ),
                            child: Center(
                              child: Text(
                                semesterText,
                                style: const TextStyle(fontSize: 17),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40), // Espacio entre los botones y el botón "Cerrar Sesión"
                    ElevatedButton(
                      onPressed: () async {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        prefs.setBool('isLoggedIn', false);
                        Navigator.pushReplacementNamed(context, 'loadinglogin');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Color de fondo verde
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10), // Espacio vertical del botón
                      ),
                      child: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(fontSize: 22), // Tamaño de fuente aumentado
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Future<String> _getDirectorType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('directorType') ?? '';
  }
}
