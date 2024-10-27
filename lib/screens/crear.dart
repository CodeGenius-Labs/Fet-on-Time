import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysql1/mysql1.dart';
import '../base_conection.dart';

class CrearPage extends StatefulWidget {
  const CrearPage({super.key});

  @override
  CrearPageState createState() => CrearPageState();
}

class CrearPageState extends State<CrearPage> {
  MySqlConnection? _connection;
  String semestre = '';
  String directorType = '';
  int estudiantes = 0;
  String selectedJornada = 'diurna';
  List<String> condiciones = [];
  int selectedMateriasId = -1;
  String nombreMateria = '';
  int materiaCreditos = -1;
  List<DropdownMenuItem<Materias>> materiasDropdown = [];
  int selectedDocenteId = -1;
  String nombreDocente = '';
  List<DropdownMenuItem<Docente>> docentesDropdown = [];
  List<String> jornadaOptions = ['diurna', 'nocturna']; // Opciones de jornada
  List<String> customDiasJornadas =
      []; //listado donde guarda las condiciones de los docentes
  List<Clase> horariosOcupadosList = []; // Cambia el tipo de la lista a Clase
  late Future<void> _cargarDatosFuture;
  bool _isLoading = false; // Estado de carga

  Future<void> cargarDatos() async {
    semestre = await obtenerSemestreType();
    directorType = await _getDirectorType();
    _connection = await getConnection();
    loadDropdownOptions(selectedJornada);
    horariosOcupadosList = await getHorariosOcupados();
    printHorariosOcupados(horariosOcupadosList);
  }

  @override
  void initState() {
    super.initState();
    _cargarDatosFuture = cargarDatos();
  }

  final TextEditingController cantidadEstudiantesController =
      TextEditingController();
  @override
  void dispose() {
    _connection?.close();
    super.dispose();
  }

