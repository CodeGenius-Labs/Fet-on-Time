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
          // Por ejemplo, puedes almacenarlos en una variable de estado.
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
  void _openAgregarDiasJornadasDialog(BuildContext context) {
    String nuevoDia = 'Lunes'; // Variable para el día ingresado
    String nuevaJornada = 'diurna'; // Variable para la jornada ingresada

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Días y Jornadas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: nuevoDia,
                items: [
                  'Lunes',
                  'Martes',
                  'Miércoles',
                  'Jueves',
                  'Viernes',
                  'Sábado',
                  'Domingo',
                ].map((dia) {
                  return DropdownMenuItem<String>(
                    value: dia,
                    child: Text(dia),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    nuevoDia = value!;
                  });
                },
                hint: const Text('Selecciona un día'),
              ),
              DropdownButton<String>(
                value: nuevaJornada,
                items: jornadaOptions.map((jornada) {
                  return DropdownMenuItem<String>(
                    value: jornada,
                    child: Text(jornada),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    nuevaJornada = value!;
                  });
                },
                hint: const Text('Selecciona una jornada'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (nuevoDia.isNotEmpty && nuevaJornada.isNotEmpty) {
                  // Verifica que los campos no estén vacíos
                  setState(() {
                    // Agregar los datos ingresados a la lista
                    customDiasJornadas.add('$nuevoDia $nuevaJornada');
                  });
                  print(customDiasJornadas);
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
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
              decoration: const InputDecoration(labelText: 'Cantidad de estudiantes'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  estudiantes = int.parse(value);
                });
              },
            ),

            const Padding(
              padding: EdgeInsets.only(top: 8.0), // Espaciado solo en la parte superior
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
            ElevatedButton(
              onPressed: () {
                _openAgregarDiasJornadasDialog(context); // Llama a la función para abrir el diálogo
              },
              child: const Text('Condiciones Docentes'),
            ),

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

  void _guardarClase() async {
    // Verificar que se hayan seleccionado una materia, docente y que la cantidad de estudiantes no sea cero
    if (selectedMateriasId == -1 || selectedDocenteId == -1 || estudiantes == 0) {
      // Mostrar un mensaje de error o realizar alguna acción apropiada
      // Puedes utilizar un ScaffoldMessenger para mostrar un SnackBar con el mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una materia, un docente y especifica la cantidad de estudiantes.'),
        ),
      );
      return;
    }

   //-------------------------------INICIO LOGICA--------------------------------------------
    /*final salonId = salon['idSalon'];
    final salonNombre = salon['nombre_salon'];*/
    print("INICIO LOGICA");
    final libre = await seleccionarDiaYHorasDisponibles(selectedJornada, estudiantes, materiaCreditos);
    final salonNombre = libre['nombre_completo'];
    final idSalon = libre['idSalon'];
    final creditoMateria = materiaCreditos;
    print('''
        semestre: $semestre
        Credito: $creditoMateria
        Nombre Materia: $nombreMateria
        Cantidad estudiantes: $estudiantes
        Docente: $nombreDocente
        salon: $idSalon $salonNombre
        jornada: $selectedJornada
    ''');




    //-----------------------------------FINAL LOGICA----------------------------------------
    // Ejemplo de cómo insertar datos en la base de datos utilizando el paquete mysql1:
    /*try {
      print('INSERT INTO clases(idmaterias, idDocentes, idSalones, semestre, idfecha_clase, hora_inicial, hora_final, programa, jornada) VALUES ($selectedMateriasId, $selectedDocenteId, $idSalon, $semestre, $diaDisp, $horaInicioStr, $horaFinStr, $directorType, $selectedJornada)');
      final result = await _connection!.query(
        'INSERT INTO clases(idmaterias, idDocentes, idSalones, semestre, idfecha_clase, hora_inicial, hora_final, programa, jornada) VALUES (?,?,?,?,?,?,?,?,?)',
        [selectedMateriasId, selectedDocenteId, idSalon, semestre, diaDisp, horaInicioStr, horaFinStr, directorType, selectedJornada],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clase guardada exitosamente.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al guardar la clase. Por favor, inténtalo de nuevo.'),
        ),
      );
      // Manejar cualquier error que pueda ocurrir durante la eliminación
      print('Error al crear la clase: $e');
      // Puedes mostrar un mensaje de error al usuario si es necesario
    }*/
  }

  Future<Map<String, dynamic>> seleccionarDiaYHorasDisponibles(String jornada, int capacidadRequerida, int materiaCreditos) async {
    // Realiza una consulta en la base de datos para obtener los salones aptos
    /*const horaInicio1 = TimeOfDay(hour: 7, minute: 50);
    const horaFin1 = TimeOfDay(hour: 8, minute: 40);
    const horaInicio2 = TimeOfDay(hour: 8, minute: 40);
    const horaFin2 = TimeOfDay(hour: 9, minute: 30);
    const horaInicio3 = TimeOfDay(hour: 10, minute: 00);
    const horaFin3 = TimeOfDay(hour: 10, minute: 50);
    const horaInicio4 = TimeOfDay(hour: 10, minute: 50);
    const horaFin4 = TimeOfDay(hour: 11, minute: 40);

    const horaInicio5 = TimeOfDay(hour: 18, minute: 30);
    const horaFin5 = TimeOfDay(hour: 19, minute: 20);
    const horaInicio6 = TimeOfDay(hour: 19, minute: 20);
    const horaFin6 = TimeOfDay(hour: 20, minute: 10);
    const horaInicio7 = TimeOfDay(hour: 20, minute: 30);
    const horaFin7 = TimeOfDay(hour: 21, minute: 20);
    const horaInicio8 = TimeOfDay(hour: 21, minute: 20);
    const horaFin8 = TimeOfDay(hour: 22, minute: 10);*/

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

  Future<List<Clase>> getHorariosOcupados() async {
    final results = await _connection!.query('''
    SELECT TIME_FORMAT(c.hora_inicial, "%H:%i:%s") AS hora_inicial,
           TIME_FORMAT(c.hora_final, "%H:%i:%s") AS hora_final,
           c.jornada,
           fc.dias AS nombre_dias,
           c.idSalones
    FROM clases c
    INNER JOIN fecha_clase fc ON c.idfecha_clase = fc.idfecha_clase
  ''');

    if (results.isNotEmpty) {
      // Mapear resultados de la base de datos a objetos Clase
      return results.map((row) {
        final horaInicialString = row['hora_inicial'];
        final horaFinalString = row['hora_final'];

        final horaInicial = TimeOfDay(
          hour: int.parse(horaInicialString.split(":")[0]),
          minute: int.parse(horaInicialString.split(":")[1]),
        );

        final horaFinal = TimeOfDay(
          hour: int.parse(horaFinalString.split(":")[0]),
          minute: int.parse(horaFinalString.split(":")[1]),
        );

        return Clase(
          horaInicial: horaInicial,
          horaFinal: horaFinal,
          jornada: row['jornada'] ?? '',
          fechaClase: row['nombre_dias'] ?? '',
          idSalones: row['idSalones'] ?? -1,
        );
      }).toList();
    } else {
      return [];
    }
  }

  void printHorariosOcupados(List<Clase> horarios) {
    for (var horario in horarios) {
      print('Hora inicial: ${horario.horaInicial}');
      print('Hora final: ${horario.horaFinal}');
      print('Jornada: ${horario.jornada}');
      print('Fecha de Clase: ${horario.fechaClase}');
      print('ID Clase: ${horario.idSalones}');
      print('---'); // Un separador para cada registro
    }
  }
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

class Clase {
  final TimeOfDay horaInicial;
  final TimeOfDay horaFinal;
  final String jornada;
  final String fechaClase;
  final int idSalones;

  Clase({required this.horaInicial, required this.horaFinal, required this.jornada, required this.fechaClase, required this.idSalones});
}

