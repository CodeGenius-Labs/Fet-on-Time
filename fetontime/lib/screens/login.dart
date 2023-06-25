import 'package:flutter/material.dart';

class login extends StatelessWidget {
  const login({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;//este metodo se usa para que me devuelva el tamaño de la pantalla
    return Scaffold(
     body: Container(
      width: double.infinity,//double.inifinity quiere decir que se va a ocupar todo el ancho de extremo a extremo
      height: double.infinity,
      child: Stack(//stack se usa para poder agregar un children que es donde se pondran una lista de widgets juntos
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                Color.fromRGBO(62, 209, 101, 1),
                Color.fromRGBO(49, 226, 96, 1)
              ])
            ),
            width: double.infinity,
            height: size.height * 0.4,
          ),
          SafeArea(
            child: Container(
              margin: const EdgeInsets.only(top: 30),
              width: double.infinity,
              child: const Icon(
                Icons.person_pin,
                color: Colors.white,
                size: 100,),
            ),
          )
        ],
      ),
     ), 
    );
  }
}