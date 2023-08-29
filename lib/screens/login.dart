import '../base_conection.dart';
import 'package:fetontime/widgets/input_decoration.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


// ignore: must_be_immutable
class login extends StatelessWidget {
  String _email = ''; // Variable para almacenar el correo electrónico
  String _password = ''; // Variable para almacenar la contraseña

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context)
        .size; //este metodo se usa para que me devuelva el tamaño de la pantalla
    return Scaffold(
      body: SizedBox(
        width: double
            .infinity, //double.inifinity quiere decir que se va a ocupar todo el ancho de extremo a extremo
        height: double.infinity,
        child: Stack(
          //stack se usa para poder agregar un children que es donde se pondran una lista de widgets juntos
          children: [cajaverde(size), iconopersona(), loginform(context)],
        ),
      ),
    );
  }

  SingleChildScrollView loginform(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 250),
          Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20,
                      offset: Offset(0, 5),
                    )
                  ]),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text('Login',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 30),
                  Container(
                    child: Form(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            autocorrect:
                                false, //esta propiedad es para que no sirve el autocorrector en este campo
                            decoration: InputDecorations.inputDecoration(
                                hintText: 'ejemplo@fet.edu.co',
                                labelText: 'Correo Electronico',
                                icono:
                                    const Icon(Icons.alternate_email_rounded)),
                            onChanged: (value) {
                              _email = value; // Actualiza la variable _email cuando el valor cambia
                            },
                            validator: (value) {
                              String pattern =
                                  r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                              RegExp regExp = new RegExp(pattern);
                              return regExp.hasMatch(value ?? '')
                                  ? null
                                  : 'El valor ingresado no es un correo'; //no entiendo esto asi que no me pregunte xd
                            },
                          ),
                          const SizedBox(height: 30),
                          TextFormField(
                              autocorrect:
                                  false, //esta propiedad es para que no sirve el autocorrector en este campo
                              obscureText: true,
                              decoration: InputDecorations.inputDecoration(
                                  hintText: '********',
                                  labelText: 'Contraseña',
                                  icono: const Icon(Icons.lock_outlined)),
                              onChanged: (value) {
                                _password = value; // Actualiza la variable _password cuando el valor cambia
                              },
                                  validator: (value) {
                                    return (value != null && value.length >= 6)
                                    ? null
                                    : 'La contraseña esta mal';
                                  },
                                  ),
                          const SizedBox(height: 30),
                          MaterialButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            disabledColor: Colors.grey,
                            color: Colors.green,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 80, vertical: 15),
                              child: const Text(
                                'Ingresar',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            onPressed: () async {

                              // Realizar la consulta a la base de datos
                              final connection = await getConnection();
                              final result = await connection.query(
                                'SELECT * FROM directores WHERE email = ? AND password = ?',
                                [_email, _password],
                              );

                              await connection.close();

                              if (result.isNotEmpty) {
                                // Si se encontró un registro, el inicio de sesión es exitoso
                                // Obtiene el tipo de director de la consulta
                                String directorType = result.first['programa'];

                                // Guarda el tipo de director en las shared_preferences
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                prefs.setBool('isLoggedIn', true); // Guarda el indicador de autenticación
                                prefs.setString('directorType', directorType);
                                Navigator.pushReplacementNamed(context, 'loadinglogin');
                              } else {
                                // Si no se encontró un registro, mostrar un mensaje de error
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Correo o contraseña incorrectos.'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              )),
          const SizedBox(height: 50),
          const Text(
            'Crear Una Nueva Cuenta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  SafeArea iconopersona() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 30),
        width: double.infinity,
        child: const Icon(
          Icons.person_pin,
          color: Colors.white,
          size: 100,
        ),
      ),
    );
  }

  Container cajaverde(Size size) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
        Color.fromRGBO(62, 209, 101, 1),
        Color.fromRGBO(49, 226, 96, 1)
      ])),
      width: double.infinity,
      height: size.height * 0.4,
      child: Stack(
        children: [
          // ignore: sort_child_properties_last
          Positioned(
            child: burbuja(),
            top: 90,
            left: 30,
          ),
          // ignore: sort_child_properties_last
          Positioned(
            child: burbuja(),
            top: -40,
            left: -30,
          ),
          // ignore: sort_child_properties_last
          Positioned(
            child: burbuja(),
            top: -50,
            right: -20,
          ),
          // ignore: sort_child_properties_last
          Positioned(
            child: burbuja(),
            bottom: -50,
            left: -10,
          ),
          // ignore: sort_child_properties_last
          Positioned(
            child: burbuja(),
            bottom: 120,
            right: -20,
          ),
        ],
      ),
    );
  }

  Container burbuja() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: const Color.fromRGBO(255, 255, 255, 0.2)),
    );
  }
}
