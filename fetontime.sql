-- MySQL dump 10.13  Distrib 8.0.32, for Win64 (x86_64)
--
-- Host: localhost    Database: fetontime
-- ------------------------------------------------------
-- Server version	8.0.32

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `clases`
--

DROP TABLE IF EXISTS `clases`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `clases` (
  `idClases` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `idfecha_clase` int NOT NULL,
  `idDocentes` int NOT NULL,
  `idSalones` int NOT NULL,
  `modalidad` varchar(30) NOT NULL,
  `programa` varchar(100) NOT NULL,
  PRIMARY KEY (`idClases`,`idfecha_clase`,`idDocentes`,`idSalones`),
  KEY `fk_Clases_fecha_clase1_idx` (`idfecha_clase`),
  KEY `fk_Clases_Docentes1_idx` (`idDocentes`),
  KEY `fk_Clases_Salones1_idx` (`idSalones`),
  CONSTRAINT `fk_Clases_Docentes1` FOREIGN KEY (`idDocentes`) REFERENCES `docentes` (`idDocentes`),
  CONSTRAINT `fk_Clases_fecha_clase1` FOREIGN KEY (`idfecha_clase`) REFERENCES `fecha_clase` (`idfecha_clase`),
  CONSTRAINT `fk_Clases_Salones1` FOREIGN KEY (`idSalones`) REFERENCES `salones` (`idSalones`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clases`
--

LOCK TABLES `clases` WRITE;
/*!40000 ALTER TABLE `clases` DISABLE KEYS */;
/*!40000 ALTER TABLE `clases` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `directores`
--

DROP TABLE IF EXISTS `directores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `directores` (
  `idDirectores` int NOT NULL AUTO_INCREMENT,
  `correo` varchar(45) NOT NULL,
  `contraseña` varchar(45) NOT NULL,
  `programa` varchar(45) NOT NULL,
  PRIMARY KEY (`idDirectores`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `directores`
--

LOCK TABLES `directores` WRITE;
/*!40000 ALTER TABLE `directores` DISABLE KEYS */;
/*!40000 ALTER TABLE `directores` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `docentes`
--

DROP TABLE IF EXISTS `docentes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `docentes` (
  `idDocentes` int NOT NULL AUTO_INCREMENT,
  `Nombre` varchar(45) NOT NULL,
  `programa` varchar(45) NOT NULL,
  PRIMARY KEY (`idDocentes`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `docentes`
--

LOCK TABLES `docentes` WRITE;
/*!40000 ALTER TABLE `docentes` DISABLE KEYS */;
/*!40000 ALTER TABLE `docentes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fecha_clase`
--

DROP TABLE IF EXISTS `fecha_clase`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fecha_clase` (
  `idfecha_clase` int NOT NULL AUTO_INCREMENT,
  `dias` varchar(45) NOT NULL,
  `idhora_clase` int NOT NULL,
  PRIMARY KEY (`idfecha_clase`,`idhora_clase`),
  KEY `fk_fecha_clase_hora_clase_idx` (`idhora_clase`),
  CONSTRAINT `fk_fecha_clase_hora_clase` FOREIGN KEY (`idhora_clase`) REFERENCES `hora_clase` (`idhora_clase`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fecha_clase`
--

LOCK TABLES `fecha_clase` WRITE;
/*!40000 ALTER TABLE `fecha_clase` DISABLE KEYS */;
/*!40000 ALTER TABLE `fecha_clase` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hora_clase`
--

DROP TABLE IF EXISTS `hora_clase`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hora_clase` (
  `idhora_clase` int NOT NULL,
  `hora_inicial` time NOT NULL,
  `hora_final` time NOT NULL,
  PRIMARY KEY (`idhora_clase`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hora_clase`
--

LOCK TABLES `hora_clase` WRITE;
/*!40000 ALTER TABLE `hora_clase` DISABLE KEYS */;
/*!40000 ALTER TABLE `hora_clase` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `salones`
--

DROP TABLE IF EXISTS `salones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `salones` (
  `idSalones` int NOT NULL AUTO_INCREMENT,
  `bloque` varchar(3) NOT NULL,
  `aula` varchar(20) NOT NULL,
  `pupitres` int NOT NULL DEFAULT '0',
  `sillas` int NOT NULL DEFAULT '0',
  `enchufes` int NOT NULL DEFAULT '0',
  `ventiladores` int NOT NULL DEFAULT '0',
  `aires` int NOT NULL DEFAULT '0',
  `tv` int NOT NULL DEFAULT '0',
  `videobeen` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`idSalones`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `salones`
--

LOCK TABLES `salones` WRITE;
/*!40000 ALTER TABLE `salones` DISABLE KEYS */;
/*!40000 ALTER TABLE `salones` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2023-08-08 15:08:35
