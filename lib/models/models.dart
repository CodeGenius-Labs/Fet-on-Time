import 'package:flutter/material.dart';

class Clase {
  final int id;
  final int idMaterias;
  final int idDocentes;
  final int idSalones;
  final String semestre;
  final TimeOfDay horaInicial;
  final TimeOfDay horaFinal;
  final String programa;
  final String jornada;
  final int idfecha_clase; // Asegúrate de que esta propiedad esté en tu tabla

  Clase({
    required this.id,
    required this.idMaterias,
    required this.idDocentes,
    required this.idSalones,
    required this.semestre,
    required this.horaInicial,
    required this.horaFinal,
    required this.programa,
    required this.jornada,
    required this.idfecha_clase,
  });
}

class FranjaHoraria {
  TimeOfDay inicio;
  TimeOfDay fin;

  FranjaHoraria(this.inicio, this.fin);
}

class Docente {
  final int id;
  final String nombre;

  Docente(this.id, this.nombre);
}

class Materias {
  final int id;
  final String nombre;
  final int creditos;

  Materias(this.id, this.nombre, this.creditos);
}
