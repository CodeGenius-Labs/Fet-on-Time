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
  @override
  _EditarPageState createState() => _EditarPageState();
}

class _EditarPageState extends State<EditarPage> {
  TextEditingController nombreController = TextEditingController();
  String jornada = ' ';
  String nombre_viejo = ' ';
  TimeOfDay horaInicial = TimeOfDay.now();
  TimeOfDay horaFinal = TimeOfDay.now();
  int selectedDocenteId = -1;
  int selectedSalonId = -1;
  int selectedFechaClaseId = -1;
  MySqlConnection? _connection;
  List<DropdownMenuItem<Docente>> docentesDropdown = [];
  List<DropdownMenuItem<Salon>> salonesDropdown = [];
  List<DropdownMenuItem<FechaClase>> fechaClaseDropdown = [];

  @override
  void initState() {
    super.initState();
    _getnombre_clase().then((value) {
      setState(() {
        nombre_viejo = value;
      });
      nombreController.text = nombre_viejo;
    });
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
    });
  }

  // Función para cargar las opciones de los desplegables
  void loadDropdownOptions() async {
    final docentes = await _fetchDocentes(); // Consultar la lista de docentes
    final salones = await _fetchSalones(); // Consultar la lista de salones
    final fechasClase =
        await _fetchFechasClase(); // Consultar la lista de fechas de clase

    setState(() {
      // Construir elementos de desplegable para docentes
      docentesDropdown = docentes
          .map((docente) => DropdownMenuItem<Docente>(
                value: docente,
                child: Text(docente.nombre),
              ))
          .toList();

      // Construir elementos de desplegable para salones
      salonesDropdown = salones
          .map((salon) => DropdownMenuItem<Salon>(
                value: salon,
                child: Text('${salon.bloque} - ${salon.aula}'),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 40, 140, 1),
        title: Text('Editar Clase'),
      ),
      body: Padding(
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
                        10.0), // Personaliza el radio del borde
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
                      primary: Color.fromRGBO(40, 140, 1, 1.0),
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
                      primary: Color.fromRGBO(40, 140, 1, 1.0),
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
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 8.0,
              ),
              child: DropdownButton<Salon>(
                value: selectedSalonId == -1
                    ? null
                    : salonesDropdown
                        .firstWhere((item) => item.value!.id == selectedSalonId)
                        .value,
                items: salonesDropdown,
                onChanged: (salon) {
                  setState(() {
                    selectedSalonId = salon!.id;
                  });
                },
                hint: Text('Seleccione un Salón'),
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
                  final nuevoIdSalones = selectedSalonId;
                  final nuevoIdFechaClase = selectedFechaClaseId;

                  // Obtener los otros valores
                  final nuevoNombre = nombreController.text;
                  final nuevaHoraInicial = formatTimeOfDay(horaInicial);
                  final nuevaHoraFinal = formatTimeOfDay(horaFinal);

                  try {
                    // Actualizar la clase en la base de datos usando las IDs seleccionadas
                    print(
                        'UPDATE clases SET idDocentes = $nuevoIdDocentes, idSalones = $nuevoIdSalones, idfecha_clase = $nuevoIdFechaClase, nombre = $nuevoNombre, hora_inicial = $nuevaHoraInicial, hora_final = $nuevaHoraFinal WHERE nombre = $nombre_viejo AND jornada = $jornada');
                    await _connection!.query(
                      'UPDATE clases SET idDocentes = ?, idSalones = ?, idfecha_clase = ?, nombre = ?, hora_inicial = ?, hora_final = ? WHERE nombre = ? AND jornada = ?',
                      [
                        nuevoIdDocentes,
                        nuevoIdSalones,
                        nuevoIdFechaClase,
                        nuevoNombre,
                        nuevaHoraInicial,
                        nuevaHoraFinal,
                        nombre_viejo,
                        jornada
                      ],
                    );

                    // Muestra un SnackBar para indicar que la clase se actualizó correctamente
                    final snackBar = SnackBar(
                      content: Text('La clase se actualizó correctamente.'),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(snackBar);

                    // Cierra la pantalla de edición después de actualizar los valores
                    Navigator.of(context).pop();
                  } catch (e) {
                    // Manejar cualquier error que pueda ocurrir durante la actualización
                    print('Error al actualizar la clase: $e');
                    // Puedes mostrar un mensaje de error al usuario si es necesario
                  }
                },
                child: Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  primary: Color.fromRGBO(40, 140, 1, 1.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getnombre_clase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('nombre_clase') ?? '';
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

  Future<List<Salon>> _fetchSalones() async {
    final results = await _connection!.query('SELECT * FROM salones');
    return results
        .map((row) => Salon(row['idSalones'], row['bloque'], row['aula']))
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

class Salon {
  final int id;
  final String bloque;
  final String aula;

  Salon(this.id, this.bloque, this.aula);
}

class FechaClase {
  final int id;
  final String fecha;

  FechaClase(this.id, this.fecha);
}
