import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysql1/mysql1.dart';
import '../base_conection.dart';
import 'package:intl/intl.dart';

class CrearPage extends StatefulWidget {
  @override
  _CrearPageState createState() => _CrearPageState();
}

class _CrearPageState extends State<CrearPage> {
  MySqlConnection? _connection;
  int estudiantes = 0;
  String selectedJornada = 'diurna';
  List<String> condiciones = [];
  int selectedMateriasId = -1;
  List<DropdownMenuItem<Materias>> materiasDropdown = [];
  int selectedDocenteId = -1;
  List<DropdownMenuItem<Docente>> docentesDropdown = [];
  List<String> jornadaOptions = ['diurna', 'nocturna']; // Opciones de jornada
  List<String> customDiasJornadas = []; //listado donde guarda las condiciones de los docentes
  List<Clase> horariosOcupadosList = []; // Cambia el tipo de la lista a Clase

  @override
  void initState() {
    super.initState();
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
    String nuevoDia = 'lunes'; // Variable para el día ingresado
    String nuevaJornada = 'diurna'; // Variable para la jornada ingresada

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar Días y Jornadas'),
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
                hint: Text('Selecciona un día'),
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
                hint: Text('Selecciona una jornada'),
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
              child: Text('Guardar'),
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
        title: Text('Crear Clase'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
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
                  });
                },
                hint: Text('Seleccione una Materia'),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
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
                  });
                },
                hint: Text('Seleccione un Docente'),
              ),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Cantidad de estudiantes'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  estudiantes = int.parse(value);
                });
              },
            ),

            Padding(
              padding: EdgeInsets.only(top: 8.0), // Espaciado solo en la parte superior
              child: Text('Selecciona una jornada:'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
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
            Text('Condiciones de tiempo:'),
            ElevatedButton(
              onPressed: () {
                _openAgregarDiasJornadasDialog(context); // Llama a la función para abrir el diálogo
              },
              child: Text('Condiciones Docentes'),
            ),

            // Agrega más CheckboxListTile para otras condiciones de tiempo
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _guardarClase();
              },
              child: Text('Guardar Clase'),
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
        SnackBar(
          content: Text('Por favor, selecciona una materia, un docente y especifica la cantidad de estudiantes.'),
        ),
      );
      return;
    }

   //-------------------------------INICIO LOGICA--------------------------------------------
    final salon = await _seleccionarSalon(estudiantes);
    final salonId = salon['idSalon'];
    final salonNombre = salon['nombre_salon'];

    final libre = await seleccionarDiaYHorasDisponibles(selectedJornada);
    final diaDisp = libre['diaDisponible'];
    final hora_inicio = libre['horaInicioDisponible'];
    final hora_final = libre['horaFinDisponible'];

    print('''
        salon: $salonId $salonNombre
        dia: $diaDisp
        hora inicial: $hora_inicio
        hora final: $hora_final
    ''');



    //-----------------------------------FINAL LOGICA----------------------------------------
