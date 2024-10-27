import 'package:fetontime/screens/calendar.dart';
import 'package:fetontime/screens/calendar2.dart';
import 'package:fetontime/screens/crear.dart';
import 'package:fetontime/screens/verhorarios.dart';
import 'package:fetontime/screens/crearhorarios.dart';
import 'package:fetontime/screens/login.dart';
import 'package:fetontime/screens/inicio.dart';
// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}
//void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fet On Time',
      routes: {
        'login': (_) => login(), // Elimina 'const' aquí
        'VerHorarios': (_) => const VerHorarios(),
        'CrearHorario': (_) => const CrearHorario(),
        'inicio': (_) => const HomePage(),
        'loading': (_) => const LoadingScreen(), // Agrega esta línea
        'loadinglogin': (_) => const LoadingScreen(),
        'calendar': (_) => const Calendar(),
        'crear': (_) => const CrearPage(),
      },
      initialRoute: 'loading',
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoggedInStatus();
  }

  Future<void> _checkLoggedInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Simula una pausa para mostrar el logo
    await Future.delayed(const Duration(seconds: 2));

    Navigator.pushReplacementNamed(context, isLoggedIn ? 'inicio' : 'login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logofet.png', // Ruta de tu imagen del logo en la carpeta "assets"
              width: 150, // Ancho deseado del logo
              height: 150, // Alto deseado del logo
            ),
            const SizedBox(
                height:
                    20), // Espacio entre el logo y el CircularProgressIndicator
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
