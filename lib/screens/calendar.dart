import 'package:fetontime/screens/crear.dart';
import 'package:fetontime/screens/editar.dart';
import 'eliminar.dart';
import '../base_conection.dart'; // Asegúrate de que la ruta sea la correcta
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mysql1/mysql1.dart'; // Importa la librería mysql1
import 'package:intl/intl.dart';

class Calendar extends StatefulWidget {
  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  String semestre = '';
  int idClase = 0;
  String directorType = ''; // Declaración de la variable directorType
  DateTime today = DateTime.now();
  DateTime? _selectedDay;
  late ValueNotifier<List<Event>> _selectedEvents;
  MySqlConnection? _connection; // Variable para la conexión

  @override
  void initState() {
    super.initState();
    obtenerSemestreType().then((value) {
      setState(() {
        semestre = value;
      });
    });
    // Llama a _getDirectorType para obtener el valor de directorType desde SharedPreferences
    _getDirectorType().then((value) {
      setState(() {
        directorType = value;
      });
    });
    _selectedEvents = ValueNotifier(_getEventsForDay(today));

    // Obtén la conexión a la base de datos desde el archivo de conexión
    getConnection().then((connection) {
      setState(() {
        _connection = connection;
      });
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    _connection?.close(); // Cierra la conexión al finalizar
    super.dispose();
  }

  Future<String> obtenerSemestreType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String semestreType = prefs.getString('semestreType') ?? '';
    return semestreType;
  }

  Future<void> _updateEvents() async {
    if (_selectedDay != null &&
        directorType.isNotEmpty &&
        _connection != null) {
      final dayOfWeek =
          DateFormat('EEEE', 'es_ES').format(_selectedDay!).toLowerCase();
      final filteredEvents =
          await fetchFilteredEventsFromDatabase(dayOfWeek, directorType);

      setState(() {
        events[_selectedDay!] = filteredEvents;
      });
    }
  }

  Future<List<Event>> fetchFilteredEventsFromDatabase(
      String dayOfWeek, String directorType) async {
    try {
      final results = await _connection!.query(
        'SELECT c.idClases AS id_clase, m.nombre AS nombre_clase, c.jornada AS jornada, d.Nombre AS nombre_docente, '
        'CONCAT(s.bloque, "-", s.aula) AS ubicacion_salon,'
        'CONCAT(c.hora_inicial, "-", c.hora_final) AS hora_clase FROM clases c '
        'INNER JOIN docentes d ON c.idDocentes = d.idDocentes '
        'INNER JOIN materias m ON c.idmaterias = m.id '
        'INNER JOIN salones s ON c.idSalones = s.idSalones '
        'INNER JOIN fecha_clase fc ON c.idfecha_clase = fc.idfecha_clase '
        'WHERE fc.dias = ? AND c.programa = ? AND c.semestre = ?',
        [dayOfWeek, directorType, semestre],
      );

      final events = <Event>[];
      for (var row in results) {
        events.add(Event(
          row['nombre_clase'],
          row['jornada'],
          row['nombre_docente'],
          row['ubicacion_salon'],
          row['hora_clase'],
        ));
        // Aquí asigna el ID de la clase a la variable idClase
        print(row['id_clase']);
        idClase = row['id_clase'];
      }

      return events;
    } catch (e) {
      print('Error en la búsqueda en la base de datos: $e');
      return [];
    }
  }

  Map<DateTime, List<Event>> events = {};

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
      _selectedDay = day;
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });
    _updateEvents(); // Actualiza los eventos al seleccionar un día
  }

  List<Event> _getEventsForDay(DateTime day) {
    return events[day] ?? [];
  }

  Widget content() {
    return Column(
      children: [
        Container(
          child: TableCalendar(
            calendarFormat: CalendarFormat.week,
            locale: "es_ES",
            rowHeight: 80,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                    color: Color.fromRGBO(40, 140, 1, 1.0),
                    shape: BoxShape.circle),
                todayDecoration: BoxDecoration(
                    color: Color.fromARGB(120, 40, 140, 1),
                    shape: BoxShape.circle)),
            availableGestures: AvailableGestures.all,
            selectedDayPredicate: (day) => isSameDay(day, today),
            focusedDay: today,
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay,
          ),
        ),
        const SizedBox(height: 20),
        const Text('Eventos',
            style: TextStyle(
              fontSize: 20, // Ajusta el tamaño de fuente según tus preferencias
              fontWeight: FontWeight.bold, // Puedes ajustar el estilo del texto
            )),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
            ),
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, selectedEvents, _) {
                return ListView.builder(
                  itemCount: selectedEvents.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(selectedEvents[index].nombre_clase),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Ubicación: ${selectedEvents[index].ubicacion_salon}"),
                            Text(
                                "Hora: ${selectedEvents[index].hora_clase.substring(0, 5)} - ${selectedEvents[index].hora_clase.substring(09, 14)}"), // Aquí se muestra el rango de horas sin los segundos
                          ],
                        ),
                        onTap: () {
                          _showEventDetails(selectedEvents[index]);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<String> _getDirectorType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('directorType') ?? '';
  }

  void _showEventDetails(Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(event.nombre_clase),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Docente: ${event.nombre_docente}"),
              Text("Ubicación: ${event.ubicacion_salon}"),
              Text(
                  "Hora: ${event.hora_clase.substring(0, 5)} - ${event.hora_clase.substring(09, 14)}"),
              Text("Jornada: ${event.jornada}")
            ],
          ),
          actions: [
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditarPage(
                                idClase: idClase,
                              )),
                    );
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    prefs.setString('nombre_clase', '${event.nombre_clase}');
                    prefs.setString('jornada', '${event.jornada}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(40, 140, 1, 1),
                  ),
                  child: Text('Editar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EliminarPage()),
                    );
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    prefs.setString('nombre_clase', '${event.nombre_clase}');
                    prefs.setString('jornada', '${event.jornada}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(40, 140, 1, 1),
                  ),
                  child: Text("Eliminar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(40, 140, 1, 1),
                  ),
                  child: Text("Cerrar"),
                ),
              ],
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
        backgroundColor: Color.fromARGB(255, 40, 140, 1),
        title: semestre.isEmpty
            ? const CircularProgressIndicator()
            : Text('Semestre $semestre'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CrearPage()),
          );
        },
        backgroundColor: Color.fromRGBO(40, 140, 1, 1.0),
        child: const Icon(Icons.add),
      ),
      body: content(),
    );
  }
}

class Event {
  String nombre_clase;
  String jornada;
  String nombre_docente;
  String ubicacion_salon;
  String hora_clase;

  Event(this.nombre_clase, this.jornada, this.nombre_docente,
      this.ubicacion_salon, this.hora_clase);
}
