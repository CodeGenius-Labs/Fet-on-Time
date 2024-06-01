import 'package:flutter/material.dart';
import 'dart:core';
import 'package:flutter_week_view/flutter_week_view.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../base_conection.dart';
import 'package:intl/intl.dart';

class Calendar extends StatefulWidget {
  const Calendar({Key? key}) : super(key: key);

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  String semestre = '';
  String directorType = '';
  String dayOfWeek = '';
  MySqlConnection? _connection;
  List<FlutterWeekViewEvent> _events = [];

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

      dayOfWeek = DateFormat('EEEE', 'es_ES').format(DateTime.now());

      fetchWeekViewEventsFromDatabase(dayOfWeek, directorType).then((events) {
        setState(() {
          _events = events;
        });
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
        'WHERE c.programa = ? AND c.semestre = ? '
        'ORDER BY c.hora_inicial',
        [directorType, semestre],
      );

      final events = <FlutterWeekViewEvent>[];
      for (var row in results) {
        String startTimeString = row['hora_inicial'].toString();
        String endTimeString = row['hora_final'].toString();
        String dias = row['dias'].toString();

        List<String> startTimeParts = startTimeString.split(':');
        List<String> endTimeParts = endTimeString.split(':');
        int startHour = int.parse(startTimeParts[0]);
        int startMinute = int.parse(startTimeParts[1]);
        int endHour = int.parse(endTimeParts[0]);
        int endMinute = int.parse(endTimeParts[1]);
        DateTime now = _getWeekdayDate(dias);
        DateTime startTime =
            DateTime(now.year, now.month, now.day, startHour, startMinute);
        DateTime endTime =
            DateTime(now.year, now.month, now.day, endHour, endMinute);

        events.add(
          FlutterWeekViewEvent(
            title: row['nombre_clase'],
            description: '${row['nombre_docente']}, ${row['ubicacion_salon']}',
            start: startTime,
            end: endTime,
            onTap: () => _showEventDetails(context, events as Map<String, dynamic>),
          ),
        );
      }

      return events;
    } catch (e, stackTrace) {
      print('Error in database query: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  DateTime _getWeekdayDate(String targetDay) {
    DateTime now = DateTime.now();
    List<String> weekDays = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo'
    ];
    int currentDayIndex =
        weekDays.indexOf(DateFormat('EEEE', 'es').format(now).toLowerCase());
    int targetDayIndex = weekDays.indexOf(targetDay.toLowerCase());

    int difference = targetDayIndex - currentDayIndex;
    if (difference < 0) {
      difference += 7;
    }

    return now.add(Duration(days: difference));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FlutterWeekViewEvent>>(
      future: fetchWeekViewEventsFromDatabase(dayOfWeek, directorType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          List<FlutterWeekViewEvent> events = snapshot.data!;

          DateTime now = DateTime.now();
          DateTime date = DateTime(now.year, now.month, now.day);

          return Scaffold(
            appBar: AppBar(
              title: const Text('Week View'),
            ),
            body: WeekView(
              dates: [
                date,
                for (int i = 1; i <= 6; i++) date.add(Duration(days: i))
              ],
              dayBarStyleBuilder: (date) {
                return DayBarStyle(
                  textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  color: Colors.grey[200],
                  dateFormatter: (year, month, day) =>
                      customDateFormatter(DateTime(year, month, day)),
                );
              },
              initialTime: const HourMinute(hour: 7).atDate(DateTime.now()),
              events: events,
              event: (context, event, start, end, isSameDay) {
                final title = event.title;
                return GestureDetector(
                  onTap: () => _showEventDetails(context, event),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue,
                    ),
                    padding: EdgeInsets.all(8),
                    child: Text(
                      title,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }

  String customDateFormatter(DateTime date) {
    return DateFormat('EEEE', 'es_ES').format(date);
  }

  Future<String> obtenerSemestreType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('semestreType') ?? '';
  }

  Future<String> _getDirectorType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('directorType') ?? '';
  }

  void _showEventDetails(BuildContext context, Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(event['nombre_clase']),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Description: ${event['nombre_docente']}, ${event['ubicacion_salon']}"),
              Text("Start Time: ${DateFormat('HH:mm').format(event['hora_inicial'])}"),
              Text("End Time: ${DateFormat('HH:mm').format(event['hora_final'])}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _editEvent(event);
              },
              child: Text('Edit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEvent(event);
              },
              child: Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _editEvent(Map<String, dynamic> event) {
    // Implement edit event logic here
    print('Edit event: ${event['nombre_clase']}');
  }

  void _deleteEvent(Map<String, dynamic> event) {
    // Implement delete event logic here
    print('Delete event: ${event['nombre_clase']}');
  }
}

void main() => runApp(MaterialApp(home: Calendar()));