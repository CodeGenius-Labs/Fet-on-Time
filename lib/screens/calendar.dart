import 'package:fetontime/screens/editar.dart';
import 'eliminar.dart';
import 'package:flutter/material.dart';
import 'dart:core';
import 'package:flutter_week_view/flutter_week_view.dart';
import 'package:mysql1/mysql1.dart'; // Importa la librería mysql1
import 'package:shared_preferences/shared_preferences.dart';
import '../base_conection.dart'; // Asegúrate de que la ruta sea la correcta
import 'package:intl/intl.dart';

class Calendar extends StatefulWidget {
  const Calendar({Key? key}) : super(key: key);

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  String semestre = '';
  String directorType = ''; // Declaración de la variable directorType
  String dayOfWeek = '';
  MySqlConnection? _connection; // Variable para la conexión
  List<FlutterWeekViewEvent> _events = [];
  bool _isLoading = true; // Variable para controlar el estado de carga

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

    // Obtén la conexión a la base de datos desde el archivo de conexión
    getConnection().then((connection) {
      setState(() {
        _connection = connection;
      });
      dayOfWeek = DateFormat('EEEE', 'es_ES').format(DateTime.now());
      _loadEvents(); // Cargar eventos inicialmente
    });
  }

  void _loadEvents() {
    fetchWeekViewEventsFromDatabase(
      dayOfWeek, // Obtener el nombre del día de hoy
      directorType,
    ).then((events) {
      setState(() {
        _events = events;
        _isLoading = false; // Cambiar el estado de carga
      });
    });
  }

  Future<List<FlutterWeekViewEvent>> fetchWeekViewEventsFromDatabase(
      String dayOfWeek, String directorType) async {
    try {
      final results = await _connection!.query(
        'SELECT c.idClases AS id_clase, m.nombre AS nombre_clase, c.jornada AS jornada, d.Nombre AS nombre_docente, '
            'CONCAT(s.bloque, "-", s.aula) AS ubicacion_salon, fc.dias AS dias, '
            'c.hora_inicial AS hora_inicial, c.hora_final AS hora_final FROM clases c '
            'INNER JOIN docentes d ON c.idDocentes = d.idDocentes '
            'INNER JOIN materias m ON c.idmaterias = m.id '
            'INNER JOIN salones s ON c.idSalones = s.idSalones '
            'INNER JOIN fecha_clase fc ON c.idfecha_clase = fc.idfecha_clase '
            'WHERE c.programa =? AND c.semestre =? '
            'ORDER BY c.hora_inicial',
        [directorType, semestre],
      );

      final events = <FlutterWeekViewEvent>[];
      for (var row in results) {
        // Obtener hora de inicio y finalización de la clase
        String startTimeString = row['hora_inicial'].toString();
        String endTimeString = row['hora_final'].toString();
        String dias = row['dias'].toString();
        int id_clase = row['id_clase'];

        // Convertir las cadenas de hora a objetos DateTime
        List<String> startTimeParts = startTimeString.split(':');
        List<String> endTimeParts = endTimeString.split(':');
        int startHour = int.parse(startTimeParts[0]);
        int startMinute = int.parse(startTimeParts[1]);
        int endHour = int.parse(endTimeParts[0]);
        int endMinute = int.parse(endTimeParts[1]);
        DateTime now = _getWeekdayDate(dias);
        DateTime startTime = DateTime(now.year, now.month, now.day, startHour, startMinute);
        DateTime endTime = DateTime(now.year, now.month, now.day, endHour, endMinute);
        Descripcion descripcion = Descripcion(
            id: id_clase,
            Materia: row['nombre_clase'],
            salon: row['ubicacion_salon'],
            docente: row['nombre_docente'],
            jornada: row['jornada'],
            hora_inicial: startTime,
            hora_final: endTime);

        // Crear un evento FlutterWeekViewEvent
        events.add(
          FlutterWeekViewEvent(
            title: row['nombre_clase'],
            description: '${row['nombre_docente']}, ${row['ubicacion_salon']}',
            start: startTime,
            end: endTime,
            onTap: () => _showEventDetails(context, descripcion),
          ),
        );
      }

      return events;
    } catch (e, stackTrace) {
      print('Error en la búsqueda en la base de datos: $e');
      print('Tipo de error: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  DateTime _getWeekdayDate(String targetDay) {
    DateTime now = DateTime.now();
    List<String> weekDays = [
      'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
    ];

    int currentDayIndex = weekDays.indexOf(DateFormat('EEEE', 'es').format(now).toLowerCase());
    int targetDayIndex = weekDays.indexOf(targetDay.toLowerCase());

    if (targetDayIndex == -1) {
      throw Exception('Día de la semana no válido: $targetDay');
    }

    int difference = targetDayIndex - currentDayIndex;
    if (difference < 0) {
      difference += 7; // Ensure we always get a future date within the next week
    }

    return now.add(Duration(days: difference));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semana'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _events.isEmpty
          ? Center(child: Text('No hay Clases Programadas'))
          : WeekView(
        dates: [
          DateTime.now(),
          for (int i = 1; i <= 6; i++)
            DateTime.now().add(Duration(days: i))
        ],
        dayBarStyleBuilder: (date) {
          return DayBarStyle(
            textStyle: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
            color: Colors.grey[200],
            dateFormatter: (year, month, day) =>
                customDateFormatter(DateTime(year, month, day)),
          );
        },
        initialTime:
        const HourMinute(hour: 7).atDate(DateTime.now()),
        events: _events,
      ),
    );
  }

  String customDateFormatter(DateTime date) {
    // Usa DateFormat de la librería intl para obtener el nombre completo del día
    return DateFormat('EEEE', 'es_ES').format(date); // 'es_ES' para español
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

  void _showEventDetails(BuildContext context, Descripcion descripcion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(descripcion.Materia),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Salon: ${descripcion.salon}"),
              Text("Docente: ${descripcion.docente}"),
              Text("Jornada: ${descripcion.jornada}"),
              Text("Hora de inicio: ${DateFormat('HH:mm').format(descripcion.hora_inicial)}"),
              Text("Hora de fin: ${DateFormat('HH:mm').format(descripcion.hora_final)}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditarPage(
                        idClase: descripcion.id,
                      )),
                );
                _loadEvents(); // Cargar eventos nuevamente al regresar
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(40, 140, 1, 1),
              ),
              child: const Text('Editar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EliminarPage(
                        idClase: descripcion.id,
                      )),
                );
                _loadEvents(); // Cargar eventos nuevamente al regresar
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(40, 140, 1, 1),
              ),
              child: const Text("Eliminar"),
            ),
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
}

class Descripcion {
  int id;
  String Materia;
  String salon;
  String docente;
  String jornada;
  DateTime hora_inicial;
  DateTime hora_final;

  // Constructor con parámetros nombrados y obligatorios
  Descripcion(
      {required this.id,
        required this.Materia,
        required this.salon,
        required this.docente,
        required this.jornada,
        required this.hora_inicial,
        required this.hora_final});
}

void main() => runApp(MaterialApp(home: Calendar()));
