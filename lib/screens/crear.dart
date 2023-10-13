import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../base_conection.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CrearPage extends StatefulWidget {
  @override
  _CrearPageState createState() => _CrearPageState();
}

class Aula {
  final int id;
  final String nombre;
  final Map<String, int> elementos;

  Aula({
    required this.id,
    required this.nombre,
    required this.elementos,
  });
}

List<Aula> listaDeAulas = [];

List<String> opcionesJornada = ['diurna', 'nocturna'];

class ListaDeAulasWidget extends StatelessWidget {
  final List<Aula> aulas;

  ListaDeAulasWidget({required this.aulas});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Aulas'),
        backgroundColor:
            Color.fromARGB(255, 40, 140, 1), // Color de fondo verde
      ),
      body: ListView.builder(
        itemCount: aulas.length,
        itemBuilder: (BuildContext context, int index) {
          final aula = aulas[index];

          final elementosWidget = aula.elementos.entries
              .map((entry) => Text("${entry.key}: ${entry.value}"))
              .toList();

          return Card(
            child: ListTile(
              title: Text(aula.nombre),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: elementosWidget,
              ),
              onTap: () {
                // Cuando se toca un aula, regresa la ID al screen anterior
                final snackBar = SnackBar(
                  content:
                      Text('Aula seleccionada Correctamente ${aula.nombre}'),
                );

                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                Navigator.of(context).pop(aula.id);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CrearPageState extends State<CrearPage> {
  MySqlConnection? _connection;
  String selectedDocente = "";
  String selectedFechaClase = "";
  String selectedSalon = "";
  String semestre = '';
  String jornada = 'diurna';
  TextEditingController nombreClaseController = TextEditingController();

  String directorType = '';
  int selectedDocenteId = -1;
  int selectedSalonId = -1;
  int selectedFechaClaseId = -1;
  int selectedIdAula = 0;
  List<DropdownMenuItem<Docente>> docentesDropdown = [];
  List<DropdownMenuItem<FechaClase>> fechaClaseDropdown = [];

  TimeOfDay selectedHoraInicio = TimeOfDay.now();
  TimeOfDay selectedHoraFin = TimeOfDay.now();

  TextEditingController horaInicioController = TextEditingController();
  TextEditingController horaFinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getConnection().then((connection) {
      setState(() {
        _connection = connection;
      });
      loadDropdownOptions(); // Cargar opciones de desplegables al obtener la conexión
    });
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
  }

  void loadDropdownOptions() async {
    final docentes = await _fetchDocentes(); // Consultar la lista de docentes
    //final salones = await _fetchSalones(); // Consultar la lista de salones
    final fechasClase =
        await _fetchFechasClase(); // Consultar la lista de fechas de clase
    // Consulta a la base de datos para obtener la lista de aulas
    final aulas = await _fetchAulas();

    setState(() {
      // Construir elementos de desplegable para docentes
      docentesDropdown = docentes
          .map((docente) => DropdownMenuItem<Docente>(
                value: docente,
                child: Text(docente.nombre),
              ))
          .toList();

      // Construir elementos de desplegable para fechas de clase
      fechaClaseDropdown = fechasClase
          .map((fechaClase) => DropdownMenuItem<FechaClase>(
                value: fechaClase,
                child: Text(fechaClase.fecha
                    .toString()), // Ajusta esto según la estructura de tus fechas
              ))
          .toList();
      // Asigna la lista de aulas obtenida de la base de datos
      listaDeAulas = aulas;
    });
  }

  // Define una función para consultar las aulas desde la base de datos
  Future<List<Aula>> _fetchAulas() async {
    final results = await _connection!.query(
        'SELECT CONCAT(bloque, " ", aula) AS nombre_completo, idSalones, pupitres, mesas, sillas, enchufes, ventiladores, aires, tv, videobeen FROM salones');

    return results.map((row) {
      final elementos = <String, int>{};
      elementos['pupitres'] = row['pupitres'];
      elementos['mesas'] = row['mesas'];
      elementos['sillas'] = row['sillas'];
      elementos['enchufes'] = row['enchufes'];
      elementos['ventiladores'] = row['ventiladores'];
      elementos['aires'] = row['aires'];
      elementos['tv'] = row['tv'];
      elementos['videobeen'] = row['videobeen'];

      // Filtra elementos diferentes de 0
      final filteredElementos = elementos.entries
          .where((entry) => entry.value != 0)
          .map((entry) => MapEntry(entry.key, entry.value))
          .toList();

      return Aula(
        id: row['idSalones'],
        nombre: row['nombre_completo'],
        elementos: Map.fromEntries(filteredElementos),
      );
    }).toList();
  }

  void _mostrarListaDeAulas() async {
    final selectedAulaId = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (context) => ListaDeAulasWidget(aulas: listaDeAulas),
      ),
    );

    if (selectedAulaId != null) {
      // Hacer algo con la ID seleccionada, como almacenarla o mostrarla en pantalla
      print("ID del aula seleccionada: $selectedAulaId");
      selectedIdAula = selectedAulaId;
      print("ID del aula: $selectedIdAula");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 40, 140, 1),
        title: Text('Crear Clase', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: nombreClaseController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la Clase',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2.0),
                    borderRadius: BorderRadius.circular(
                        10.0), // Personaliza el radio del borde
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2.0),
                    borderRadius: BorderRadius.circular(
                        10.0), // Personaliza el radio del borde
                  ),
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              DropdownButton<Docente>(
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
              ElevatedButton(
                onPressed: _mostrarListaDeAulas,
                child: Text('Seleccionar Salón'),
                style: ElevatedButton.styleFrom(
                  primary: Color.fromRGBO(40, 140, 1, 1.0),
                ),
              ),
              DropdownButton<FechaClase>(
                value: selectedFechaClaseId == -1
                    ? null
                    : fechaClaseDropdown
                        .firstWhere(
                            (item) => item.value!.id == selectedFechaClaseId)
                        .value,
                items: fechaClaseDropdown,
                onChanged: (fechaClase) {
                  setState(() {
                    selectedFechaClaseId = fechaClase!.id;
                  });
                },
                hint: Text('Seleccione una Fecha de Clase'),
              ),
              ListTile(
                title: Text('Hora de Inicio'),
                subtitle: Text(
                  DateFormat.jm().format(
                    DateTime(
                      0,
                      1,
                      1,
                      selectedHoraInicio.hour,
                      selectedHoraInicio.minute,
                    ),
                  ),
                ),
                onTap: () async {
                  final selectedTime = await showTimePicker(
                    context: context,
                    initialTime: selectedHoraInicio,
                  );
                  if (selectedTime != null) {
                    setState(() {
                      selectedHoraInicio = selectedTime;
                      horaInicioController.text = DateFormat.Hms().format(
                        DateTime(
                          0,
                          1,
                          1,
                          selectedHoraInicio.hour,
                          selectedHoraInicio.minute,
                        ),
                      );
                    });
                  }
                },
              ),
              ListTile(
                title: Text('Hora de Fin'),
                subtitle: Text(
                  DateFormat.jm().format(
                    DateTime(
                      0,
                      1,
                      1,
                      selectedHoraFin.hour,
                      selectedHoraFin.minute,
                    ),
                  ),
                ),
                onTap: () async {
                  final selectedTime = await showTimePicker(
                    context: context,
                    initialTime: selectedHoraFin,
                  );
                  if (selectedTime != null) {
                    setState(() {
                      selectedHoraFin = selectedTime;
                      horaFinController.text = DateFormat.Hms().format(
                        DateTime(
                          0,
                          1,
                          1,
                          selectedHoraFin.hour,
                          selectedHoraFin.minute,
                        ),
                      );
                    });
                  }
                },
              ),
              DropdownButton<String>(
                value: jornada,
                items: opcionesJornada.map((String opcion) {
                  return DropdownMenuItem<String>(
                    value: opcion,
                    child: Text(opcion),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    jornada = newValue ?? '';
                  });
                },
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    // Obtener los valores de los campos y desplegables
                    final nombreClase = nombreClaseController.text;
                    final docenteId = selectedDocenteId;
                    final fechaClaseId = selectedFechaClaseId;
                    final horaInicio = selectedHoraInicio;
                    final horaFin = selectedHoraFin;

                    // Verificar que se haya seleccionado un aula
                    if (selectedIdAula == 0) {
                      // Muestra un mensaje de error o realiza alguna acción de manejo de error
                      return;
                    }

                    // Realizar la inserción en la base de datos
                    await _insertarClase(nombreClase, docenteId, fechaClaseId,
                        horaInicio, horaFin, selectedIdAula);
                  },
                  child: Text('Guardar Clase'),
                  style: ElevatedButton.styleFrom(
                    primary: Color.fromRGBO(40, 140, 1, 1.0),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Función para insertar la clase en la base de datos
  Future<void> _insertarClase(
      String nombreClase,
      int docenteId,
      int fechaClaseId,
      TimeOfDay horaInicio,
      TimeOfDay horaFin,
      int aulaId) async {
    final connection = _connection;

    if (connection == null) {
      // Manejo de error si la conexión no está disponible
      return;
    }

    try {
      final horaInicioStr = '${horaInicio.hour}:${horaInicio.minute}';
      final horaFinStr = '${horaFin.hour}:${horaFin.minute}';

      final results = await connection.query(
        'SELECT nombre, programa FROM clases WHERE idSalones = ? AND idfecha_clase = ? AND (' +
            '((hora_inicial <= ? AND hora_final >= ?) OR (hora_inicial >= ? AND hora_final <= ?))' +
            ')',
        [
          aulaId,
          fechaClaseId,
          horaInicioStr,
          horaInicioStr,
          horaInicioStr,
          horaFinStr,
        ],
      );

      if (results.isNotEmpty) {
        final nombreClaseExistente = results.first['nombre'];
        final programaClaseExistente = results.first['programa'];

        print(
            'Clase choca con $nombreClaseExistente de $programaClaseExistente');

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(
                'Ya existe una clase programada en ese horario y aula. Choca con la clase: $nombreClaseExistente de $programaClaseExistente',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Aceptar'),
                ),
              ],
            );
          },
        );
      } else {
        print(
            'INSERT INTO clases ($nombreClase, $docenteId, $aulaId, $semestre, $fechaClaseId, $horaInicioStr, $horaFinStr, $directorType, $jornada) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
        await connection.query(
          'INSERT INTO clases (nombre, idDocentes, idSalones, semestre, idfecha_clase, hora_inicial, hora_final, programa, jornada) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            nombreClase,
            docenteId,
            aulaId,
            semestre,
            fechaClaseId,
            horaInicioStr,
            horaFinStr,
            directorType,
            jornada,
          ],
        );

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Clase Guardada'),
              content: Text(
                  'La clase se ha guardado exitosamente en la base de datos.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text('Aceptar'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error al insertar clase: $e');
    }
  }

  Future<String> obtenerSemestreType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String semestreType = prefs.getString('semestreType') ?? '';
    return semestreType;
  }

  Future<List<Docente>> _fetchDocentes() async {
    final results = await _connection!
        .query('SELECT * FROM docentes WHERE programa = ?', [directorType]);
    return results
        .map((row) => Docente(row['idDocentes'], row['Nombre']))
        .toList();
  }

  Future<List<FechaClase>> _fetchFechasClase() async {
    final results = await _connection!.query('SELECT * FROM fecha_clase');
    return results
        .map((row) => FechaClase(row['idfecha_clase'], row['dias']))
        .toList();
  }

  Future<String> _getDirectorType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('directorType') ?? '';
  }

  @override
  void dispose() {
    horaInicioController.dispose();
    horaFinController.dispose();
    super.dispose();
  }
}

class Docente {
  final int id;
  final String nombre;

  Docente(this.id, this.nombre);
}

class FechaClase {
  final int id;
  final String fecha;

  FechaClase(this.id, this.fecha);
}