/*
    // Ejemplo de cómo insertar datos en la base de datos utilizando el paquete mysql1:
    final result = await _connection!.query(
      'INSERT INTO clases (materia_id, docente_id, cantidad_estudiantes, jornada) '
          'VALUES (?, ?, ?, ?)',
      [selectedMateriasId, selectedDocenteId, estudiantes, selectedJornada],
    );

    if (result != null) {
      // La inserción fue exitosa
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Clase guardada exitosamente.'),
        ),
      );

      // Puedes realizar otras acciones necesarias después de guardar la clase, como limpiar los campos, etc.
      // También puedes navegar a otra pantalla si es necesario.
    } else {
      // Ocurrió un error al guardar la clase
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrió un error al guardar la clase. Por favor, inténtalo de nuevo.'),
        ),
      );
    }*/
  }

  Future<Map<String, dynamic>> _seleccionarSalon(int capacidadRequerida) async {
    // Realiza una consulta en la base de datos para obtener los salones aptos
    final results = await _connection!.query(
      'SELECT CONCAT(bloque, " ", aula) AS nombre_completo, idSalones FROM salones WHERE sillas >= ? ORDER BY sillas ASC',
      [capacidadRequerida],
    );

    if (results.isNotEmpty) {

      // Selecciona el primer salón con suficiente capacidad
      final salonSeleccionado = results.first;

      // Retorna la ID y el nombre del salón seleccionado
      return {
        'idSalon': salonSeleccionado['idSalones'],
        'nombre_salon': salonSeleccionado['nombre_completo'],
      };
    } else {
      // No se encontraron salones aptos, puedes devolver un valor por defecto o lanzar una excepción
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se encontraron salones con capacidad suficiente.'),
        ),
      );
      throw Exception('No se encontraron salones con capacidad suficiente.');
    }
  }

  Future<Map<String, dynamic>> seleccionarDiaYHorasDisponibles(String jornada) async {
    final horaInicio1 = TimeOfDay(hour: 7, minute: 50);
    final horaFin1 = TimeOfDay(hour: 9, minute: 30);
    final horaInicio2 = TimeOfDay(hour: 10, minute: 0);
    final horaFin2 = TimeOfDay(hour: 11, minute: 40);
    final horaInicio3 = TimeOfDay(hour: 18, minute: 30);
    final horaFin3 = TimeOfDay(hour: 20, minute: 10);
    final horaInicio4 = TimeOfDay(hour: 20, minute: 30);
    final horaFin4 = TimeOfDay(hour: 22, minute: 10);

    int timeOfDayToMinutes(TimeOfDay time) {
      return time.hour * 60 + time.minute;
    }

    final clasesEnBaseDeDatos = await getHorariosOcupados();
    final clasesEnJornada = clasesEnBaseDeDatos.where((clase) => clase.jornada == jornada).toList();

    String diaDisponible = '';
    TimeOfDay horaInicioDisponible = horaInicio1;
    TimeOfDay horaFinDisponible = horaFin1;

    final diasSemana = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];

    for (final dia in diasSemana) {
      final clasesEnDia = clasesEnJornada.where((clase) => clase.fechaClase.toLowerCase() == dia).toList();
      /*print('''
        jornada: ${clasesEnDia.first.jornada}
        jornada: ${clasesEnDia.first.fechaClase}
        jornada: ${clasesEnDia.first.horaFinal}
        jornada: ${clasesEnDia.first.horaInicial}
        ''');*/
      if (clasesEnDia.isEmpty) {
        diaDisponible = dia;
        horaInicioDisponible = horaInicio1;
        horaFinDisponible = horaFin4;
        break;  // Puedes detener la iteración si se encuentra un día libre
      } else {
        clasesEnDia.sort((a, b) => timeOfDayToMinutes(a.horaInicial).compareTo(timeOfDayToMinutes(b.horaInicial)));
        if ((timeOfDayToMinutes(clasesEnDia.first.horaInicial) >= timeOfDayToMinutes(horaFin1)  && timeOfDayToMinutes(clasesEnDia.first.horaFinal) <= timeOfDayToMinutes(horaFin2)) && (timeOfDayToMinutes(clasesEnDia.last.horaInicial) >= timeOfDayToMinutes(horaFin1)  && timeOfDayToMinutes(clasesEnDia.last.horaFinal) <= timeOfDayToMinutes(horaFin2))) {
          diaDisponible = "1 $dia";
          horaInicioDisponible = horaInicio1;
          horaFinDisponible = horaFin1;
          break;  // Puedes detener la iteración si se encuentra un día libre
        } else if ((timeOfDayToMinutes(clasesEnDia.first.horaInicial) >= timeOfDayToMinutes(horaInicio1)  && timeOfDayToMinutes(clasesEnDia.first.horaFinal) <= timeOfDayToMinutes(horaInicio2)) && (timeOfDayToMinutes(clasesEnDia.last.horaInicial) >= timeOfDayToMinutes(horaInicio1)  && timeOfDayToMinutes(clasesEnDia.last.horaFinal) <= timeOfDayToMinutes(horaInicio2))) {
          diaDisponible = "2 $dia";
          horaInicioDisponible = horaInicio2;
          horaFinDisponible = horaFin2;
          break;  // Puedes detener la iteración si se encuentra un día libre
        } else if (timeOfDayToMinutes(clasesEnDia.first.horaInicial) >= timeOfDayToMinutes(horaFin3)  && timeOfDayToMinutes(clasesEnDia.first.horaFinal) <= timeOfDayToMinutes(horaFin4)) {
          diaDisponible = "3 $dia";
          horaInicioDisponible = horaInicio3;
          horaFinDisponible = horaFin3;
          break;  // Puedes detener la iteración si se encuentra un día libre
        } else if (timeOfDayToMinutes(clasesEnDia.first.horaInicial) >= timeOfDayToMinutes(horaInicio3)  && timeOfDayToMinutes(clasesEnDia.first.horaFinal) <= timeOfDayToMinutes(horaInicio4)) {
          diaDisponible = "4 $dia";
          horaInicioDisponible = horaInicio4;
          horaFinDisponible = horaFin4;
          break;  // Puedes detener la iteración si se encuentra un día libre
        }
      }
    }

    return {
      'diaDisponible': diaDisponible,
      'horaInicioDisponible': horaInicioDisponible,
      'horaFinDisponible': horaFinDisponible,
    };
  }








  Future<List<Materias>> _fetchMaterias() async {
    final results = await _connection!.query('SELECT id, Nombre, creditos FROM materias');

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
           fc.dias AS nombre_dias
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
          fechaClase: row['nombre_dias'] ?? -1,
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

  Clase({required this.horaInicial, required this.horaFinal, required this.jornada, required this.fechaClase});
}

