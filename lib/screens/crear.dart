import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysql1/mysql1.dart';
import '../base_conection.dart';

class CrearPage extends StatefulWidget {
  const CrearPage({super.key});

  @override
  _CrearPageState createState() => _CrearPageState();
}

class _CrearPageState extends State<CrearPage> {
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
  List<String> customDiasJornadas = []; //listado donde guarda las condiciones de los docentes
  List<Clase> horariosOcupadosList = []; // Cambia el tipo de la lista a Clase

  @override
  void initState() {
    super.initState();
    obtenerSemestreType().then((value) {
      setState(() {
        semestre = value;
      });
    });
    _getDirectorType().then((value) {
      setState(() {
        directorType = value;
      });
      // Cargar datos adicionales según el tipo de director
    });
    getConnection().then((connection) {
      setState(() {
        _connection = connection;
      });
      loadDropdownOptions(); // Cargar opciones de desplegables al obtener la conexión
      getHorariosOcupados().then((horariosOcupados) {
        // Aquí puedes usar los horarios ocupados como sea necesario
        setState(() {
          // Actualiza el estado con los horarios ocupados
          horariosOcupadosList = horariosOcupados;
          printHorariosOcupados(horariosOcupadosList);
        });
      });
    });
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
  void loadDropdownOptions() async {
    final docentes = await _fetchDocentes(); // Consultar la lista de docentes
    final materias = await _fetchMaterias(); // Consultar la lista de docentes

    setState(() {
      // Construir elementos de desplegable para docentes
      docentesDropdown = docentes
          .map((docente) => DropdownMenuItem<Docente>(
        value: docente,
        child: Text(docente.nombre),
      ))
          .toList();

      materiasDropdown = materias
          .map((materias) => DropdownMenuItem<Materias>(
        value: materias,
        child: Text(materias.nombre),
      ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Clase'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
              ),
              child: DropdownButton<Materias>(
                value: selectedMateriasId == -1
                    ? null
                    : materiasDropdown
                    .firstWhere(
                        (item) => item.value!.id == selectedMateriasId)
                    .value,
                items: materiasDropdown,
                onChanged: (materia) {
                  setState(() {
                    selectedMateriasId = materia!.id;
                    materiaCreditos = materia.creditos;
                    nombreMateria = materia.nombre;
                  });
                },
                hint: const Text('Seleccione una Materia'),
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
                    .firstWhere(
                        (item) => item.value!.id == selectedDocenteId)
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
              decoration: const InputDecoration(
                  labelText: 'Cantidad de estudiantes'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  estudiantes = int.parse(value);
                });
              },
            ),
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
                  });
                },
              ),
            ),
            const Text('Condiciones de tiempo:'),
            // Agrega más CheckboxListTile para otras condiciones de tiempo
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _guardarClase();
              },
              child: const Text('Guardar Clase'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDatosClase(int selectedMateriasId, int selectedDocenteId, int idSalon, String semestre, int posicionDia, TimeOfDay inicio, TimeOfDay fin, String directorType, String selectedJornada) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Datos de la clase guardada'),
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
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _guardarClase() async {
    if (selectedMateriasId == -1 || selectedDocenteId == -1 || estudiantes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Por favor, selecciona una materia, un docente y agrega la cantidad de estudiantes.'),
        ),
      );
      return;
    }

    final List<FranjaHoraria> franjasHorarias = obtenerFranjasHorariasDiurnas();
    final int duracionClaseMinutos = materiaCreditos * 50;
    final diasSemana = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado'];
    final libreSalon = await SeleccionarSalonDisponible(selectedJornada, estudiantes, materiaCreditos);
    final salonNombre = libreSalon['nombre_completo'];
    final idSalon = libreSalon['idSalon'];

    for (String dia in diasSemana) {
      int posicionDia = diasSemana.indexOf(dia) + 1;
      print("posicion dia es: $posicionDia");
      for (FranjaHoraria franja in franjasHorarias) {
        TimeOfDay inicio = franja.inicio;

        while (inicio.hour * 60 + inicio.minute + duracionClaseMinutos <=
            franja.fin.hour * 60 + franja.fin.minute) {
          TimeOfDay fin = agregarMinutos(inicio, duracionClaseMinutos);
          bool conflict = false;
          print("hola 1");
          for (Clase clase in horariosOcupadosList) {         //ACA QUEDE
            print("hola 2");
            print("Salon: " + (clase.idSalones == idSalon).toString());
            print("Docente: " + (clase.idDocentes == selectedDocenteId).toString());
            print("Fecha_Clase: " + (clase.idfecha_clase == posicionDia).toString());
            print("Horas: " + (!estaDisponible(clase, inicio, fin)).toString());

            if (clase.idSalones == idSalon && clase.idDocentes == selectedDocenteId &&
                clase.idfecha_clase == posicionDia &&
                estaDisponible(clase, inicio, fin)) {
              conflict = true;
              break;
            }
          }
          print("hola 3");

          if (!conflict) {
            // Asigna la clase
            final result = await _connection!.query(
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

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Clase guardada exitosamente.'),
              ),
            );
            _mostrarDatosClase(selectedMateriasId, selectedDocenteId, idSalon, semestre, posicionDia, inicio, fin, directorType, selectedJornada);
            setState(() {
              // Limpia la lista antes de cargar los nuevos datos
              horariosOcupadosList.clear();
            });

            // Vuelve a cargar los datos de la base de datos
            getHorariosOcupados().then((horariosOcupados) {
              setState(() {
                horariosOcupadosList = horariosOcupados;
              });
            });
            return;
          }

          inicio = agregarMinutos(inicio, 50); // Intentar con el siguiente bloque de 50 minutos
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se encontró un horario disponible para la clase.'),
      ),
    );
  }

  Future<Map<String, dynamic>> SeleccionarSalonDisponible(String jornada, int capacidadRequerida, int materiaCreditos) async {

    String nombrecompleto = '';
    int idSalon = -1;
    int selectedSalonIndex = 0;

    print('Inicio seleccionar salon');
    final results = await _connection!.query(
      'SELECT CONCAT(bloque, " ", aula) AS nombre_completo, idSalones FROM salones WHERE sillas >= ? ORDER BY sillas ASC',
      [capacidadRequerida],
    );
    final resultList = results.toList();
    if (results.isNotEmpty) {
      while(selectedSalonIndex < resultList.length){
        // Selecciona el primer salón con suficiente capacidad
        final salonSeleccionado = resultList[selectedSalonIndex];
        idSalon = salonSeleccionado['idSalones'];
        nombrecompleto = salonSeleccionado['nombre_completo'];
        print('idsalon: $idSalon nombre: $nombrecompleto');

        final clasesEnBaseDeDatos = await getHorariosOcupados();
        final clasesEnSalon = clasesEnBaseDeDatos.where((clase) => clase.jornada == jornada).toList();
        final clasesEnJornada = clasesEnSalon.where((clase) => clase.idSalones == idSalon).toList();


        final diasSemana = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];
        selectedSalonIndex = resultList.length + 1;

        print('selectindex: $selectedSalonIndex result: ${resultList.length}');

      }
    } else {
      // No se encontraron salones aptos, puedes devolver un valor por defecto o lanzar una excepción
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontraron salones con capacidad suficiente.'),
        ),
      );
      throw Exception('No se encontraron salones con capacidad suficiente.');
    }

    return {
      'nombre_completo': nombrecompleto,
      'idSalon': idSalon,
    };
  }

  // Obtener franjas horarias diurnas
  List<FranjaHoraria> obtenerFranjasHorariasDiurnas() {
    return [
      FranjaHoraria(TimeOfDay(hour: 7, minute: 0), TimeOfDay(hour: 9, minute: 30)),
      FranjaHoraria(TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 13, minute: 0)),
      // Puedes agregar más franjas si es necesario
    ];
  }

  bool estaDisponible(Clase claseExistente, TimeOfDay inicio, TimeOfDay fin) {
    // Verificar si hay un conflicto de horario
    print("Primera condicion ${inicio.hour} < ${claseExistente.horaFinal.hour} = " + (inicio.hour < claseExistente.horaFinal.hour).toString());
    print("Segunda condicion ${fin.hour} > ${claseExistente.horaInicial.hour} = " + (fin.hour > claseExistente.horaInicial.hour).toString());
    print("Final = " + (!(inicio.hour < claseExistente.horaFinal.hour &&
        fin.hour > claseExistente.horaInicial.hour)).toString());
    return !(inicio.hour < claseExistente.horaFinal.hour &&
        fin.hour > claseExistente.horaInicial.hour);
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
      print(row['hora_inicial']);
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
        idfecha_clase: row['idfecha_clase'], // Asegúrate de que esta columna exista en tu tabla
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

  Future<List<Materias>> _fetchMaterias() async {
    final results = await _connection!.query('SELECT id, Nombre, creditos FROM materias WHERE Semestre = ?',[semestre]);

    if (results.isNotEmpty) {
      return results
          .map((row) => Materias(row['id'] ?? -1, row['Nombre'] ?? '',row['creditos'] ?? -1))
          .toList();
    } else {
      return [];
    }
  }

  Future<List<Docente>> _fetchDocentes() async {
    final results = await _connection!.query('SELECT idDocentes, Nombre FROM docentes');

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
