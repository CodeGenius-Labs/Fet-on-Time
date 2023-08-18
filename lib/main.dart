import 'package:fetontime/screens/home.dart';
import 'package:fetontime/screens/login.dart';
// ignore: unused_import
import 'package:fetontime/screens/loading.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fet On Time',
      routes: {
        'login': (_) => login(), // Elimina 'const' aquí
        'home': (_) => const home(),
        'loading': (_) => LoadingScreen(), // Agrega esta línea
        'loadinglogin': (_) => LoadingScreen(),
      },
      initialRoute: 'loading',
    );
  }
}

class LoadingScreen extends StatefulWidget {
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
    await Future.delayed(Duration(seconds: 2));

    Navigator.pushReplacementNamed(context, isLoggedIn ? 'home' : 'login');
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
            SizedBox(height: 20), // Espacio entre el logo y el CircularProgressIndicator
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

