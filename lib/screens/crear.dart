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
  String semestre = '';
  String directorType = '';
  int estudiantes = 0;
  String selectedJornada = 'diurna';
  List<String> condiciones = [];
  int selectedMateriasId = -1;
  int materiaCreditos = -1;
  List<DropdownMenuItem<Materias>> materiasDropdown = [];
  int selectedDocenteId = -1;
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
                    materiaCreditos = materia.creditos;
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
    /*final salonId = salon['idSalon'];
    final salonNombre = salon['nombre_salon'];*/

    final libre = await seleccionarDiaYHorasDisponibles(selectedJornada, estudiantes, materiaCreditos);
    final diaDisp = libre['diaDisponible'];
    final hora_inicio = libre['horaInicioDisponible'];
    final hora_final = libre['horaFinDisponible'];
    final salonNombre = libre['nombre_completo'];
    final idSalon = libre['idSalon'];
    print('''
        salon: $idSalon $salonNombre
        dia: $diaDisp
        hora inicial: $hora_inicio
        hora final: $hora_final
    ''');
    final horaInicioStr = '${hora_inicio.hour}:${hora_inicio.minute}';
    final horaFinStr = '${hora_final.hour}:${hora_final.minute}';




    //-----------------------------------FINAL LOGICA----------------------------------------
    // Ejemplo de cómo insertar datos en la base de datos utilizando el paquete mysql1:
    try {
      print('INSERT INTO clases(idmaterias, idDocentes, idSalones, semestre, idfecha_clase, hora_inicial, hora_final, programa, jornada) VALUES ($selectedMateriasId, $selectedDocenteId, $idSalon, $semestre, $diaDisp, $horaInicioStr, $horaFinStr, $directorType, $selectedJornada)');
      final result = await _connection!.query(
        'INSERT INTO clases(idmaterias, idDocentes, idSalones, semestre, idfecha_clase, hora_inicial, hora_final, programa, jornada) VALUES (?,?,?,?,?,?,?,?,?)',
        [selectedMateriasId, selectedDocenteId, idSalon, semestre, diaDisp, horaInicioStr, horaFinStr, directorType, selectedJornada],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Clase guardada exitosamente.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrió un error al guardar la clase. Por favor, inténtalo de nuevo.'),
        ),
      );
      // Manejar cualquier error que pueda ocurrir durante la eliminación
      print('Error al crear la clase: $e');
      // Puedes mostrar un mensaje de error al usuario si es necesario
    }
  }

  Future<Map<String, dynamic>> seleccionarDiaYHorasDisponibles(String jornada, int capacidadRequerida, int materiaCreditos) async {
    // Realiza una consulta en la base de datos para obtener los salones aptos
    final horaInicio1 = TimeOfDay(hour: 7, minute: 50);
    final horaFin1 = TimeOfDay(hour: 8, minute: 40);
    final horaInicio2 = TimeOfDay(hour: 8, minute: 40);
    final horaFin2 = TimeOfDay(hour: 9, minute: 30);
    final horaInicio3 = TimeOfDay(hour: 10, minute: 00);
    final horaFin3 = TimeOfDay(hour: 10, minute: 50);
    final horaInicio4 = TimeOfDay(hour: 10, minute: 50);
    final horaFin4 = TimeOfDay(hour: 11, minute: 40);

    final horaInicio5 = TimeOfDay(hour: 18, minute: 30);
    final horaFin5 = TimeOfDay(hour: 19, minute: 20);
    final horaInicio6 = TimeOfDay(hour: 19, minute: 20);
    final horaFin6 = TimeOfDay(hour: 20, minute: 10);
    final horaInicio7 = TimeOfDay(hour: 20, minute: 30);
    final horaFin7 = TimeOfDay(hour: 21, minute: 20);
    final horaInicio8 = TimeOfDay(hour: 21, minute: 20);
    final horaFin8 = TimeOfDay(hour: 22, minute: 10);

    String diaDisponible = '';
    String nombrecompleto = '';
    int idSalon = -1;
    int selectedSalonIndex = 0;
    TimeOfDay horaInicioDisponible = horaInicio1;
    TimeOfDay horaFinDisponible = horaFin1;
    int creditos = materiaCreditos;


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

        // Retorna la ID y el nombre del salón seleccionado
        /*return {
        'idSalon': salonSeleccionado['idSalones'],
        'nombre_salon': salonSeleccionado['nombre_completo'],
      };*/

        int timeOfDayToMinutes(TimeOfDay time) {
          return time.hour * 60 + time.minute;
        }

        final clasesEnBaseDeDatos = await getHorariosOcupados();
        final clasesEnSalon = clasesEnBaseDeDatos.where((clase) => clase.jornada == jornada).toList();
        final clasesEnJornada = clasesEnSalon.where((clase) => clase.idSalones == idSalon).toList();


        final diasSemana = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];


        while(creditos > 0){
          for (final dia in diasSemana) {
            final clasesEnDia = clasesEnJornada.where((clase) => clase.fechaClase.toLowerCase() == dia).toList();
            print('creditos: $creditos');
            if (clasesEnDia.isEmpty) {
              print("empty");
              if (jornada == "diurna"){
                if(creditos == 2){
                  diaDisponible = dia;
                  horaInicioDisponible = horaInicio1;
                  horaFinDisponible = horaFin2;
                  creditos -= 2;
                  break;  // Puedes detener la iteración si se encuentra un día libree
                } else if(creditos == 1) {
                  diaDisponible = dia;
                  horaInicioDisponible = horaInicio1;
                  horaFinDisponible = horaFin1;
                  creditos--;
                  break;  // Puedes detener la iteración si se encuentra un día libree
                } else {
                  break;
                }
              } else {
                if(creditos == 2){
                  diaDisponible = dia;
                  horaInicioDisponible = horaInicio5;
                  horaFinDisponible = horaFin6;
                  creditos -= 2;
                  break;  // Puedes detener la iteración si se encuentra un día libree
                } else if(creditos == 1) {
                  diaDisponible = dia;
                  horaInicioDisponible = horaInicio5;
                  horaFinDisponible = horaFin5;
                  creditos--;
                  break;  // Puedes detener la iteración si se encuentra un día libree
                } else {
                  break;
                }
              }

            } else {
              clasesEnDia.sort((a, b) => timeOfDayToMinutes(a.horaInicial).compareTo(timeOfDayToMinutes(b.horaInicial)));
              print('''
                CLASE FINAL
                jornada: ${clasesEnDia.last.jornada}
                dia: ${clasesEnDia.last.fechaClase}
                inicial: ${clasesEnDia.last.horaInicial}
                final: ${clasesEnDia.last.horaFinal}
                -------------------------------------------
                CLASE INICIAL
                jornada: ${clasesEnDia.first.jornada}
                dia: ${clasesEnDia.first.fechaClase}
                inicial: ${clasesEnDia.first.horaInicial}
                final: ${clasesEnDia.first.horaFinal}
              ''');

              if (clasesEnDia.last.jornada == "diurna"){
                if (timeOfDayToMinutes(clasesEnDia.last.horaInicial) > timeOfDayToMinutes(horaInicio1)){
                  if (timeOfDayToMinutes(clasesEnDia.last.horaInicial) > timeOfDayToMinutes(horaInicio2)){
                    if (timeOfDayToMinutes(clasesEnDia.last.horaInicial) > timeOfDayToMinutes(horaInicio3)){

                    } else{
                      print("3");
                      if (creditos == 2){
                        print("3.1");
                      } else{
                        if (timeOfDayToMinutes(clasesEnDia.first.horaFinal) < timeOfDayToMinutes(horaInicio3) && timeOfDayToMinutes(clasesEnDia.last.horaInicial) > timeOfDayToMinutes(horaInicio3)){
                          print("3.1.1");
                        }else if (timeOfDayToMinutes(clasesEnDia.first.horaFinal) < timeOfDayToMinutes(horaInicio3)){
                          if(timeOfDayToMinutes(clasesEnDia.last.horaInicial) >= timeOfDayToMinutes(horaInicio3) && timeOfDayToMinutes(clasesEnDia.last.horaFinal) <= timeOfDayToMinutes(horaFin3)){
                            print("3.1.2.1");
                            diaDisponible = dia;
                            horaInicioDisponible = horaInicio4;
                            horaFinDisponible = horaFin4;
                            creditos--;
                            break;
                          } else {
                            print("3.1.2.2");
                          }
                          /*diaDisponible = dia;
                          horaInicioDisponible = horaInicio4;
                          horaFinDisponible = horaFin4;
                          creditos--;
                          break;*/
                        } else {
                          print("3.1.3");
                          diaDisponible = dia;
                          horaInicioDisponible = horaInicio4;
                          horaFinDisponible = horaFin4;
                          creditos--;
                        }
                      }
                    }
                  } else {
                    print("2");
                    if(creditos == 2){
                      print("2.1");
                      diaDisponible = dia;
                      horaInicioDisponible = horaInicio3;
                      horaFinDisponible = horaFin4;
                      creditos -= 2;
                      break;
                    } else if(creditos == 1){
                      print("2.2");
                      diaDisponible = dia;
                      horaInicioDisponible = horaInicio3;
                      horaFinDisponible = horaFin3;
                      creditos--;
                      break;
                    } else {
                      break;
                    }

                  }
                } else {
                  print("1");
                  if(timeOfDayToMinutes(clasesEnDia.last.horaFinal) > timeOfDayToMinutes(horaFin1)) {
                    if (creditos == 2){
                      print("1.1.1");
                      diaDisponible = dia;
                      horaInicioDisponible = horaInicio3;
                      horaFinDisponible = horaFin4;
                      creditos -= 2;
                      break;
                    } else{
                      print("1.1.2");
                      diaDisponible = dia;
                      horaInicioDisponible = horaInicio3;
                      horaFinDisponible = horaFin3;
                      creditos--;
                      break;
                    }
                  } else {
                    if (creditos == 2){
                      print("1.2.1");
                      diaDisponible = dia;
                      horaInicioDisponible = horaInicio3;
                      horaFinDisponible = horaFin4;
                      creditos -= 2;
                      break;
                    } else{
                      print("1.2.2");
                      diaDisponible = dia;
                      horaInicioDisponible = horaInicio2;
                      horaFinDisponible = horaFin2;
                      creditos--;
                      break;
                    }
                  }
                }
              } else{
                if (timeOfDayToMinutes(clasesEnDia.last.horaInicial) > timeOfDayToMinutes(horaInicio5)){
                  if (timeOfDayToMinutes(clasesEnDia.last.horaInicial) > timeOfDayToMinutes(horaInicio6)){
                    if (timeOfDayToMinutes(clasesEnDia.last.horaInicial) > timeOfDayToMinutes(horaInicio7)){

                    } else{
                      print("4");
                      if (creditos == 2){
                        print("4.1");
                      } else{
                        diaDisponible = dia;
                        horaInicioDisponible = horaInicio8;
                        horaFinDisponible = horaFin8;
                        creditos--;
                        break;
                      }
                    }
                  } else {
                    print("5");
                    if(creditos == 2){
                      print("5.1");
                      diaDisponible = dia;
                      horaInicioDisponible = horaInicio7;
                      horaFinDisponible = horaFin8;
                      creditos -= 2;
                      break;
                    } else if(creditos == 1){
                      print("5.2");
                      diaDisponible = dia;
                      horaInicioDisponible = horaInicio7;
                      horaFinDisponible = horaFin7;
                      creditos--;
                      break;
                    } else {
                      break;
                    }

                  }
                } else {
                  print("6");
                  if(timeOfDayToMinutes(clasesEnDia.last.horaFinal) > timeOfDayToMinutes(horaFin5)) {
                    if (creditos == 2){
                      print("6.1.1");
                      diaDisponible = dia;
                      horaInicioDisponible = horaInicio7;
                      horaFinDisponible = horaFin8;
                      creditos -= 2;
                      break;
                    } else{
                      print("6.1.2");
                      diaDisponible = dia;
                      horaInicioDisponible = horaInicio7;
                      horaFinDisponible = horaFin7;
                      creditos--;
                      break;
                    }
                  } else {
                    if (creditos == 2){
                      print("6.2.1");
                      diaDisponible = dia;
                      horaInicioDisponible = horaInicio7;
                      horaFinDisponible = horaFin8;
                      creditos -= 2;
                      break;
                    } else{
                      print("6.2.2");
                      diaDisponible = dia;
                      horaInicioDisponible = horaInicio6;
                      horaFinDisponible = horaFin6;
                      creditos--;
                      break;
                    }
                  }
                }
              }



            }
            print(dia);
          }
        }
        if (diaDisponible.isEmpty) {
          selectedSalonIndex++;
          // Si ya no hay más salones, termina el bucle
          if (selectedSalonIndex >= resultList.length) {
            break;
          }
        } else {
          // Si se encontró un día libre, sal del bucle while
          break;
        }
      }
    } else {
      // No se encontraron salones aptos, puedes devolver un valor por defecto o lanzar una excepción
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se encontraron salones con capacidad suficiente.'),
        ),
      );
      throw Exception('No se encontraron salones con capacidad suficiente.');
    }
    int idfecha_clase; // Variable para almacenar el valor de idfecha_clase

    if (diaDisponible == "lunes") {
      idfecha_clase = 1;
    } else if (diaDisponible == "martes") {
      idfecha_clase = 2;
    } else if (diaDisponible == "miercoles") {
      idfecha_clase = 3;
    } else if (diaDisponible == "jueves") {
      idfecha_clase = 4;
    } else if (diaDisponible == "viernes") {
      idfecha_clase = 5;
    } else if (diaDisponible == "sabado") {
      idfecha_clase = 6;
    } else if (diaDisponible == "domingo") {
      idfecha_clase = 7;
    } else {
      // Si diaDisponible no coincide con ningún día, puedes asignar un valor predeterminado o mostrar un mensaje de error
      idfecha_clase = -1; // Valor predeterminado o cualquier otro valor adecuado
      print("Día no válido"); // Mensaje de error
    }

    return {

      'diaDisponible': idfecha_clase,
      'horaInicioDisponible': horaInicioDisponible,
      'horaFinDisponible': horaFinDisponible,
      'nombre_completo': nombrecompleto,
      'idSalon': idSalon,
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