  Future<String> obtenerSemestreType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String semestreType = prefs.getString('semestreType') ?? '';
    return semestreType;
  }

  Future<String> _getDirectorType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('directorType') ?? '';
  }

  // Función para cargar las opciones de los desplegables
  void loadDropdownOptions(selectedJornada) async {
    final docentes = await _fetchDocentes(); // Consultar la lista de docentes
    final materias =
        await _fetchMaterias(selectedJornada); // Consultar la lista de docentes

    setState(() {
      // Construir elementos de desplegable para docentes
      docentesDropdown = docentes
          .map((docente) => DropdownMenuItem<Docente>(
                value: docente,
                child: Text(docente.nombre),
              ))
          .toList();

      materiasDropdown = materias.map((materia) {
        return DropdownMenuItem<Materias>(
          value: materia,
          child: Text(materia.nombre),
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _cargarDatosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Crear Clase'),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Crear Clase'),
            ),
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Crear Clase'),
            ),
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(
                              top: 8.0), // Espaciado solo en la parte superior
                          child: Text('Selecciona una jornada:'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 1.0,
                          ),
                          child: DropdownButton<String>(
                            value: selectedJornada,
                            items: jornadaOptions.map((jornada) {
                              return DropdownMenuItem<String>(
                                value: jornada,
                                child: Text(jornada),
                              );
                            }).toList(),
                            onChanged: (jornada) {
                              setState(() {
                                selectedJornada = jornada!;
                                selectedDocenteId = -1;
                                selectedMateriasId = -1;
                                loadDropdownOptions(
                                    selectedJornada); // Carga las opciones según la jornada seleccionada
                              });
                            },
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                          ),
                          child: DropdownButton<Materias>(
                            //evita el overflow
                            isExpanded: true,
                            value: selectedMateriasId == -1
                                ? null
                                : materiasDropdown
                                    .firstWhere((item) =>
                                        item.value!.id == selectedMateriasId)
                                    .value,
                            items: materiasDropdown,
                            onChanged: (materia) {
                              setState(() {
                                if (materia != null) {
                                  selectedMateriasId = materia.id;
                                  materiaCreditos = materia.creditos;
                                  nombreMateria = materia.nombre;
                                }
                              });
                            },
                            hint: materiasDropdown.isNotEmpty
                                ? const Text('Seleccione una Materia')
                                : const Text('No hay materia disponible'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                          ),
                          child: DropdownButton<Docente>(
                            value: selectedDocenteId == -1
                                ? null
                                : docentesDropdown
                                    .firstWhere((item) =>
                                        item.value!.id == selectedDocenteId)
                                    .value,
                            items: docentesDropdown,
                            onChanged: (docente) {
                              setState(() {
                                selectedDocenteId = docente!.id;
                                nombreDocente = docente.nombre;
                              });
                            },
                            hint: const Text('Seleccione un Docente'),
                          ),
                        ),

                        TextField(
                          controller: cantidadEstudiantesController,
                          decoration: const InputDecoration(
                              labelText: 'Cantidad de estudiantes'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              estudiantes = int.parse(value);
                            });
                          },
                        ),

                        const Text('Condiciones de tiempo:'),
                        // Agrega más CheckboxListTile para otras condiciones de tiempo
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: () {
                            // guardarClase(materiaCreditos);
                            dividirMateria();
                            setState(() {
                              // estudiantes = 0;
                              // Actualiza la lista de dropdown después de cambiar la selección
                              loadDropdownOptions(selectedJornada);
                            });
                          },
                          child: const Text('Guardar Clase'),
                        ),
                      ],
                    ),
                  ),
          );
        }
      },
    );
  }

  void _mostrarDatosClase(
      int selectedMateriasId,
      int selectedDocenteId,
      int idSalon,
      String semestre,
      int posicionDia,
      TimeOfDay inicio,
      TimeOfDay fin,
      String directorType,
      String selectedJornada) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Datos de la clase guardada'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID de la materia: $selectedMateriasId'),
              Text('ID del docente: $selectedDocenteId'),
              Text('ID del salón: $idSalon'),
              Text('Semestre: $semestre'),
              Text('Posición del día: $posicionDia'),
              Text('Hora de inicio: ${inicio.hour}:${inicio.minute}'),
              Text('Hora de fin: ${fin.hour}:${fin.minute}'),
              Text('Tipo de director: $directorType'),
              Text('Jornada seleccionada: $selectedJornada'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void dividirMateria() async {
    int credit = materiaCreditos;

    while (credit > 0) {
      if (credit == 3) {
        // Dividir 3 créditos en 2 + 1

        await guardarClase(2);
        getHorariosOcupados().then((horariosOcupados) {
          setState(() {
            horariosOcupadosList = horariosOcupados;
          });
        });
        credit -= 2;
        print(credit);
      } else if (credit >= 2) {
        // Guardar clase con 2 créditos
        await guardarClase(2);
        getHorariosOcupados().then((horariosOcupados) {
          setState(() {
            horariosOcupadosList = horariosOcupados;
          });
        });
        credit -= 2;
        print(credit);
      } else {
        // Guardar clase con 1 crédito
        await guardarClase(1);
        getHorariosOcupados().then((horariosOcupados) {
          setState(() {
            horariosOcupadosList = horariosOcupados;
          });
        });
        credit -= 1;
        print(credit);
      }
    }

    setState(() {
      // Limpia la lista antes de cargar los nuevos datos
      horariosOcupadosList.clear();
      cantidadEstudiantesController.clear();
      selectedDocenteId = -1;
      selectedMateriasId = -1;
      loadDropdownOptions(selectedJornada);
    });
  }

  Future<void> guardarClase(creditos) async {
    if (selectedMateriasId == -1 ||
        selectedDocenteId == -1 ||
        estudiantes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Por favor, selecciona una materia, un docente y agrega la cantidad de estudiantes.'),
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true; // Muestra el loading
    });

    try {
      final List<FranjaHoraria> franjasHorariasDiurnas =
          obtenerFranjasHorariasDiurnas();
      final List<FranjaHoraria> franjasHorariasNocturnas =
          obtenerFranjasHorariasNocturnas();
      final int duracionClaseMinutos = creditos * 50;
      final diasSemana = [
        'lunes',
        'martes',
        'miercoles',
        'jueves',
        'viernes',
      ];

      bool claseAsignada = false;
      int estudiantesInicial = estudiantes;

      while (!claseAsignada) {
        final List<Map<String, dynamic>> salonesDisponibles =
            await seleccionarSalonDisponible(estudiantesInicial);

        if (salonesDisponibles.isEmpty) {
          // Si no hay más salones disponibles, salir del bucle
          print('No hay más salones disponibles.');
          break;
        }

        for (var libreSalon in salonesDisponibles) {
          final idSalon = libreSalon['idSalon'];

          for (String dia in diasSemana) {
            int posicionDia = diasSemana.indexOf(dia) + 1;
            final List<FranjaHoraria> franjasHorarias =
                selectedJornada == 'diurna'
                    ? franjasHorariasDiurnas
                    : franjasHorariasNocturnas;

            for (FranjaHoraria franja in franjasHorarias) {
              TimeOfDay inicio = franja.inicio;

              while (inicio.hour * 60 + inicio.minute + duracionClaseMinutos <=
                  franja.fin.hour * 60 + franja.fin.minute) {
                TimeOfDay fin = agregarMinutos(inicio, duracionClaseMinutos);
                bool conflict = false;

                final horariosOcupadosList1 = await getHorariosOcupados();
                final horariosJornada = horariosOcupadosList1.where((clase) {
                  return clase.jornada == selectedJornada;
                }).toList();

                for (Clase clase in horariosJornada) {
                  if (clase.idfecha_clase == posicionDia) {
                    int inicioClaseOcupada =
                        clase.horaInicial.hour * 60 + clase.horaInicial.minute;
                    int finClaseOcupada =
                        clase.horaFinal.hour * 60 + clase.horaFinal.minute;

                    int inicioPropuesto = inicio.hour * 60 + inicio.minute;
                    int finPropuesto = fin.hour * 60 + fin.minute;

                    // Verifica si hay superposición de horario
                    if ((inicioPropuesto < finClaseOcupada) &&
                        (finPropuesto > inicioClaseOcupada)) {
                      // Verifica si el semestre está ocupado
                      if (clase.semestre == semestre &&
                          clase.programa == directorType) {
                        conflict = true;
                        print("Conflicto de semestre: $semestre");
                        break; // Sale del bucle si se encuentra un conflicto
                      }
                      // Verifica si el salón está ocupado
                      if (clase.idSalones == idSalon) {
                        conflict = true;

                        print('Intentando con otro salón...');
                        print("Conflicto de salón: $idSalon");
                        break; // Sale del bucle si se encuentra un conflicto
                      }
                      // Verifica si el docente está ocupado
                      if (clase.idDocentes == selectedDocenteId) {
                        conflict = true;
                        print("Conflicto de docente: $selectedDocenteId");
                        break; // Sale del bucle si se encuentra un conflicto
                      }
                    }
                  }
                }

                if (!conflict) {
                  // Asigna la clase

                  await _connection!.query(
                    'INSERT INTO clases(idmaterias, idDocentes, idSalones, semestre, idfecha_clase, hora_inicial, hora_final, programa, jornada) VALUES (?,?,?,?,?,?,?,?,?)',
                    [
                      selectedMateriasId,
                      selectedDocenteId,
                      idSalon,
                      semestre,
                      posicionDia,
                      '${inicio.hour}:${inicio.minute}',
                      '${fin.hour}:${fin.minute}',
                      directorType,
                      selectedJornada
                    ],
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Clase guardada exitosamente.'),
                    ),
                  );
                  _mostrarDatosClase(
                      selectedMateriasId,
                      selectedDocenteId,
                      idSalon,
                      semestre,
                      posicionDia,
                      inicio,
                      fin,
                      directorType,
                      selectedJornada);

                  // if (mounted) {
                  //   setState(() {
                  //     // Limpia la lista antes de cargar los nuevos datos
                  //     horariosOcupadosList.clear();
                  //     cantidadEstudiantesController.clear();
                  //     selectedDocenteId = -1;
                  //     selectedMateriasId = -1;
                  //     loadDropdownOptions(selectedJornada);
                  //   });
                  // }

                  // Vuelve a cargar los datos de la base de datos
                  // getHorariosOcupados().then((horariosOcupados) {
                  //   if (mounted) {
                  //     setState(() {
                  //       horariosOcupadosList = horariosOcupados;
                  //     });
                  //   }
                  // });

                  claseAsignada = true;
                  break;
                }

                inicio = agregarMinutos(inicio,
                    50); // Intentar con el siguiente bloque de 50 minutos
              }

              if (claseAsignada) break;
            }

            if (claseAsignada) break;
          }
        }

        if (!claseAsignada) {
          // reintentar con otro profesor

          setState(() {
            // Limpia la lista antes de cargar los nuevos datos
            // horariosOcupadosList.clear();
            // cantidadEstudiantesController.clear();
            // selectedDocenteId = -1;
            // selectedMateriasId = -1;
            // loadDropdownOptions(selectedJornada);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('No se pudo asignar la clase.selecciona otro profesor'),
            ),
          );
          break;
        }
        print('Reintenta con otro docente: $selectedDocenteId');
      }
    } catch (e) {
      print('Error al guardar la clase: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Oculta el loading
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> seleccionarSalonDisponible(
      int capacidadRequerida) async {
    List<Map<String, dynamic>> salonesDisponibles = [];
    try {
      print('Inicio seleccionar salón');
      final results = await _connection!.query(
        'SELECT CONCAT(bloque, " ", aula) AS nombre_completo, idSalones, sillas FROM salones WHERE sillas >= ? ORDER BY sillas ASC',
        [capacidadRequerida],
      );
      final resultList = results.toList();

      if (resultList.isNotEmpty) {
        for (var salon in resultList) {
          salonesDisponibles.add({
            'nombre_completo': salon['nombre_completo'],
            'idSalon': salon['idSalones'],
            'sillas': salon['sillas'],
          });
        }
        print('Salones encontrados: ${salonesDisponibles.length}');
      } else {
        // No se encontraron salones aptos
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No se encontraron salones con capacidad suficiente.'),
          ),
        );
      }
    } catch (e) {
      // Manejo de errores
      print('Error al seleccionar salón: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al buscar salones con capacidad suficiente.'),
        ),
      );
      throw Exception('No se encontraron salones con capacidad suficiente.');
    }

    return salonesDisponibles;
  }

  // Obtener franjas horarias diurnas
  List<FranjaHoraria> obtenerFranjasHorariasDiurnas() {
    return [
      FranjaHoraria(const TimeOfDay(hour: 7, minute: 0),
          const TimeOfDay(hour: 9, minute: 30)),
      FranjaHoraria(const TimeOfDay(hour: 10, minute: 0),
          const TimeOfDay(hour: 11, minute: 40)),
      // Puedes agregar más franjas si es necesario
    ];
  }

  // Obtener franjas horarias nocturnas
  List<FranjaHoraria> obtenerFranjasHorariasNocturnas() {
    return [
      FranjaHoraria(const TimeOfDay(hour: 18, minute: 30),
          const TimeOfDay(hour: 20, minute: 10)),
      FranjaHoraria(const TimeOfDay(hour: 20, minute: 30),
          const TimeOfDay(hour: 22, minute: 10)),
      // Puedes agregar más franjas si es necesario
    ];
  }

  TimeOfDay agregarMinutos(TimeOfDay time, int minutes) {
    final int totalMinutes = time.hour * 60 + time.minute + minutes;
    final int hours = totalMinutes ~/ 60;
    final int mins = totalMinutes % 60;
    return TimeOfDay(hour: hours, minute: mins);
  }

  Future<List<Clase>> getHorariosOcupados() async {
    final results = await _connection!.query('''
    SELECT TIME_FORMAT(c.hora_inicial, "%H:%i") AS hora_inicial,
           TIME_FORMAT(c.hora_final, "%H:%i") AS hora_final,
           c.jornada,
           fc.dias AS nombre_dias,
           c.idSalones,
           c.idClases,
           c.idmaterias,
           c.idDocentes,
           c.semestre,
           c.programa,
           c.idfecha_clase
    FROM clases c
    INNER JOIN fecha_clase fc ON c.idfecha_clase = fc.idfecha_clase
  ''');
    final horariosOcupados = <Clase>[];

    for (var row in results) {
      // print(row['hora_inicial']);
      final clase = Clase(
        id: row['idClases'],
        idMaterias: row['idmaterias'],
        idDocentes: row['idDocentes'],
        idSalones: row['idSalones'],
        semestre: row['semestre'],
        horaInicial: TimeOfDay(
            hour: int.parse(row['hora_inicial'].split(':')[0]),
            minute: int.parse(row['hora_inicial'].split(':')[1])),
        horaFinal: TimeOfDay(
            hour: int.parse(row['hora_final'].split(':')[0]),
            minute: int.parse(row['hora_final'].split(':')[1])),
        programa: row['programa'],
        jornada: row['jornada'],
        idfecha_clase: row[
            'idfecha_clase'], // Asegúrate de que esta columna exista en tu tabla
      );
      horariosOcupados.add(clase);
    }
    return horariosOcupados;
  }

  void printHorariosOcupados(List<Clase> horariosOcupados) {
    for (var clase in horariosOcupados) {
      print(
          'Clase ID: ${clase.id}, Salon ID: ${clase.idSalones}, Hora Inicial: ${clase.horaInicial}, Hora Final: ${clase.horaFinal}, Jornada: ${clase.jornada}, Día: ${clase.idfecha_clase}');
    }
  }

  Future<List<Materias>> _fetchMaterias(String selectedJornada) async {
    final results = await _connection!.query(
        'SELECT m.id, m.Nombre, m.creditos FROM materias m '
        'LEFT JOIN clases c ON m.id = c.idmaterias AND c.jornada = ? '
        'WHERE m.Semestre = ? AND c.idmaterias IS NULL AND m.programa = ?',
        [selectedJornada, semestre, directorType]);
    if (results.isNotEmpty) {
      final allMaterias = results
          .map((row) => Materias(
              row['id'] ?? -1, row['Nombre'] ?? '', row['creditos'] ?? -1))
          .toList();
      return allMaterias;
    } else {
      return [];
    }
  }

  Future<List<Docente>> _fetchDocentes() async {
    final results =
        await _connection!.query('SELECT idDocentes, Nombre FROM docentes');

    if (results.isNotEmpty) {
      return results
          .map((row) => Docente(row['idDocentes'] ?? -1, row['Nombre'] ?? ''))
          .toList();
    } else {
      return [];
    }
  }
}

class Clase {
  final int id;
  final int idMaterias;
  final int idDocentes;
  final int idSalones;
  final String semestre;
  final TimeOfDay horaInicial;
  final TimeOfDay horaFinal;
  final String programa;
  final String jornada;
  final int idfecha_clase; // Asegúrate de que esta propiedad esté en tu tabla

  Clase({
    required this.id,
    required this.idMaterias,
    required this.idDocentes,
    required this.idSalones,
    required this.semestre,
    required this.horaInicial,
    required this.horaFinal,
    required this.programa,
    required this.jornada,
    required this.idfecha_clase,
  });
}

class FranjaHoraria {
  TimeOfDay inicio;
  TimeOfDay fin;

  FranjaHoraria(this.inicio, this.fin);
}

class Docente {
  final int id;
  final String nombre;

  Docente(this.id, this.nombre);
}

class Materias {
  final int id;
  final String nombre;
  final int creditos;

  Materias(this.id, this.nombre, this.creditos);
}
