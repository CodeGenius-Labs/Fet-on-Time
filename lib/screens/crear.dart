import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear las horas de inicio y fin
import '../base_conection.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CrearPage extends StatefulWidget {
  @override
  _CrearPageState createState() => _CrearPageState();
}

class _CrearPageState extends State<CrearPage> {
  MySqlConnection? _connection;
  String selectedDocente = "";
  String selectedFechaClase = "";
  String selectedSalon = "";
  String selectedSemestre = "1"; // Valor inicial

  int selectedDocenteId = -1;
  int selectedSalonId = -1;
  int selectedFechaClaseId = -1;
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
  }
  void loadDropdownOptions() async {
    final docentes = await _fetchDocentes(); // Consultar la lista de docentes
    //final salones = await _fetchSalones(); // Consultar la lista de salones
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
        title: Text('Crear Clase'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Nombre de la Clase'),
              ),
              DropdownButton<Docente>(
                value: selectedDocenteId == -1
                    ? null
                    : docentesDropdown
                    .firstWhere((item) => item.value!.id == selectedDocenteId)
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
                onPressed: () {
                  // ... Código para seleccionar salón ...
                },
                child: Text('Seleccionar Salón'),
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
              ElevatedButton(
                onPressed: () {
                  // Realizar la acción de guardar la clase en la base de datos
                },
                child: Text('Guardar Clase'),
              ),
            ],
          ),
        ),
      ),
    );
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

  // Las funciones fetchFechasClase y getConnection siguen siendo similares
  // ...
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
