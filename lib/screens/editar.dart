import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysql1/mysql1.dart';
import '../base_conection.dart';
import 'package:intl/intl.dart';

// Define la función para formatear TimeOfDay
String formatTimeOfDay(TimeOfDay timeOfDay) {
  final now = DateTime.now();
  final dateTime = DateTime(
    now.year,
    now.month,
    now.day,
    timeOfDay.hour,
    timeOfDay.minute,
  );
  final formattedTime = DateFormat('HH:mm:ss').format(dateTime);
  return formattedTime;
}

class EditarPage extends StatefulWidget {
  final int idClase;
  EditarPage({required this.idClase});
  @override
  _EditarPageState createState() => _EditarPageState();
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

class ListaDeAulasWidget extends StatelessWidget {
  final List<Aula> aulas;

  ListaDeAulasWidget({required this.aulas});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Aulas'),
        backgroundColor: Color.fromARGB(255, 40, 140, 1), // Color de fondo verde
      ),
      body: ListView.builder(
        itemCount: (aulas.length / 2).ceil(), // Redondea hacia arriba
        itemBuilder: (BuildContext context, int index) {
          final firstAulaIndex = index * 2;
          final secondAulaIndex = (index * 2) + 1;

          return Row(
            children: <Widget>[
              Expanded(
                child: Card(
                  child: buildAulaCard(context, aulas[firstAulaIndex]),
                ),
              ),
              SizedBox(width: 8.0), // Espacio entre las aulas
              if (secondAulaIndex < aulas.length)
                Expanded(
                  child: Card(
                    child: buildAulaCard(context, aulas[secondAulaIndex]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget buildAulaCard(BuildContext context, Aula aula) {
    final elementosWidget = aula.elementos.entries
        .map((entry) => Text("${entry.key}: ${entry.value}"))
        .toList();

    return ListTile(
      title: Text(aula.nombre),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: elementosWidget,
      ),
      onTap: () {
        // Cuando se toca un aula, regresa la ID al screen anterior
        final snackBar = SnackBar(
          content: Text('Aula seleccionada Correctamente ${aula.nombre}'),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        Navigator.of(context).pop(aula.id);
      },
    );
  }
}

class _EditarPageState extends State<EditarPage> {
  TextEditingController nombreController = TextEditingController();
  String jornada = '';
  String nombre_viejo = '';
  TimeOfDay horaInicial = TimeOfDay.now();
  TimeOfDay horaFinal = TimeOfDay.now();
  int selectedDocenteId = -1;
  int selectedSalonId = -1;
  int selectedFechaClaseId = -1;
  int selectedIdAula = 0;
  MySqlConnection? _connection;
  List<DropdownMenuItem<Docente>> docentesDropdown = [];
  List<DropdownMenuItem<FechaClase>> fechaClaseDropdown = [];

  @override
  void initState() {
    super.initState();
    _getjornada().then((value) {
      setState(() {
        jornada = value;
      });
    });
    getConnection().then((connection) {
      setState(() {
        _connection = connection;
      });
      loadDropdownOptions(); // Cargar opciones de desplegables al obtener la conexión
      _getClaseInfo(widget.idClase);
    });
  }

  // Función para cargar las opciones de los desplegables
  void loadDropdownOptions() async {
    final docentes = await _fetchDocentes(); // Consultar la lista de docentes
    final fechasClase =
        await _fetchFechasClase(); // Consultar la lista de fechas de clase
    final aulas = await _fetchAulas();

    setState(() {
      // Construir elementos de desplegable para docentes
      docentesDropdown = docentes
          .map((docente) => DropdownMenuItem<Docente>(
                value: docente,
                child: Text(docente.nombre),
              ))
          .toList();

      // Construir elementos de desplegable para salones

      // Construir elementos de desplegable para fechas de clase
      fechaClaseDropdown = fechasClase
          .map((fechaClase) => DropdownMenuItem<FechaClase>(
                value: fechaClase,
                child: Text(fechaClase.fecha
                    .toString()), // Ajusta esto según la estructura de tus fechas
              ))
          .toList();
      listaDeAulas = aulas;
    });
  }

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
        title: Text('Editar Clase'),
      ),
  body: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: 8.0,
            ),
            child: TextField(
              controller: nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre de la Clase',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    10.0, // Personaliza el radio del borde
                  ),
                ),
              ),
            ),
          ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Hora Inicial: ${horaInicial.format(context)}'),
                  ElevatedButton(
                    onPressed: () => _selectHoraInicial(context),
                    child: Text('Seleccionar Hora'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(40, 140, 1, 1.0),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Hora Final: ${horaFinal.format(context)}'),
                  ElevatedButton(
                    onPressed: () => _selectHoraFinal(context),
                    child: Text('Seleccionar Hora'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(40, 140, 1, 1.0),
                    ),
                  ),
                ],
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
          ElevatedButton(
            onPressed: _mostrarListaDeAulas,
            child: Text('Seleccionar Salón'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromRGBO(40, 140, 1, 1.0),
            ),
          ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 8.0,
              ),
              child: DropdownButton<FechaClase>(
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
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 8.0,
              ),
              child: ElevatedButton(
                onPressed: () async {
                  // Obtener los valores seleccionados de los desplegables
                  final nuevoIdDocentes = selectedDocenteId;
                  final nuevoIdFechaClase = selectedFechaClaseId;

                  // Obtener los otros valores
                  final nuevoNombre = nombreController.text;
                  final nuevaHoraInicial = horaInicial;
                  final nuevaHoraFinal = horaFinal;

                  // Verificar que se haya seleccionado un aula
                  if (selectedIdAula == 0) {
                    // Muestra un mensaje de error o realiza alguna acción de manejo de error
                    return;
                  }

                  await _insertarClase(nuevoNombre, nuevoIdDocentes, nuevoIdFechaClase, nuevaHoraInicial, nuevaHoraFinal, selectedIdAula);

                },
                child: Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(40, 140, 1, 1.0),
                ),
              ),
            ),
          ],
        ),
      )
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
        'SELECT programa FROM clases WHERE idSalones = ? AND idfecha_clase = ? AND (' +
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
        //final nombreClaseExistente = results.first['nombre'];
        final programaClaseExistente = results.first['programa'];

        print(
            'Clase choca con  de $programaClaseExistente'); /*$nombreClaseExistente*/

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(
                'Ya existe una clase programada en ese horario y aula. Choca con la clase:  de $programaClaseExistente',/*$nombreClaseExistente*/
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
        await _connection!.query(
          'UPDATE materias SET nombre= ? WHERE nombre = ?',
          [
            nombreClase,
            nombre_viejo,
          ],
        );

        await _connection!.query(
          'UPDATE clases SET idDocentes = ?, idSalones = ?, idfecha_clase = ?, hora_inicial = ?, hora_final = ? WHERE idClases = ? AND jornada = ?',
          [
            docenteId,
            aulaId,
            fechaClaseId,
            horaInicioStr,
            horaFinStr,
            widget.idClase,
            jornada
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

  Future<void> _getClaseInfo(int idClase) async {
    print("Hola1");
    if (_connection == null) {
      // Manejo de error si la conexión no está disponible
      print("no hay conexion a la bd");
      return;
    }

    try {
      final results = await _connection!.query(
        'SELECT m.nombre AS nombre, TIME_FORMAT(hora_inicial, "%H:%i:%s") AS hora_inicial, TIME_FORMAT(hora_final, "%H:%i:%s") AS hora_final FROM clases c '
            'INNER JOIN materias m ON c.idmaterias = m.id '
            'WHERE idClases = ?',
        [idClase],
      );
      print(idClase);
      print("Hola2");

      if (results.isNotEmpty) {
        final row = results.first;

        final nombre = row['nombre'];
        final horaInicialStr = row['hora_inicial'];
        final horaFinalStr = row['hora_final'];
        print("Hola3 $horaInicialStr");

        setState(() {
          nombreController.text = nombre;
          print(nombreController.text);

          horaInicial = _parseTimeOfDay(horaInicialStr);
          print(horaInicial);

          horaFinal = _parseTimeOfDay(horaFinalStr);
          print(horaFinal);

          nombre_viejo = nombre;
        });
      }
    } catch (e) {
      print('Error al obtener la información de la clase: $e');
    }
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 3) {
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    }
    print("tiempo2");
    return TimeOfDay.now();
  }



  Future<String> _getjornada() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jornada') ?? '';
  }

  Future<List<Docente>> _fetchDocentes() async {
    final results = await _connection!.query('SELECT * FROM docentes');
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

  // Función para seleccionar la hora inicial
  Future<void> _selectHoraInicial(BuildContext context) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: horaInicial,
    );

    if (selectedTime != null) {
      setState(() {
        horaInicial = selectedTime;
      });
    }
  }

  // Función para seleccionar la hora final
  Future<void> _selectHoraFinal(BuildContext context) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: horaFinal,
    );

    if (selectedTime != null) {
      setState(() {
        horaFinal = selectedTime;
      });
    }
  }
}

// Define las clases para representar las opciones de los desplegables (Docente, Salon, FechaClase)
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
