import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Calendar extends StatelessWidget {
  Future<String> obtenerSemestreType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String semestreType = prefs.getString('semestreType') ?? ''; // Valor por defecto si no se encuentra la clave
    return semestreType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Vuelve a la pantalla anterior
          },
        ),
      ),
      body: Center(
        child: FutureBuilder<String>(
          future: obtenerSemestreType(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text('Semestre ${snapshot.data}');
            } else if (snapshot.hasError) {
              return Text('Error al obtener el semestre');
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}
