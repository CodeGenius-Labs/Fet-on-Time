import 'package:flutter/material.dart';

class login extends StatelessWidget {
  const login({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context)
        .size; //este metodo se usa para que me devuelva el tamaño de la pantalla
    return Scaffold(
      body: Container(
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

  Column loginform(BuildContext context) {
    return Column(
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
              ],
            )),
        const SizedBox(height: 50),
        const Text(
          'Crear Una Nueva Cuenta',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        )
      ],
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
          Positioned(child: burbuja(),top: 90,left: 30,),
          // ignore: sort_child_properties_last
          Positioned(child: burbuja(),top: -40,left: -30,),
          // ignore: sort_child_properties_last
          Positioned(child: burbuja(),top: -50,right: -20,),
          // ignore: sort_child_properties_last
          Positioned(child: burbuja(),bottom: -50,left: -10,),
          // ignore: sort_child_properties_last
          Positioned(child: burbuja(),bottom: 120,right: -20,),

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
