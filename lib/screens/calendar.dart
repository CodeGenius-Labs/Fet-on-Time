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
      // Llama a fetchWeekViewEventsFromDatabase para cargar los eventos desde la base de datos
      fetchWeekViewEventsFromDatabase(
        dayOfWeek, // Obtener el nombre del día de hoy
        directorType,
      ).then((events) {
        setState(() {
          _events = events;
        });
      });
    });
  }

  Future<List<FlutterWeekViewEvent>> fetchWeekViewEventsFromDatabase(
      String dayOfWeek, String directorType) async {
    print(dayOfWeek.runtimeType);
    print(directorType.runtimeType);
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
        //print("FOR= " + row['hora_inicial'].toString() + " - " + row['hora_final'].toString());
        //print("fecha clase: " + row['dias']);
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
        print(startHour);
        print(startMinute);
        //print(startTime);

        // Crear un evento FlutterWeekViewEvent
        events.add(
          FlutterWeekViewEvent(
            title: row['nombre_clase'],
            description: '${row['nombre_docente']}, ${row['ubicacion_salon']}',
            start: startTime,
            end: endTime, onTap: () => _showEventDetails(context, id_clase)
          ),
        );
      }
      events.forEach((event) {
        print('Título: ${event.title}');
        print('Descripción: ${event.description}');
        print('Hora de inicio: ${event.start}');
        print('Hora de fin: ${event.end}');
      });

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
    return FutureBuilder<List<FlutterWeekViewEvent>>(
      future: fetchWeekViewEventsFromDatabase(dayOfWeek, directorType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          List<FlutterWeekViewEvent> events = snapshot.data!;
          // Obtiene la fecha actual
          DateTime now = DateTime.now();
          DateTime date = DateTime(now.year, now.month, now.day);
          // Encuentra el lunes de esta semana
          //DateTime mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));
          // Lista para almacenar todas las fechas de la semana desde el lunes hasta el domingo
          //List<DateTime> weekDates = List.generate(7, (index) => mondayThisWeek.add(Duration(days: index)));

          return Scaffold(
            appBar: AppBar(
              title: const Text('Semana'),
            ),
            body: WeekView(
              dates: [
                date,
                for (int i = 1; i <= 6; i++)
                  date.add(Duration(days: i))
              ],
              dayBarStyleBuilder: (date) {
                return DayBarStyle(
                  textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  color: Colors.grey[200],
                  dateFormatter: (year, month, day) => customDateFormatter(DateTime(year, month, day)),
                );
              },
              initialTime: const HourMinute(hour: 7).atDate(DateTime.now()),
              events: events,

            ),
          );
        }
      },
    );
  }
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
                          idClase: event.id_clase,
                        )),
                  );
                  SharedPreferences prefs =
                  await SharedPreferences.getInstance();
                  prefs.setString('nombre_clase', event.nombre_clase);
                  prefs.setString('jornada', event.jornada);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(40, 140, 1, 1),
                ),
                child: const Text('Editar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EliminarPage(idClase: event.id_clase,)),
                  );
                  SharedPreferences prefs =
                  await SharedPreferences.getInstance();
                  prefs.setString('nombre_clase', event.nombre_clase);
                  prefs.setString('jornada', event.jornada);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(40, 140, 1, 1),
                ),
                child: const Text("Eliminar"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(40, 140, 1, 1),
                ),
                child: const Text("Cerrar"),
              ),
            ],
          ),
        ],
      );
    },
  );
}

void main() => runApp(MaterialApp(home: Calendar()));
