-- MySQL dump 10.13  Distrib 5.1.62, for unknown-linux-gnu (x86_64)
--
-- Host: localhost    Database: express27
-- ------------------------------------------------------
-- Server version	5.1.62

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
-- Table structure for table `addr`
--

DROP TABLE IF EXISTS `addr`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `addr` (
  `addr_id` int(11) NOT NULL AUTO_INCREMENT,
  `addr` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`addr_id`),
  KEY `addr` (`addr`)
) ENGINE=MyISAM AUTO_INCREMENT=1780 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `boats`
--

DROP TABLE IF EXISTS `boats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `boats` (
  `regattaid` int(12) NOT NULL DEFAULT '0',
  `sailnumber` mediumint(9) NOT NULL DEFAULT '0',
  `skipper` varchar(80) NOT NULL DEFAULT '',
  `crew` varchar(80) NOT NULL DEFAULT '',
  `note` text,
  `status` enum('Sailing','Available','Looking') NOT NULL DEFAULT 'Sailing',
  `lastupdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `regattaid` (`regattaid`),
  KEY `status` (`status`),
  KEY `sailnumber` (`sailnumber`),
  KEY `lastupdate` (`lastupdate`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `crew`
--

DROP TABLE IF EXISTS `crew`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `crew` (
  `id` smallint(6) NOT NULL AUTO_INCREMENT,
  `firstname` varchar(32) NOT NULL DEFAULT '',
  `lastname` varchar(48) NOT NULL DEFAULT '',
  `city` varchar(32) NOT NULL DEFAULT '',
  `state` char(2) NOT NULL DEFAULT '',
  `phone` varchar(20) NOT NULL DEFAULT '',
  `email` varchar(100) NOT NULL DEFAULT '',
  `height` smallint(3) NOT NULL DEFAULT '0',
  `weight` smallint(3) NOT NULL DEFAULT '0',
  `positions` varchar(200) NOT NULL DEFAULT '',
  `note` varchar(500) NOT NULL DEFAULT '',
  `password` varchar(16) NOT NULL DEFAULT '',
  `lastupdateip` varchar(128) NOT NULL DEFAULT '',
  `lastupdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `name` (`lastname`,`firstname`)
) ENGINE=MyISAM AUTO_INCREMENT=87 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dues_paid`
--

DROP TABLE IF EXISTS `dues_paid`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dues_paid` (
  `year` int(10) unsigned NOT NULL DEFAULT '0',
  `hullnumber` int(10) unsigned NOT NULL DEFAULT '0',
  `dues1` tinyint(4) NOT NULL,
  `dues2` tinyint(4) NOT NULL,
  `name` varchar(200) NOT NULL DEFAULT '',
  `note` text,
  `modification_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `dues3` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `dues4` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`year`,`hullnumber`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `email`
--

DROP TABLE IF EXISTS `email`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `email` (
  `email_id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(80) NOT NULL DEFAULT '',
  `modification_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`email_id`),
  KEY `email` (`email`)
) ENGINE=MyISAM AUTO_INCREMENT=721 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `forum`
--

DROP TABLE IF EXISTS `forum`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `forum` (
  `forum_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) NOT NULL DEFAULT '',
  `modification_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`forum_id`),
  KEY `modification_date` (`modification_date`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gallery`
--

DROP TABLE IF EXISTS `gallery`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gallery` (
  `id` int(16) NOT NULL AUTO_INCREMENT,
  `name` varchar(40) NOT NULL DEFAULT '',
  `description` text,
  `hide` tinyint(1) NOT NULL DEFAULT '0',
  KEY `id` (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=120 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gps`
--

DROP TABLE IF EXISTS `gps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gps` (
  `gps_id` int(11) NOT NULL AUTO_INCREMENT,
  `regattaid` int(11) NOT NULL,
  `start_time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `end_time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `day` date NOT NULL,
  `filename` varchar(250) NOT NULL DEFAULT '',
  `boat` varchar(50) NOT NULL DEFAULT '',
  `description` varchar(500) NOT NULL DEFAULT '',
  `upload_date` datetime NOT NULL,
  PRIMARY KEY (`gps_id`),
  KEY `regattaid` (`regattaid`)
) ENGINE=MyISAM AUTO_INCREMENT=19 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `html`
--

DROP TABLE IF EXISTS `html`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `html` (
  `id` int(12) NOT NULL AUTO_INCREMENT,
  `uniquename` varchar(32) NOT NULL DEFAULT '',
  `title` varchar(64) NOT NULL DEFAULT '',
  `html` text,
  `lastupdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniquename` (`uniquename`)
) ENGINE=MyISAM AUTO_INCREMENT=582 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `msg`
--

DROP TABLE IF EXISTS `msg`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `msg` (
  `msg_id` int(11) NOT NULL AUTO_INCREMENT,
  `reply_to` int(11) NOT NULL DEFAULT '0',
  `name_id` int(11) NOT NULL DEFAULT '0',
  `email_id` int(11) NOT NULL DEFAULT '0',
  `txt_id` int(11) NOT NULL DEFAULT '0',
  `addr_id` int(11) NOT NULL DEFAULT '0',
  `title_id` int(11) NOT NULL DEFAULT '0',
  `session_id` int(11) NOT NULL DEFAULT '0',
  `thread_id` int(11) NOT NULL DEFAULT '0',
  `nomessage` tinyint(1) NOT NULL DEFAULT '0',
  `views` int(10) unsigned NOT NULL DEFAULT '0',
  `good` smallint(6) NOT NULL DEFAULT '0',
  `bad` smallint(6) NOT NULL DEFAULT '0',
  `deleted` tinyint(1) NOT NULL DEFAULT '0',
  `password` varchar(40) NOT NULL DEFAULT '',
  `insert_date` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `modification_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`msg_id`),
  KEY `reply_to` (`reply_to`),
  KEY `name_id` (`name_id`),
  KEY `email_id` (`email_id`),
  KEY `insert_date` (`insert_date`)
) ENGINE=MyISAM AUTO_INCREMENT=4419 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `name`
--

DROP TABLE IF EXISTS `name`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `name` (
  `name_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL DEFAULT '',
  `modification_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`name_id`),
  KEY `name` (`name`),
  FULLTEXT KEY `ftname` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=818 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `oldperson`
--

DROP TABLE IF EXISTS `oldperson`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `oldperson` (
  `id` smallint(6) NOT NULL AUTO_INCREMENT,
  `firstname` varchar(32) NOT NULL DEFAULT '',
  `lastname` varchar(48) NOT NULL DEFAULT '',
  `street` varchar(64) DEFAULT NULL,
  `city` varchar(32) DEFAULT NULL,
  `state` char(2) DEFAULT NULL,
  `zip` varchar(10) DEFAULT NULL,
  `homephone` varchar(20) DEFAULT NULL,
  `workphone` varchar(20) DEFAULT NULL,
  `faxphone` varchar(20) DEFAULT NULL,
  `yachtclub` varchar(64) DEFAULT NULL,
  `email` varchar(64) DEFAULT NULL,
  `url` varchar(128) DEFAULT NULL,
  `type` enum('Owner','Crew','Other') DEFAULT NULL,
  `hullnumber` tinyint(4) DEFAULT NULL,
  `special` varchar(64) DEFAULT NULL,
  `specialorder` smallint(6) DEFAULT NULL,
  `note` text,
  `boatname` varchar(64) DEFAULT NULL,
  `sailnumber` varchar(8) DEFAULT NULL,
  `password` varchar(16) DEFAULT NULL,
  `lastupdateip` varchar(128) DEFAULT NULL,
  `lastupdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `firstname` (`firstname`),
  KEY `lastname` (`lastname`)
) ENGINE=MyISAM AUTO_INCREMENT=229 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `person`
--

DROP TABLE IF EXISTS `person`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person` (
  `id` smallint(6) NOT NULL AUTO_INCREMENT,
  `firstname` varchar(32) NOT NULL DEFAULT '',
  `lastname` varchar(48) NOT NULL DEFAULT '',
  `street` varchar(64) NOT NULL DEFAULT '',
  `city` varchar(32) NOT NULL DEFAULT '',
  `state` char(2) NOT NULL DEFAULT '',
  `zip` varchar(10) DEFAULT NULL,
  `phone` varchar(20) NOT NULL DEFAULT '',
  `email` varchar(100) NOT NULL DEFAULT '',
  `url` varchar(128) NOT NULL DEFAULT '',
  `type` enum('Owner','Crew','Other') DEFAULT 'Other',
  `hullnumber` smallint(5) DEFAULT NULL,
  `special` varchar(64) NOT NULL DEFAULT '',
  `specialorder` smallint(6) NOT NULL DEFAULT '0',
  `note` varchar(500) NOT NULL DEFAULT '',
  `boatname` varchar(64) NOT NULL DEFAULT '',
  `sailnumber` varchar(8) NOT NULL DEFAULT '',
  `password` varchar(16) NOT NULL DEFAULT '',
  `photo_id` int(16) NOT NULL DEFAULT '0',
  `lastupdateip` varchar(128) NOT NULL DEFAULT '',
  `lastupdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `specialorder` (`specialorder`),
  KEY `firstname` (`lastname`,`firstname`),
  KEY `hullnumber` (`hullnumber`)
) ENGINE=MyISAM AUTO_INCREMENT=133 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `photo`
--

DROP TABLE IF EXISTS `photo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `photo` (
  `id` int(16) NOT NULL AUTO_INCREMENT,
  `width` int(16) NOT NULL DEFAULT '0',
  `height` int(16) NOT NULL DEFAULT '0',
  `caption` varchar(80) NOT NULL DEFAULT '',
  `gallery_id` int(16) NOT NULL DEFAULT '0',
  `thumb_width` int(16) NOT NULL DEFAULT '0',
  `thumb_height` int(16) NOT NULL DEFAULT '0',
  `hide` tinyint(4) NOT NULL DEFAULT '0',
  `filename` varchar(250) NOT NULL DEFAULT '',
  `sailnumbers` varchar(80) NOT NULL DEFAULT '',
  KEY `id` (`id`),
  KEY `gallery_id` (`gallery_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2916 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `regatta`
--

DROP TABLE IF EXISTS `regatta`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regatta` (
  `id` int(12) NOT NULL AUTO_INCREMENT,
  `startdate` date NOT NULL DEFAULT '0000-00-00',
  `enddate` date DEFAULT NULL,
  `lastupdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `name` varchar(64) NOT NULL DEFAULT '',
  `venue` int(12) NOT NULL DEFAULT '0',
  `contact` int(12) NOT NULL DEFAULT '0',
  `series1` tinyint(4) NOT NULL DEFAULT '0',
  `url` varchar(128) NOT NULL DEFAULT '',
  `result` text,
  `description` text,
  `story` text,
  `series2` tinyint(4) NOT NULL DEFAULT '0',
  `series3` tinyint(4) NOT NULL DEFAULT '0',
  `series4` tinyint(4) NOT NULL DEFAULT '0',
  `series5` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `startdate` (`startdate`),
  KEY `venue` (`venue`),
  KEY `contact` (`contact`)
) ENGINE=MyISAM AUTO_INCREMENT=369 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `session`
--

DROP TABLE IF EXISTS `session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `session` (
  `session_id` int(11) NOT NULL AUTO_INCREMENT,
  `session` char(32) DEFAULT NULL,
  `modification_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`session_id`),
  KEY `session` (`session`)
) ENGINE=MyISAM AUTO_INCREMENT=1669 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `thread`
--

DROP TABLE IF EXISTS `thread`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `thread` (
  `thread_id` int(11) NOT NULL AUTO_INCREMENT,
  `forum_id` int(11) NOT NULL DEFAULT '0',
  `first_msg` int(11) NOT NULL DEFAULT '0',
  `modification_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`thread_id`),
  KEY `forum_id` (`forum_id`),
  KEY `modification_date` (`modification_date`)
) ENGINE=MyISAM AUTO_INCREMENT=1947 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `title`
--

DROP TABLE IF EXISTS `title`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `title` (
  `title_id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(80) NOT NULL DEFAULT '',
  `modification_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`title_id`),
  KEY `title` (`title`),
  FULLTEXT KEY `fttitle` (`title`)
) ENGINE=MyISAM AUTO_INCREMENT=2038 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `txt`
--

DROP TABLE IF EXISTS `txt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `txt` (
  `txt_id` int(11) NOT NULL AUTO_INCREMENT,
  `txt` text,
  PRIMARY KEY (`txt_id`),
  FULLTEXT KEY `fttxt` (`txt`)
) ENGINE=MyISAM AUTO_INCREMENT=4420 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `venue`
--

DROP TABLE IF EXISTS `venue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `venue` (
  `id` int(12) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL DEFAULT '',
  `url` varchar(64) NOT NULL DEFAULT '',
  `address` varchar(128) NOT NULL DEFAULT '',
  `city` varchar(64) NOT NULL DEFAULT '',
  `zip` varchar(10) NOT NULL DEFAULT '',
  `state` char(2) NOT NULL DEFAULT '',
  `lastupdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=45 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2012-11-09 17:46:02
