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
          return const Center(
              child: Text('Error al obtener el tipo de director'));
        } else {
          final directorType = snapshot.data ?? '';

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Color.fromARGB(255, 40, 140, 1),
              toolbarHeight: 120,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logofet.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Tipo de Director: $directorType',
                    style: TextStyle(
                      fontSize: _calculateTitleFontSize(context),
                    ),
                  ),
                ],
              ),
              centerTitle: true,
            ),
            body: Container(
              color: const Color.fromARGB(120, 40, 140, 1),
              child: Center(
                child: SingleChildScrollView(
                  // Utiliza SingleChildScrollView para agregar la barra de desplazamiento vertical
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(10, (index) {
                      int semesterNumber = index + 1;
                      String semesterText = 'SEMESTRE $semesterNumber';

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20), // Añade un margen horizontal
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pushNamed(context, 'calendar');
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            prefs.setString('semestreType', '$semesterNumber');
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors
                                .green, // Cambia el color de fondo del botón
                            padding: EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal:
                                    30), // Aumenta el espacio en el botón
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  10.0), // Redondea los bordes del botón
                            ),
                            textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold), // Estiliza el texto
                          ),
                          child: Text(
                            semesterText,
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors
                                    .white), // Estiliza el texto del botón
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  double _calculateTitleFontSize(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    double baseFontSize = 17;

    if (screenWidth < 365) {
      baseFontSize = 16;
    } else if (screenWidth < 320) {
      baseFontSize = 14;
    }

    return baseFontSize;
  }

  Future<String> _getDirectorType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('directorType') ?? '';
  }
}
