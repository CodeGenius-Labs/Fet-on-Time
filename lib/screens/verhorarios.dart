import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:core';
import 'package:mysql1/mysql1.dart';
import '../base_conection.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class VerHorarios extends StatefulWidget {
  const VerHorarios({super.key});

  @override
  _VerHorariosState createState() => _VerHorariosState();
}

class _VerHorariosState extends State<VerHorarios> {
  MySqlConnection? _connection;
  String directorType = '';
  String semestre = '';

  @override
  void initState() {
    super.initState();
    getConnection().then((connection) {
      setState(() {
        _connection = connection;
      });
    });
    // Llama a _getDirectorType() para obtener el valor de directorType
    _getDirectorType().then((value) {
      setState(() {
        directorType = value;
      });
    });
  }

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
              backgroundColor: const Color.fromARGB(255, 40, 140, 1),
              toolbarHeight: 120,
              automaticallyImplyLeading: false,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...List.generate(10, (index) {
                        int semesterNumber = index + 1;
                        String semesterText = 'SEMESTRE $semesterNumber';

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20,
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pushNamed(context, 'calendar');
                              SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                              prefs.setString(
                                  'semestreType', '$semesterNumber');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 30,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Text(
                              semesterText,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }),
                      // Aquí agregamos el botón para descargar todos los horarios
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            _downloadAllSchedules(); // Llamamos a la función de descarga
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 30,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text(
                            'Descargar Todos los Horarios',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Botón de volver
                      Container(
                        margin: const EdgeInsets.only(
                            top: 12,
                            bottom:
                            12), // Margen en la parte superior e inferior
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                                context); // Esto te llevará a la página anterior
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 10),
                          ),
                          child: const Text(
                            'Volver',
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ],
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

  Future<void> _downloadAllSchedules() async {
    try {
      final excel = Excel.createExcel();
      final Sheet sheet = excel['Horario Total'];

      // Obtener los datos de la base de datos
      final results = await _connection!.query(
        'SELECT m.nombre AS nombre_clase, d.Nombre AS nombre_docente, '
            'CONCAT(s.bloque, "-", s.aula) AS ubicacion_salon, fc.dias AS dias, '
            'c.hora_inicial AS hora_inicial, c.hora_final AS hora_final, '
            'c.jornada AS jornada, c.semestre AS semestre FROM clases c '
            'INNER JOIN docentes d ON c.idDocentes = d.idDocentes '
            'INNER JOIN materias m ON c.idmaterias = m.id '
            'INNER JOIN salones s ON c.idSalones = s.idSalones '
            'INNER JOIN fecha_clase fc ON c.idfecha_clase = fc.idfecha_clase '
            'WHERE c.programa = ? '  // Filtra por semestre
            'ORDER BY fc.dias, c.hora_inicial, c.semestre',  // Ordenar por días y horas
        [directorType],  // Pasa tanto el tipo de director como el semestre
      );



      // Añadir encabezados con estilo
      sheet.appendRow([
        'Clase',
        'Docente',
        'Ubicación',
        'Días',
        'Hora Inicial',
        'Hora Final',
        'Jornada'
      ]);

      var headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: "#D3D3D3",
        horizontalAlign: HorizontalAlign.Center,
      );

      for (var col = 0; col < 7; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          ..cellStyle = headerStyle;
      }

      // Ajustar el ancho de las columnas
      for (var i = 0; i < 7; i++) {
        sheet.setColAutoFit(i);
      }

      // Añadir los datos
      for (var row in results) {
        // Quitar los milisegundos y asegurar formato HH:mm:ss
        String formatHora(String? hora) {
          if (hora == null || hora.isEmpty) return '00:00:00';
          return hora.split('.').first; // Divide por '.' y toma la primera parte
        }

        String horaInicial = formatHora(row['hora_inicial']?.toString());
        String horaFinal = formatHora(row['hora_final']?.toString());

        sheet.appendRow([
          row['nombre_clase'] ?? 'N/A',
          row['nombre_docente'] ?? 'N/A',
          row['ubicacion_salon'] ?? 'N/A',
          row['dias'] ?? 'N/A',
          horaInicial,
          horaFinal,
          row['jornada'] ?? 'N/A',
        ]);
      }
      sheet.setColWidth(1, 35); // Cambia el ancho de la columna 2 (índice empieza en 1)
      sheet.setColWidth(0, 20); // Cambia el ancho de la columna 2 (índice empieza en 1)

      // Guardar el archivo
      final directory = Directory('/storage/emulated/0/Download');
      final String fileName =
          'horario_semestre_${semestre}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final String filePath = '${directory.path}/$fileName';

      final List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Horario exportado exitosamente a: $filePath'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error al exportar: $e');
    }
  }
}
