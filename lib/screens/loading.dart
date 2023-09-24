import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _simulateLogin(); // Simular el proceso de inicio de sesión
  }

  // Simular un proceso de inicio de sesión
  Future<void> _simulateLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    String status = prefs.getString('status') ?? '';

    await Future.delayed(Duration(seconds: 2)); // Esperar 2 segundos (simulación)

    if (status == 'home' && isLoggedIn ) {
      Navigator.pushReplacementNamed(context, 'home');
    } else if (status == 'login' && !isLoggedIn) {
      Navigator.pushReplacementNamed(context, 'login');
    } else if (status == 'calendar' && isLoggedIn){
      Navigator.pushReplacementNamed(context, 'calendar');
    }
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
            SizedBox(height: 20),
            CircularProgressIndicator(), // Indicador visual de carga
            SizedBox(height: 10),
            Text('Cargando...'), // Mensaje de carga
          ],
        ),
      ),
    );
  }
}
