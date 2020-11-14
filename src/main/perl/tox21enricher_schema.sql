-- MySQL dump 10.13  Distrib 5.7.30, for Linux (x86_64)
--
-- Host: localhost    Database: tox21enricher
-- ------------------------------------------------------
-- Server version	5.7.30-0ubuntu0.16.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `annotation_class`
--

DROP TABLE IF EXISTS `annotation_class`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `annotation_class` (
  `annoClassID` int(5) NOT NULL AUTO_INCREMENT,
  `annoClassName` varchar(50) NOT NULL,
  `firstTermID` int(10) NOT NULL,
  `lastTermID` int(10) NOT NULL,
  `numberOfTermIDs` int(10) NOT NULL,
  `baseURL` varchar(255) DEFAULT NULL,
  `annoType` varchar(45) NOT NULL,
  `annoDesc` varchar(1400) DEFAULT NULL,
  `annoGroovyClassName` varchar(50) NOT NULL,
  PRIMARY KEY (`annoClassID`)
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `annotation_detail`
--

DROP TABLE IF EXISTS `annotation_detail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `annotation_detail` (
  `annoTermID` int(10) NOT NULL,
  `annoClassID` int(5) NOT NULL,
  `annoTerm` varchar(400) NOT NULL,
  PRIMARY KEY (`annoTermID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `annoterm_pairwise`
--

DROP TABLE IF EXISTS `annoterm_pairwise`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `annoterm_pairwise` (
  `pairwiseID` int(20) NOT NULL AUTO_INCREMENT,
  `term1UID` int(10) NOT NULL,
  `term2UID` int(10) NOT NULL,
  `term1Size` int(5) NOT NULL,
  `term2Size` int(5) NOT NULL,
  `common` int(5) NOT NULL,
  `union` int(5) NOT NULL,
  `jaccardIndex` double(15,10) NOT NULL,
  `pvalue` double(15,10) NOT NULL,
  `qvalue` double(15,10) NOT NULL,
  PRIMARY KEY (`pairwiseID`),
  KEY `term1UID` (`term1UID`) USING HASH,
  KEY `term2UID` (`term2UID`) USING HASH
) ENGINE=InnoDB AUTO_INCREMENT=24326616 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `chemical_detail`
--

DROP TABLE IF EXISTS `chemical_detail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `chemical_detail` (
  `CASRNUID` int(5) NOT NULL AUTO_INCREMENT,
  `CASRN` varchar(15) NOT NULL,
  `TestSubstance_ChemName` varchar(500) NOT NULL,
  `Molecular_Formular` varchar(50) DEFAULT NULL,
  `IUPAC_Name` varchar(1000) DEFAULT NULL,
  `InChI` varchar(1000) DEFAULT NULL,
  `InChiKey` varchar(30) DEFAULT NULL,
  `SMILES` varchar(600) DEFAULT NULL,
  PRIMARY KEY (`CASRNUID`)
) ENGINE=InnoDB AUTO_INCREMENT=8949 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `result_set_model`
--

DROP TABLE IF EXISTS `result_set_model`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `result_set_model` (
  `id` bigint(20) DEFAULT NULL,
  `version` bigint(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `term2casrn_mapping`
--

DROP TABLE IF EXISTS `term2casrn_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `term2casrn_mapping` (
  `term2casrnMappingUID` int(10) NOT NULL AUTO_INCREMENT,
  `annoTermID` int(10) NOT NULL,
  `annoClassID` int(5) NOT NULL,
  `CASRNUID` int(10) NOT NULL,
  PRIMARY KEY (`term2casrnMappingUID`)
) ENGINE=InnoDB AUTO_INCREMENT=1414142 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2020-06-29 20:27:18
