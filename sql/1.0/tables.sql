-- MySQL dump 10.13  Distrib 5.1.56, for unknown-linux-gnu (x86_64)
--
-- Host: localhost    Database: pp
-- ------------------------------------------------------
-- Server version	5.1.56-log

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
-- Table structure for table `_descendants`
--

DROP TABLE IF EXISTS `_descendants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `_descendants` (
  `cId` int(10) unsigned NOT NULL DEFAULT '0',
  KEY `cId` (`cId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `affiliate_quotes`
--

DROP TABLE IF EXISTS `affiliate_quotes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `affiliate_quotes` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `eId` varchar(12) DEFAULT NULL,
  `company` varchar(32) DEFAULT NULL,
  `locale` varchar(8) DEFAULT NULL,
  `state` varchar(8) DEFAULT NULL,
  `price` decimal(16,2) DEFAULT NULL,
  `currency` varchar(20) DEFAULT NULL,
  `usd_price` decimal(16,2) DEFAULT NULL,
  `link` varchar(255) DEFAULT NULL,
  `found` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `link_class` varchar(64) DEFAULT NULL,
  `bargain_ratio` int(10) unsigned DEFAULT '0',
  `detailsURL` varchar(514) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `eId` (`eId`,`company`,`locale`,`state`),
  KEY `bargain_ratio` (`bargain_ratio`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `affils`
--

DROP TABLE IF EXISTS `affils`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `affils` (
  `iId` int(11) DEFAULT NULL,
  `role` varchar(64) DEFAULT NULL,
  `rank` int(11) DEFAULT '0',
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `discipline` varchar(100) DEFAULT 'Philosophy',
  `inst_manual` varchar(100) DEFAULT NULL,
  `year` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `affil` (`iId`,`role`,`rank`,`discipline`,`inst_manual`,`year`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=13114 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `affils_m`
--

DROP TABLE IF EXISTS `affils_m`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `affils_m` (
  `uId` int(11) NOT NULL,
  `aId` int(11) NOT NULL,
  PRIMARY KEY (`uId`,`aId`),
  KEY `uId` (`uId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `alerts`
--

DROP TABLE IF EXISTS `alerts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `alerts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `url` varchar(1000) DEFAULT NULL,
  `freq` int(6) unsigned DEFAULT '7',
  `lastChecked` datetime DEFAULT '0000-00-00 00:00:00',
  `uId` int(10) unsigned DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `deprecated` tinyint(1) unsigned DEFAULT '0',
  `notes` varchar(255) DEFAULT NULL,
  `failures` int(3) unsigned DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `uId` (`uId`)
) ENGINE=InnoDB AUTO_INCREMENT=1142 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `aliases`
--

DROP TABLE IF EXISTS `aliases`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `aliases` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uId` int(11) DEFAULT NULL,
  `firstname` varchar(128) DEFAULT NULL,
  `lastname` varchar(128) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `uId` (`uId`,`firstname`,`lastname`),
  KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=119522 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ancestors`
--

DROP TABLE IF EXISTS `ancestors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ancestors` (
  `aId` int(10) unsigned NOT NULL DEFAULT '0',
  `cId` int(10) unsigned NOT NULL DEFAULT '0',
  `prime` tinyint(4) DEFAULT '0',
  `distance` int(10) unsigned DEFAULT NULL,
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `aId_2` (`aId`,`cId`),
  KEY `aId` (`aId`),
  KEY `cId` (`cId`)
) ENGINE=MyISAM AUTO_INCREMENT=37466 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `answer_opts`
--

DROP TABLE IF EXISTS `answer_opts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `answer_opts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `qId` int(10) unsigned DEFAULT NULL,
  `other` tinyint(1) unsigned DEFAULT '0',
  `value` varchar(1000) DEFAULT NULL,
  `follow` int(10) unsigned DEFAULT NULL,
  `hidden` tinyint(1) unsigned DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `qId` (`qId`),
  KEY `other` (`other`),
  KEY `follow` (`follow`)
) ENGINE=InnoDB AUTO_INCREMENT=14438 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `answers`
--

DROP TABLE IF EXISTS `answers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `answers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uId` int(11) DEFAULT NULL,
  `qId` int(10) unsigned DEFAULT NULL,
  `anId` int(10) unsigned DEFAULT NULL,
  `text` varchar(1000) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `superseded` datetime DEFAULT NULL,
  `comment` text,
  `skipped` tinyint(1) unsigned DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `uId` (`uId`),
  KEY `qId` (`qId`),
  KEY `anId` (`anId`)
) ENGINE=InnoDB AUTO_INCREMENT=259220 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `aos_m`
--

DROP TABLE IF EXISTS `aos_m`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `aos_m` (
  `aId` int(8) NOT NULL DEFAULT '0',
  `mId` int(32) NOT NULL DEFAULT '0',
  `rank` int(10) unsigned DEFAULT '0',
  PRIMARY KEY (`aId`,`mId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `areas`
--

DROP TABLE IF EXISTS `areas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `areas` (
  `id` int(8) NOT NULL DEFAULT '0',
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=42 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `areas_m`
--

DROP TABLE IF EXISTS `areas_m`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `areas_m` (
  `aId` int(8) NOT NULL DEFAULT '0',
  `mId` int(32) NOT NULL DEFAULT '0',
  `rank` int(10) unsigned DEFAULT '0',
  PRIMARY KEY (`aId`,`mId`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `areas_ml`
--

DROP TABLE IF EXISTS `areas_ml`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `areas_ml` (
  `aId` int(8) NOT NULL DEFAULT '0',
  `mId` int(16) NOT NULL DEFAULT '0',
  PRIMARY KEY (`aId`,`mId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `author_aliases`
--

DROP TABLE IF EXISTS `author_aliases`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `author_aliases` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(128) DEFAULT NULL,
  `alias` varchar(128) DEFAULT NULL,
  `to_display` tinyint(1) DEFAULT NULL,
  `is_dead` tinyint(1) DEFAULT NULL,
  `is_strengthening` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `name` (`name`),
  KEY `alias` (`alias`)
) ENGINE=MyISAM AUTO_INCREMENT=471019 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `author_areas`
--

DROP TABLE IF EXISTS `author_areas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `author_areas` (
  `name` varchar(255) DEFAULT NULL,
  `cId` int(10) unsigned NOT NULL DEFAULT '0',
  `nb` bigint(21) NOT NULL DEFAULT '0',
  KEY `cId` (`cId`,`nb`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `author_weakenings`
--

DROP TABLE IF EXISTS `author_weakenings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `author_weakenings` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `eId` varchar(11) DEFAULT NULL,
  `firstname` varchar(255) DEFAULT NULL,
  `lastname` varchar(255) DEFAULT NULL,
  `weakened_first` varchar(255) DEFAULT NULL,
  `weakened_last` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `firstname` (`firstname`(128),`lastname`(128)),
  KEY `weakened_first` (`weakened_first`(128),`weakened_last`(128))
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `author_weakenings_1`
--

DROP TABLE IF EXISTS `author_weakenings_1`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `author_weakenings_1` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `eId` text,
  `firstname` varchar(128) DEFAULT NULL,
  `lastname` varchar(128) DEFAULT NULL,
  `weakened_first` varchar(128) DEFAULT NULL,
  `weakened_last` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `firstname` (`firstname`,`lastname`),
  KEY `weakened_first` (`weakened_first`,`weakened_last`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `batch`
--

DROP TABLE IF EXISTS `batch`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `batch` (
  `id` int(12) unsigned NOT NULL AUTO_INCREMENT,
  `uId` int(12) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `errors` text,
  `ok` tinyint(1) unsigned DEFAULT '1',
  `finished` tinyint(1) unsigned DEFAULT '0',
  `inputFile` varchar(255) DEFAULT NULL,
  `format` varchar(100) DEFAULT NULL,
  `cId` int(12) unsigned DEFAULT NULL,
  `notFound` int(15) unsigned DEFAULT '0',
  `msg` varchar(255) DEFAULT NULL,
  `ticket` varchar(255) DEFAULT NULL,
  `found` int(15) unsigned DEFAULT '0',
  `createMissing` tinyint(1) unsigned DEFAULT '0',
  `categorized` int(15) unsigned DEFAULT '0',
  `completed` datetime DEFAULT NULL,
  `inserted` int(10) unsigned DEFAULT NULL,
  `checked` tinyint(1) unsigned DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `ticket` (`ticket`)
) ENGINE=MyISAM AUTO_INCREMENT=719 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `browse_c`
--

DROP TABLE IF EXISTS `browse_c`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `browse_c` (
  `catId` varchar(11) CHARACTER SET latin1 DEFAULT '',
  `day` date DEFAULT NULL,
  `nb` bigint(21) NOT NULL DEFAULT '0',
  KEY `catId` (`catId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache_objects`
--

DROP TABLE IF EXISTS `cache_objects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache_objects` (
  `id` int(16) unsigned NOT NULL AUTO_INCREMENT,
  `class` varchar(128) DEFAULT NULL,
  `oId` varchar(16) DEFAULT NULL,
  `content` blob,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=735123 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cat_edits`
--

DROP TABLE IF EXISTS `cat_edits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cat_edits` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uId` int(10) unsigned DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `cmds` text,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=139 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cats`
--

DROP TABLE IF EXISTS `cats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cats` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `exclusions` int(10) unsigned NOT NULL,
  `owner` int(10) unsigned NOT NULL DEFAULT '0',
  `groups_c` int(10) unsigned DEFAULT '0',
  `forum_id` int(10) unsigned NOT NULL,
  `system` tinyint(3) unsigned NOT NULL,
  `publish` tinyint(3) unsigned NOT NULL,
  `writable` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `hidden` tinyint(3) unsigned DEFAULT '0',
  `level` int(8) DEFAULT NULL,
  `seeAlso` int(10) unsigned DEFAULT NULL,
  `created` datetime NOT NULL,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `filter_id` int(10) unsigned NOT NULL,
  `description` varchar(500) NOT NULL,
  `negative` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `canonical` tinyint(4) DEFAULT '0',
  `numid` varchar(10) DEFAULT NULL,
  `catCount` int(10) unsigned DEFAULT '0',
  `count` int(10) unsigned DEFAULT NULL,
  `condCounts` blob,
  `related` int(11) DEFAULT NULL,
  `highestLevel` int(11) DEFAULT NULL,
  `postCount` int(10) unsigned DEFAULT '0',
  `gId` int(10) unsigned DEFAULT NULL,
  `fId` int(10) unsigned DEFAULT NULL,
  `ppId` int(10) unsigned DEFAULT NULL,
  `greedy` tinyint(3) DEFAULT '0',
  `mp` tinyint(3) DEFAULT '0',
  `fnumid` varchar(10) DEFAULT NULL,
  `ifId` int(10) unsigned DEFAULT '0',
  `useAutoCat` tinyint(1) unsigned DEFAULT '0',
  `flags` set('HISTORICAL') DEFAULT '',
  `dfo` int(10) unsigned DEFAULT NULL,
  `pLevel` int(6) DEFAULT '-1',
  `edfo` int(10) unsigned DEFAULT NULL,
  `uName` varchar(200) DEFAULT NULL,
  `marginal` tinyint(1) unsigned DEFAULT '0',
  `edfId` int(12) unsigned DEFAULT '0',
  `edfChecked` datetime DEFAULT NULL,
  `edEnd` datetime DEFAULT '1970-01-01 00:00:00',
  `cacheId` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `canonical` (`canonical`),
  KEY `niceId` (`numid`),
  KEY `name` (`name`),
  KEY `dfo` (`dfo`),
  KEY `pLevel` (`pLevel`),
  KEY `uName` (`uName`),
  KEY `uName_2` (`uName`)
) ENGINE=InnoDB AUTO_INCREMENT=27260 DEFAULT CHARSET=utf8 PACK_KEYS=1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cats_e`
--

DROP TABLE IF EXISTS `cats_e`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cats_e` (
  `cId` int(10) unsigned DEFAULT NULL,
  `uId` int(11) DEFAULT NULL,
  `id` int(16) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cId` (`cId`,`uId`),
  KEY `cId_2` (`cId`),
  KEY `uId` (`uId`)
) ENGINE=MyISAM AUTO_INCREMENT=989 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cats_eterms`
--

DROP TABLE IF EXISTS `cats_eterms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cats_eterms` (
  `cId` int(10) unsigned DEFAULT NULL,
  `uId` int(11) DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `start` datetime DEFAULT NULL,
  `end` datetime DEFAULT NULL,
  `current` tinyint(1) unsigned DEFAULT '0',
  `recursive` tinyint(1) unsigned DEFAULT '0',
  `comment` text,
  `id` int(20) unsigned NOT NULL AUTO_INCREMENT,
  `confirmBy` datetime DEFAULT NULL,
  `status` int(11) DEFAULT '0',
  `renew` tinyint(1) unsigned DEFAULT '1',
  `IO` int(10) unsigned DEFAULT NULL,
  `imports` int(10) unsigned DEFAULT NULL,
  `checked` int(10) unsigned DEFAULT NULL,
  `excluded` int(10) unsigned DEFAULT NULL,
  `GIO` int(10) unsigned DEFAULT NULL,
  `confirmWarnings` int(10) unsigned DEFAULT '100',
  `auto` tinyint(1) DEFAULT '0',
  `added` int(10) unsigned DEFAULT '0',
  `lastAdded` datetime DEFAULT NULL,
  `entryCount` int(10) unsigned DEFAULT NULL,
  `entryCountUnder` int(10) unsigned DEFAULT NULL,
  `input` int(10) unsigned DEFAULT '0',
  `output` int(10) unsigned DEFAULT '0',
  `input6m` int(10) unsigned DEFAULT '0',
  `output6m` int(10) unsigned DEFAULT '0',
  `inputu6m` int(10) unsigned DEFAULT '0',
  `inputu` int(10) unsigned DEFAULT '0',
  `lastMessage` text,
  `lastMessageTime` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `uId` (`uId`),
  KEY `status` (`status`),
  KEY `end` (`end`),
  KEY `cId` (`cId`),
  CONSTRAINT `cats_eterms_ibfk_1` FOREIGN KEY (`cId`) REFERENCES `cats` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1707 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cats_m`
--

DROP TABLE IF EXISTS `cats_m`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cats_m` (
  `pId` int(10) unsigned NOT NULL DEFAULT '0',
  `cId` int(10) unsigned NOT NULL DEFAULT '0',
  `rank` int(10) unsigned NOT NULL,
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pId_2` (`pId`,`cId`),
  KEY `child` (`cId`),
  KEY `pId` (`pId`),
  CONSTRAINT `child` FOREIGN KEY (`cId`) REFERENCES `cats` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `parent` FOREIGN KEY (`pId`) REFERENCES `cats` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8664 DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cats_me`
--

DROP TABLE IF EXISTS `cats_me`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cats_me` (
  `cId` int(10) unsigned NOT NULL DEFAULT '0',
  `eId` varchar(11) NOT NULL DEFAULT '',
  `rank` int(10) unsigned NOT NULL DEFAULT '0',
  `id` int(32) NOT NULL AUTO_INCREMENT,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `editor` tinyint(1) unsigned DEFAULT '0',
  `setAside` tinyint(1) unsigned DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `cId` (`cId`,`eId`),
  KEY `eId` (`eId`),
  KEY `cId_2` (`cId`),
  KEY `created` (`created`)
) ENGINE=MyISAM AUTO_INCREMENT=633089 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cats_mg`
--

DROP TABLE IF EXISTS `cats_mg`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cats_mg` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `gId` int(10) unsigned NOT NULL,
  `cId` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cId` (`cId`,`gId`)
) ENGINE=InnoDB AUTO_INCREMENT=46 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `citations`
--

DROP TABLE IF EXISTS `citations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `citations` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `xml` text,
  `volume` int(11) DEFAULT NULL,
  `issue` varchar(32) DEFAULT NULL,
  `issn` varchar(100) DEFAULT NULL,
  `title` varchar(1000) DEFAULT NULL,
  `pages` varchar(32) DEFAULT NULL,
  `source` varchar(255) DEFAULT NULL,
  `authors` varchar(1000) DEFAULT NULL,
  `date` varchar(16) DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  `fromeId` varchar(11) DEFAULT NULL,
  `toeId` varchar(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `xml` (`xml`(255)),
  KEY `fromeId` (`fromeId`),
  KEY `toeId` (`toeId`)
) ENGINE=MyISAM AUTO_INCREMENT=1575825 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `crossref_journals`
--

DROP TABLE IF EXISTS `crossref_journals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `crossref_journals` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `issn` varchar(16) DEFAULT NULL,
  `issn2` varchar(16) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  `lastIssue` varchar(255) DEFAULT NULL,
  `publisher` varchar(255) DEFAULT NULL,
  `subjects` text,
  `localName` varchar(255) DEFAULT NULL,
  `harvestJournalId` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `issn` (`issn`),
  FULLTEXT KEY `name` (`name`,`subjects`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `diff_applied`
--

DROP TABLE IF EXISTS `diff_applied`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `diff_applied` (
  `id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `diff_groups`
--

DROP TABLE IF EXISTS `diff_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `diff_groups` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uId` int(12) unsigned DEFAULT NULL,
  `type` varchar(20) DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `status` int(8) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `diffs`
--

DROP TABLE IF EXISTS `diffs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `diffs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `class` varchar(255) NOT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `status` smallint(5) DEFAULT NULL,
  `diffb` longblob,
  `type` enum('update','delete','add','restore') DEFAULT NULL,
  `oId` varchar(32) DEFAULT NULL,
  `reverse_of` int(10) unsigned DEFAULT '0',
  `status_changed` datetime DEFAULT NULL,
  `uId` int(11) DEFAULT NULL,
  `relo1` varchar(64) DEFAULT NULL,
  `relo2` varchar(64) DEFAULT NULL,
  `host` varchar(255) DEFAULT NULL,
  `session` varchar(255) DEFAULT NULL,
  `checked` tinyint(4) DEFAULT '0',
  `note` varchar(500) DEFAULT NULL,
  `reversed` tinyint(1) unsigned DEFAULT '0',
  `version` int(4) DEFAULT '0',
  `dgId` int(12) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `relo1` (`relo1`),
  KEY `relo2` (`relo2`),
  KEY `oId` (`oId`),
  KEY `status` (`status`),
  KEY `checked` (`checked`),
  KEY `class` (`class`),
  KEY `created` (`created`),
  KEY `updated` (`updated`),
  KEY `reverse_of` (`reverse_of`),
  KEY `session` (`session`),
  KEY `uId` (`uId`)
) ENGINE=MyISAM AUTO_INCREMENT=810707 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `editor_invitations`
--

DROP TABLE IF EXISTS `editor_invitations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `editor_invitations` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uId` int(11) DEFAULT NULL,
  `cId` int(11) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `sent_at` datetime DEFAULT NULL,
  `status` char(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `uId` (`uId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `entry_origin`
--

DROP TABLE IF EXISTS `entry_origin`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `entry_origin` (
  `eId` varchar(32) NOT NULL DEFAULT '',
  `repo_id` int(11) DEFAULT NULL,
  `set_spec` varchar(255) DEFAULT NULL,
  `set_name` varchar(255) DEFAULT NULL,
  `type` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`eId`),
  KEY `repo_id` (`repo_id`),
  KEY `set_spec` (`set_spec`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`xpapers`@`localhost`*/ /*!50003 TRIGGER entry_origin_ins AFTER  INSERT ON entry_origin FOR EACH ROW BEGIN UPDATE oai_repos SET savedRecords = savedRecords + 1 WHERE oai_repos.id = NEW.repo_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`xpapers`@`localhost`*/ /*!50003 TRIGGER entry_origin_del BEFORE DELETE ON entry_origin FOR EACH ROW BEGIN UPDATE oai_repos SET savedRecords = savedRecords - 1 WHERE oai_repos.id = OLD.repo_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `errors`
--

DROP TABLE IF EXISTS `errors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `errors` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ip` varchar(15) DEFAULT NULL,
  `uId` int(11) DEFAULT NULL,
  `type` tinyint(3) unsigned DEFAULT NULL,
  `request_uri` varchar(1000) DEFAULT NULL,
  `args` text,
  `cookies` text,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `info` text,
  `user_agent` varchar(500) DEFAULT NULL,
  `host` varchar(255) DEFAULT NULL,
  `referer` varchar(500) DEFAULT NULL,
  `pid` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ip` (`ip`),
  KEY `uId` (`uId`),
  KEY `time` (`time`)
) ENGINE=MyISAM AUTO_INCREMENT=363178 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `feeds`
--

DROP TABLE IF EXISTS `feeds`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `feeds` (
  `id` int(14) unsigned NOT NULL AUTO_INCREMENT,
  `k` varchar(180) DEFAULT NULL,
  `url` varchar(1000) DEFAULT NULL,
  `lastChecked` datetime DEFAULT NULL,
  `uId` int(10) unsigned DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `lastIP` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `k` (`k`)
) ENGINE=MyISAM AUTO_INCREMENT=19080 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `follow_suggestions`
--

DROP TABLE IF EXISTS `follow_suggestions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `follow_suggestions` (
  `uId` int(11) NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL DEFAULT '',
  `rating` int(10) unsigned DEFAULT '0',
  PRIMARY KEY (`uId`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `followers`
--

DROP TABLE IF EXISTS `followers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `followers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uId` int(10) unsigned DEFAULT NULL,
  `original_name` varchar(128) DEFAULT NULL,
  `alias` varchar(128) DEFAULT NULL,
  `eId` varchar(11) DEFAULT NULL,
  `seen` tinyint(1) unsigned DEFAULT '0',
  `ok` tinyint(1) unsigned DEFAULT '0',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `facebook_id` bigint(20) DEFAULT NULL,
  `fuId` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uId_2` (`uId`,`original_name`,`alias`),
  KEY `uId` (`uId`),
  KEY `alias` (`alias`)
) ENGINE=MyISAM AUTO_INCREMENT=143678 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `forums`
--

DROP TABLE IF EXISTS `forums`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `forums` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `cId` int(10) unsigned DEFAULT NULL,
  `eId` varchar(11) DEFAULT NULL,
  `gId` int(10) unsigned DEFAULT NULL,
  `cacheId` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cat c` (`cId`),
  KEY `group c` (`gId`),
  CONSTRAINT `cat c` FOREIGN KEY (`cId`) REFERENCES `cats` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `group c` FOREIGN KEY (`gId`) REFERENCES `groups` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=188601 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `forums_m`
--

DROP TABLE IF EXISTS `forums_m`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `forums_m` (
  `fId` int(10) unsigned NOT NULL DEFAULT '0',
  `uId` int(11) NOT NULL,
  PRIMARY KEY (`fId`,`uId`),
  KEY `userk` (`uId`),
  CONSTRAINT `forum` FOREIGN KEY (`fId`) REFERENCES `forums` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `userk` FOREIGN KEY (`uId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fs_tmp`
--

DROP TABLE IF EXISTS `fs_tmp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fs_tmp` (
  `uId` int(11) NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL DEFAULT '',
  `rating` int(10) unsigned DEFAULT '0',
  PRIMARY KEY (`uId`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ftp_users`
--

DROP TABLE IF EXISTS `ftp_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ftp_users` (
  `userid` varchar(30) NOT NULL,
  `passwd` varchar(80) NOT NULL,
  `uid` int(11) DEFAULT '2001',
  `gid` int(11) DEFAULT '65534',
  `homedir` varchar(255) DEFAULT NULL,
  `shell` varchar(255) DEFAULT '/bin/bash',
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `last_scan_time` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `userid` (`userid`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `groups`
--

DROP TABLE IF EXISTS `groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `groups` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `owner` int(11) DEFAULT '0',
  `system` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `publish` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `created` datetime NOT NULL,
  `updated` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `description` varchar(200) NOT NULL,
  `permViewPapers` tinyint(3) unsigned DEFAULT '0',
  `permAddPapers` tinyint(3) unsigned DEFAULT '0',
  `permDeletePapers` tinyint(3) unsigned DEFAULT '40',
  `permViewPosts` tinyint(3) unsigned DEFAULT '0',
  `permAddPosts` tinyint(3) unsigned DEFAULT '0',
  `permDeletePosts` tinyint(3) unsigned DEFAULT '50',
  `permInvite` tinyint(3) unsigned DEFAULT '10',
  `permBan` tinyint(3) unsigned DEFAULT '30',
  `permJoin` tinyint(3) unsigned DEFAULT '1',
  `cId` int(10) unsigned DEFAULT NULL,
  `fId` int(10) unsigned DEFAULT NULL,
  `dId` int(11) DEFAULT NULL,
  `memberCount` int(10) unsigned DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `ownerk` (`owner`),
  CONSTRAINT `ownerk` FOREIGN KEY (`owner`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 PACK_KEYS=1 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `groups_m`
--

DROP TABLE IF EXISTS `groups_m`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `groups_m` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `gId` int(10) unsigned NOT NULL,
  `uId` int(11) NOT NULL,
  `level` tinyint(3) unsigned NOT NULL DEFAULT '10',
  PRIMARY KEY (`id`),
  UNIQUE KEY `gId` (`gId`,`uId`),
  KEY `member` (`uId`,`gId`),
  KEY `level` (`level`),
  CONSTRAINT `group` FOREIGN KEY (`gId`) REFERENCES `groups` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `user` FOREIGN KEY (`uId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1933 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `harvest_journals`
--

DROP TABLE IF EXISTS `harvest_journals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `harvest_journals` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `issn` varchar(16) DEFAULT NULL,
  `issn2` varchar(16) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `localName` varchar(255) DEFAULT NULL,
  `publisher` varchar(255) DEFAULT NULL,
  `subjects` text,
  `doi` varchar(255) DEFAULT NULL,
  `inCrossRef` tinyint(1) DEFAULT NULL,
  `lastFound` datetime DEFAULT NULL,
  `lastIssue` varchar(255) DEFAULT NULL,
  `deleted` char(1) DEFAULT '0',
  `toHarvest` tinyint(1) DEFAULT NULL,
  `oai_set` varchar(128) DEFAULT NULL,
  `lastSuccess` datetime DEFAULT NULL,
  `fetched` int(11) DEFAULT '0',
  `nonEng` int(11) DEFAULT '0',
  `newEntries` int(11) DEFAULT '0',
  `oldEntries` int(11) DEFAULT '0',
  `origin` char(1) DEFAULT NULL,
  `noTitle` int(11) DEFAULT '0',
  `suggestion` tinyint(1) unsigned DEFAULT '0',
  `lastFetched` int(11) DEFAULT '0',
  `lastNewEntries` int(11) DEFAULT '0',
  `lastFetchSuccess` datetime DEFAULT NULL,
  `lastPaper` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `issn` (`issn`),
  KEY `inCrossRef` (`inCrossRef`),
  KEY `name_2` (`name`),
  KEY `oai_set` (`oai_set`),
  FULLTEXT KEY `name` (`name`,`subjects`)
) ENGINE=MyISAM AUTO_INCREMENT=45074 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `input_feeds`
--

DROP TABLE IF EXISTS `input_feeds`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `input_feeds` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `lastStatus` varchar(20) DEFAULT NULL,
  `useSince` int(10) unsigned DEFAULT NULL,
  `harvested` varchar(40) DEFAULT NULL,
  `harvested_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `db_src` varchar(10) DEFAULT NULL,
  `pass` varchar(32) DEFAULT NULL,
  `type` varchar(16) DEFAULT 'journal',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=263 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `insts`
--

DROP TABLE IF EXISTS `insts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `insts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `domain` varchar(255) DEFAULT NULL,
  `phdName` varchar(6) DEFAULT 'PhD',
  `country` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=6060 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `insts_m`
--

DROP TABLE IF EXISTS `insts_m`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `insts_m` (
  `iId` int(11) NOT NULL DEFAULT '0',
  `uId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`iId`,`uId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `invites`
--

DROP TABLE IF EXISTS `invites`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `invites` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `gId` int(10) unsigned NOT NULL,
  `uId` int(10) unsigned NOT NULL,
  `status` varchar(16) NOT NULL DEFAULT 'no response',
  `key` varchar(100) NOT NULL,
  `rId` int(10) unsigned DEFAULT NULL,
  `rEmail` varchar(255) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`),
  KEY `send-receiv` (`uId`,`rEmail`,`gId`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lc_ranges`
--

DROP TABLE IF EXISTS `lc_ranges`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lc_ranges` (
  `lc_class` varchar(3) NOT NULL,
  `start` float unsigned DEFAULT NULL,
  `exclude` tinyint(2) unsigned DEFAULT '0',
  `description` varchar(255) DEFAULT NULL,
  `cId` int(10) unsigned DEFAULT NULL,
  `end` float unsigned DEFAULT NULL,
  `subrange` varchar(10) DEFAULT NULL,
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `xwords` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=27185 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `links`
--

DROP TABLE IF EXISTS `links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `links` (
  `url` varchar(950) CHARACTER SET latin1 NOT NULL DEFAULT '',
  `firstFailed` datetime DEFAULT NULL,
  `lastChecked` datetime DEFAULT NULL,
  `failures` int(4) unsigned DEFAULT '0',
  `safe` tinyint(1) unsigned DEFAULT '0',
  `dead` tinyint(1) unsigned DEFAULT '0',
  PRIMARY KEY (`url`),
  KEY `lastChecked` (`lastChecked`),
  KEY `failures` (`failures`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `links_m`
--

DROP TABLE IF EXISTS `links_m`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `links_m` (
  `url` varchar(950) CHARACTER SET latin1 DEFAULT NULL,
  `eId` varchar(13) DEFAULT NULL,
  UNIQUE KEY `url_2` (`url`,`eId`),
  KEY `url` (`url`),
  KEY `eId` (`eId`),
  KEY `url_3` (`url`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lists`
--

DROP TABLE IF EXISTS `lists`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lists` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `contentType` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `count` int(10) unsigned DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lists_c`
--

DROP TABLE IF EXISTS `lists_c`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lists_c` (
  `id` int(12) NOT NULL DEFAULT '0',
  `nb` bigint(21) NOT NULL DEFAULT '0'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lists_m`
--

DROP TABLE IF EXISTS `lists_m`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lists_m` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `oId` int(10) unsigned DEFAULT NULL,
  `lId` int(10) unsigned DEFAULT NULL,
  `rank` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `locks`
--

DROP TABLE IF EXISTS `locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `locks` (
  `id` varchar(64) NOT NULL DEFAULT '',
  `uId` int(10) unsigned DEFAULT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `log_6months`
--

DROP TABLE IF EXISTS `log_6months`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `log_6months` (
  `tracker` varchar(30) CHARACTER SET latin1 DEFAULT NULL,
  `action` varchar(10) CHARACTER SET latin1 DEFAULT NULL,
  `site` varchar(15) CHARACTER SET latin1 DEFAULT NULL,
  `host` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `time` datetime DEFAULT NULL,
  `x` varchar(255) CHARACTER SET latin1 DEFAULT '',
  `entryId` varchar(11) DEFAULT NULL,
  `catId` varchar(11) CHARACTER SET latin1 DEFAULT '',
  `name` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `email` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `referer` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `ip` varchar(16) CHARACTER SET latin1 DEFAULT '',
  `bot` tinyint(1) DEFAULT '0',
  `uId` int(10) unsigned DEFAULT NULL,
  `html` tinyint(1) unsigned DEFAULT '1',
  KEY `uId` (`uId`,`action`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `log_act`
--

DROP TABLE IF EXISTS `log_act`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `log_act` (
  `tracker` varchar(30) DEFAULT NULL,
  `action` varchar(10) DEFAULT NULL,
  `site` varchar(15) DEFAULT NULL,
  `host` varchar(255) DEFAULT NULL,
  `time` datetime DEFAULT NULL,
  `x` varchar(255) DEFAULT '',
  `entryId` varchar(11) CHARACTER SET utf8 DEFAULT NULL,
  `catId` varchar(11) DEFAULT '',
  `name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `referer` varchar(255) DEFAULT NULL,
  `ip` varchar(16) DEFAULT '',
  `bot` tinyint(1) DEFAULT '0',
  `uId` int(10) unsigned DEFAULT NULL,
  `html` tinyint(1) unsigned DEFAULT '1',
  KEY `tracker` (`tracker`),
  KEY `time` (`time`),
  KEY `entryId` (`entryId`),
  KEY `action` (`action`),
  KEY `site` (`site`),
  KEY `uId` (`uId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `log_recent`
--

DROP TABLE IF EXISTS `log_recent`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `log_recent` (
  `tracker` varchar(30) CHARACTER SET latin1 DEFAULT NULL,
  `action` varchar(10) CHARACTER SET latin1 DEFAULT NULL,
  `site` varchar(15) CHARACTER SET latin1 DEFAULT NULL,
  `host` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `time` datetime DEFAULT NULL,
  `x` varchar(255) CHARACTER SET latin1 DEFAULT '',
  `entryId` varchar(11) DEFAULT NULL,
  `catId` varchar(11) CHARACTER SET latin1 DEFAULT '',
  `name` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `email` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `referer` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `ip` varchar(16) CHARACTER SET latin1 DEFAULT '',
  `bot` tinyint(1) DEFAULT '0',
  `uId` int(10) unsigned DEFAULT NULL,
  `html` tinyint(1) unsigned DEFAULT '1',
  KEY `uId` (`uId`,`action`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `main`
--

DROP TABLE IF EXISTS `main`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `main` (
  `id` varchar(11) NOT NULL,
  `authors` varchar(1000) DEFAULT NULL,
  `ant_editors` varchar(1000) DEFAULT NULL,
  `links` varchar(5000) DEFAULT NULL,
  `PI_updated` varchar(32) DEFAULT NULL,
  `ant_date` varchar(16) DEFAULT NULL,
  `ant_publisher` varchar(255) DEFAULT NULL,
  `citations` float(14,0) DEFAULT NULL,
  `date` varchar(16) DEFAULT 'unknown',
  `descriptors` varchar(1000) DEFAULT NULL,
  `edited` tinyint(1) DEFAULT NULL,
  `etal` tinyint(1) DEFAULT NULL,
  `extra` varchar(1000) DEFAULT NULL,
  `issn` varchar(100) DEFAULT NULL,
  `issue` varchar(32) DEFAULT NULL,
  `notes` varchar(1000) DEFAULT NULL,
  `pages` varchar(32) DEFAULT NULL,
  `pub_type` varchar(32) CHARACTER SET latin1 DEFAULT NULL,
  `publisher` varchar(255) DEFAULT NULL,
  `replyto` varchar(255) DEFAULT NULL,
  `reprint` varchar(255) DEFAULT NULL,
  `school` varchar(255) DEFAULT NULL,
  `source` varchar(255) DEFAULT NULL,
  `title` varchar(1000) DEFAULT NULL,
  `type` varchar(16) DEFAULT NULL,
  `updated` datetime DEFAULT NULL,
  `volume` int(12) DEFAULT NULL,
  `db_src` varchar(10) CHARACTER SET latin1 DEFAULT 'user',
  `review` tinyint(1) DEFAULT '0',
  `source_id` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `author_abstract` text,
  `deleted` tinyint(1) DEFAULT '0',
  `defective` tinyint(1) DEFAULT '0',
  `source_subjects` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `online` tinyint(1) DEFAULT '0',
  `free` tinyint(1) DEFAULT '1',
  `published` tinyint(1) DEFAULT '0',
  `citationsLink` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `originalId` varchar(12) CHARACTER SET latin1 DEFAULT NULL,
  `duplicate` tinyint(1) DEFAULT '0',
  `_new` tinyint(1) DEFAULT NULL,
  `added` datetime DEFAULT NULL,
  `viewings` int(11) DEFAULT '0',
  `online_book` tinyint(1) DEFAULT '0',
  `sites` set('pp','mp','opc') CHARACTER SET latin1 DEFAULT NULL,
  `pubHarvest` tinyint(1) DEFAULT '0',
  `file` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `addToList` int(11) DEFAULT NULL,
  `postCount` int(10) unsigned DEFAULT '0',
  `fId` int(10) unsigned DEFAULT NULL,
  `draft` int(10) unsigned DEFAULT '0',
  `owner` int(10) unsigned DEFAULT NULL,
  `reviewed_title` varchar(500) DEFAULT NULL,
  `pro` tinyint(3) DEFAULT '0',
  `forcePro` tinyint(3) DEFAULT '0',
  `cn_class` varchar(3) DEFAULT NULL,
  `cn_num` float unsigned DEFAULT NULL,
  `cn_alpha` varchar(10) DEFAULT NULL,
  `cn_full` varchar(32) DEFAULT NULL,
  `isbn` varchar(300) DEFAULT NULL,
  `lccn` varchar(500) DEFAULT NULL,
  `dateRP` varchar(10) DEFAULT NULL,
  `book` varchar(11) DEFAULT NULL,
  `catCount` int(4) DEFAULT '0',
  `googleBooksQuery` varchar(500) DEFAULT NULL,
  `hasChapters` tinyint(1) unsigned DEFAULT '0',
  `flags` set('GS','GB','HIDE','GETPDF') DEFAULT '',
  `lang` char(3) DEFAULT 'eng',
  `duplicateOf` varchar(11) DEFAULT NULL,
  `serial` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `cacheId` int(10) unsigned DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `serial` (`serial`),
  KEY `id` (`id`),
  KEY `updated` (`updated`),
  KEY `added` (`added`),
  KEY `sites` (`sites`),
  KEY `source` (`source`),
  KEY `title` (`title`(333)),
  KEY `authors_4` (`authors`(255)),
  KEY `db_src` (`db_src`),
  KEY `date_idx` (`date`),
  KEY `deleted` (`deleted`),
  KEY `cn_class` (`cn_class`),
  KEY `cn_alpha` (`cn_alpha`),
  KEY `cn_num` (`cn_num`),
  KEY `call` (`cn_full`),
  KEY `lccn idx` (`lccn`(333)),
  KEY `source_id` (`source_id`),
  KEY `book` (`book`),
  FULLTEXT KEY `authors` (`authors`,`date`,`title`),
  FULLTEXT KEY `title_2` (`title`,`authors`,`notes`,`descriptors`,`source`,`author_abstract`),
  FULLTEXT KEY `authors_5` (`authors`),
  FULLTEXT KEY `authors_6` (`authors`,`title`),
  FULLTEXT KEY `title_3` (`title`),
  FULLTEXT KEY `authors_2` (`authors`,`title`,`descriptors`),
  FULLTEXT KEY `authors_3` (`authors`,`title`,`author_abstract`,`descriptors`)
) ENGINE=MyISAM AUTO_INCREMENT=419462 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`xpapers`@`localhost`*/ /*!50003 TRIGGER entry_del AFTER DELETE ON main FOR EACH ROW BEGIN DELETE FROM cats_me WHERE eId = OLD.id; DELETE FROM forums  WHERE eId = OLD.id; DELETE FROM links_m WHERE eId = OLD.id; DELETE FROM main_authors WHERE eId = OLD.id; DELETE FROM relations WHERE eId1 = OLD.id; DELETE FROM relations WHERE eId2 = OLD.id; DELETE FROM entry_origin WHERE eId = OLD.id; DELETE FROM diffs WHERE oId = OLD.id AND class = 'xPapers::Entry'; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `main_added`
--

DROP TABLE IF EXISTS `main_added`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `main_added` (
  `id` varchar(11) DEFAULT NULL,
  `source` enum('journals','local','archives','web','other') DEFAULT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `rank` int(4) DEFAULT NULL,
  `extra` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  KEY `source` (`source`),
  KEY `time` (`time`),
  KEY `id` (`id`),
  KEY `rank` (`rank`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `main_authors`
--

DROP TABLE IF EXISTS `main_authors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `main_authors` (
  `authId` int(20) NOT NULL DEFAULT '0',
  `name` varchar(255) DEFAULT NULL,
  `citations` float(14,0) DEFAULT '0',
  `eId` varchar(11) CHARACTER SET latin1 DEFAULT NULL,
  `good_journal` tinyint(4) DEFAULT '0',
  `firstname` varchar(100) DEFAULT NULL,
  `lastname` varchar(100) DEFAULT NULL,
  `year` varchar(16) DEFAULT NULL,
  `mereFirstname` varchar(50) DEFAULT NULL,
  KEY `name` (`name`),
  KEY `lastname` (`lastname`),
  KEY `firstname` (`firstname`),
  KEY `eId` (`eId`),
  KEY `lastname_2` (`lastname`,`mereFirstname`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `main_ids`
--

DROP TABLE IF EXISTS `main_ids`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `main_ids` (
  `id` varchar(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `main_jlists`
--

DROP TABLE IF EXISTS `main_jlists`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `main_jlists` (
  `jlId` int(11) NOT NULL AUTO_INCREMENT,
  `jlOwner` int(12) DEFAULT '0',
  `jlName` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`jlId`),
  KEY `jlOwner` (`jlOwner`)
) ENGINE=MyISAM AUTO_INCREMENT=2640 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `main_jlm`
--

DROP TABLE IF EXISTS `main_jlm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `main_jlm` (
  `jlmId` bigint(20) NOT NULL AUTO_INCREMENT,
  `jlId` int(12) DEFAULT NULL,
  `jId` int(12) DEFAULT NULL,
  PRIMARY KEY (`jlmId`),
  KEY `jlId` (`jlId`),
  KEY `jId` (`jId`)
) ENGINE=MyISAM AUTO_INCREMENT=305990 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `main_journals`
--

DROP TABLE IF EXISTS `main_journals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `main_journals` (
  `name` varchar(255) NOT NULL DEFAULT '',
  `browsable` tinyint(1) DEFAULT '1',
  `id` int(12) NOT NULL AUTO_INCREMENT,
  `maxVol` varchar(255) DEFAULT NULL,
  `nb` int(11) DEFAULT NULL,
  `minVol` varchar(255) DEFAULT NULL,
  `nbHarvest` int(11) DEFAULT NULL,
  `nbVol` int(11) DEFAULT NULL,
  `latestVolume` int(11) DEFAULT NULL,
  `showIssues` tinyint(1) DEFAULT '0',
  `archive` tinyint(1) DEFAULT '0',
  `cId` int(10) unsigned DEFAULT NULL,
  `hide` tinyint(1) unsigned DEFAULT '0',
  `listCount` int(10) unsigned DEFAULT '0',
  PRIMARY KEY (`name`),
  UNIQUE KEY `id_2` (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=3231 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `metaerror`
--

DROP TABLE IF EXISTS `metaerror`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `metaerror` (
  `poId` int(10) unsigned DEFAULT NULL,
  `uId` int(11) DEFAULT NULL,
  `qId` int(10) unsigned DEFAULT NULL,
  `opt` varchar(255) DEFAULT NULL,
  `error` float DEFAULT NULL,
  `oqId` int(10) unsigned DEFAULT NULL,
  `estimate` int(10) unsigned DEFAULT NULL,
  `actual` float DEFAULT NULL,
  `n_estimate` float DEFAULT NULL,
  `n_actual` float DEFAULT NULL,
  `own` tinyint(1) unsigned DEFAULT NULL,
  KEY `oqId` (`oqId`),
  KEY `qId` (`qId`),
  KEY `opt` (`opt`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notes`
--

DROP TABLE IF EXISTS `notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uId` int(11) DEFAULT NULL,
  `eId` varchar(10) DEFAULT NULL,
  `body` text,
  `created` datetime DEFAULT NULL,
  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FULLTEXT KEY `body` (`body`)
) ENGINE=MyISAM AUTO_INCREMENT=49 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notices`
--

DROP TABLE IF EXISTS `notices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notices` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uId` int(10) unsigned DEFAULT NULL,
  `email` varchar(255) NOT NULL,
  `brief` varchar(255) DEFAULT NULL,
  `content` text,
  `sent` tinyint(4) NOT NULL DEFAULT '0',
  `created` datetime NOT NULL,
  `sent_time` datetime DEFAULT NULL,
  `isHTML` tinyint(1) unsigned DEFAULT '0',
  `failed` tinyint(1) unsigned DEFAULT '0',
  `failures` int(5) unsigned DEFAULT '0',
  `replyTo` int(10) unsigned DEFAULT NULL,
  `sender` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sent` (`sent`),
  KEY `created` (`created`)
) ENGINE=InnoDB AUTO_INCREMENT=1174818 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `oai_repos`
--

DROP TABLE IF EXISTS `oai_repos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `oai_repos` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `rid` varchar(32) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `handler` varchar(255) DEFAULT NULL,
  `deleted` tinyint(1) unsigned DEFAULT '0',
  `useSubjectFilter` varchar(32) DEFAULT NULL,
  `sets` text,
  `found` int(10) unsigned DEFAULT '0',
  `scannedAt` datetime DEFAULT NULL,
  `errorLog` text,
  `fetchedRecords` int(11) DEFAULT NULL,
  `savedRecords` int(11) DEFAULT NULL,
  `downloadType` varchar(32) DEFAULT NULL,
  `nonEngRecords` int(11) DEFAULT NULL,
  `languages` text,
  `lastSuccess` datetime DEFAULT NULL,
  `isSlow` tinyint(1) DEFAULT NULL,
  `lastHarvestDuration` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2131 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `old_notices`
--

DROP TABLE IF EXISTS `old_notices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `old_notices` (
  `id` int(10) unsigned NOT NULL,
  `uId` int(10) unsigned DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `brief` varchar(255) DEFAULT NULL,
  `content` text,
  `sent` tinyint(4) DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `sent_time` datetime DEFAULT NULL,
  `isHTML` tinyint(1) unsigned DEFAULT NULL,
  `failed` tinyint(1) unsigned DEFAULT NULL,
  `failures` int(5) unsigned DEFAULT NULL,
  `replyTo` int(10) unsigned DEFAULT NULL,
  `sender` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `old_url_names`
--

DROP TABLE IF EXISTS `old_url_names`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `old_url_names` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cId` int(11) DEFAULT NULL,
  `uName` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `uName` (`uName`)
) ENGINE=MyISAM AUTO_INCREMENT=34 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `pagearea_m`
--

DROP TABLE IF EXISTS `pagearea_m`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pagearea_m` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pageauthor_id` int(11) NOT NULL,
  `area_id` int(8) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `map` (`pageauthor_id`,`area_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2256 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `pageauthors`
--

DROP TABLE IF EXISTS `pageauthors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pageauthors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lastname` varchar(255) DEFAULT NULL,
  `firstname` varchar(255) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `people_cat` varchar(128) DEFAULT NULL,
  `people_descr` text,
  `pro` tinyint(4) DEFAULT '0',
  `opp_id` int(11) DEFAULT NULL,
  `accepted` tinyint(4) DEFAULT NULL,
  `deleted` tinyint(4) DEFAULT '0',
  `created` datetime DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2010 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `pages`
--

DROP TABLE IF EXISTS `pages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` varchar(255) NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `author_id` int(11) NOT NULL,
  `accepted` tinyint(4) DEFAULT NULL,
  `deleted` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2309 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `paper_areas`
--

DROP TABLE IF EXISTS `paper_areas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `paper_areas` (
  `eId` varchar(11) NOT NULL,
  `cId` int(10) unsigned NOT NULL DEFAULT '0',
  KEY `eId` (`eId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `papers_read`
--

DROP TABLE IF EXISTS `papers_read`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `papers_read` (
  `id` varchar(11) NOT NULL,
  `source` varchar(255) DEFAULT NULL,
  `nb` bigint(21) NOT NULL DEFAULT '0',
  KEY `id` (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `past_userworks`
--

DROP TABLE IF EXISTS `past_userworks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `past_userworks` (
  `uId` int(10) unsigned NOT NULL DEFAULT '0',
  `eId` varchar(11) NOT NULL DEFAULT '',
  `good_journal` tinyint(1) DEFAULT '0'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `plugin_tests`
--

DROP TABLE IF EXISTS `plugin_tests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `plugin_tests` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `url` varchar(500) DEFAULT NULL,
  `plugin` varchar(128) DEFAULT NULL,
  `expected` text,
  `last` text,
  `created` datetime DEFAULT NULL,
  `lastChecked` datetime DEFAULT NULL,
  `lastStatus` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=13 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `poll_depts`
--

DROP TABLE IF EXISTS `poll_depts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `poll_depts` (
  `iId` int(10) unsigned DEFAULT NULL,
  `poId` int(10) unsigned DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `poll_guests`
--

DROP TABLE IF EXISTS `poll_guests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `poll_guests` (
  `uId` int(11) NOT NULL DEFAULT '0',
  `iId` int(10) unsigned DEFAULT NULL,
  `invites` int(10) unsigned DEFAULT '0',
  `isOut` tinyint(1) unsigned DEFAULT '0',
  PRIMARY KEY (`uId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `poll_opts`
--

DROP TABLE IF EXISTS `poll_opts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `poll_opts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uId` int(11) DEFAULT NULL,
  `poId` int(10) unsigned DEFAULT NULL,
  `again` tinyint(1) unsigned DEFAULT '1',
  `comment` text,
  `sug_questions` text,
  `sug_analysis` text,
  `step` int(10) unsigned DEFAULT '0',
  `aos` varchar(1000) DEFAULT NULL,
  `aoi` varchar(1000) DEFAULT NULL,
  `tradition` varchar(255) DEFAULT NULL,
  `xian` varchar(255) DEFAULT NULL,
  `affils` varchar(1000) DEFAULT NULL,
  `yob` int(10) unsigned DEFAULT NULL,
  `nationality` varchar(2) DEFAULT NULL,
  `gender` varchar(1) DEFAULT NULL,
  `phd` int(10) unsigned DEFAULT NULL,
  `publish` tinyint(1) unsigned DEFAULT '0',
  `flags` set('name','background','affils','research') DEFAULT '',
  `answered` int(10) unsigned DEFAULT '0',
  `series` varchar(1000) DEFAULT NULL,
  `isout` tinyint(1) unsigned DEFAULT '0',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `invited` tinyint(1) unsigned DEFAULT '0',
  `ip` varchar(32) DEFAULT NULL,
  `signed` tinyint(1) unsigned DEFAULT '0',
  `emailStep` int(10) unsigned DEFAULT '0',
  `firstQuestion` datetime DEFAULT NULL,
  `lastEmail` datetime DEFAULT NULL,
  `noEmails` tinyint(1) unsigned DEFAULT '0',
  `completed` datetime DEFAULT NULL,
  `emailFailed` tinyint(1) unsigned DEFAULT '0',
  `bounceMsg` varchar(255) DEFAULT NULL,
  `givenUp` tinyint(1) unsigned DEFAULT '0',
  `invitedMeta` tinyint(1) unsigned DEFAULT '0',
  `invitedUser` tinyint(1) unsigned DEFAULT '0',
  `sameIP` int(10) unsigned DEFAULT '0',
  `affilCountry` varchar(2) DEFAULT NULL,
  `followEmailStep` int(10) unsigned DEFAULT '0',
  `nationality_region` varchar(100) DEFAULT NULL,
  `affil_region` varchar(50) DEFAULT NULL,
  `phd_region` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `poId` (`poId`,`uId`),
  KEY `completed` (`completed`),
  KEY `step` (`step`),
  KEY `lastEmail` (`lastEmail`),
  KEY `invitedUser` (`invitedUser`),
  KEY `invited` (`invited`),
  KEY `phd_region` (`phd_region`),
  KEY `nationality_region` (`nationality_region`),
  KEY `affil_region` (`affil_region`)
) ENGINE=InnoDB AUTO_INCREMENT=30234 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `polls`
--

DROP TABLE IF EXISTS `polls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `polls` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `description` text,
  `owner` int(11) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `open` datetime DEFAULT NULL,
  `close` datetime DEFAULT NULL,
  `guestListId` int(10) unsigned DEFAULT NULL,
  `cId` int(10) unsigned DEFAULT NULL,
  `randomize` tinyint(1) unsigned DEFAULT '0',
  `rolling` tinyint(1) unsigned DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `polls_m`
--

DROP TABLE IF EXISTS `polls_m`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `polls_m` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `poId` int(10) unsigned DEFAULT NULL,
  `qId` int(10) unsigned DEFAULT NULL,
  `rank` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `posts`
--

DROP TABLE IF EXISTS `posts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `posts` (
  `id` int(32) NOT NULL AUTO_INCREMENT,
  `uId` int(11) NOT NULL,
  `tId` int(10) unsigned DEFAULT NULL,
  `subject` varchar(255) DEFAULT NULL,
  `body` text,
  `created` datetime DEFAULT NULL,
  `target` int(32) DEFAULT NULL,
  `notified` tinyint(4) DEFAULT '0',
  `notifiedMode` set('instant','daily','weekly') DEFAULT '',
  `accepted` tinyint(1) unsigned DEFAULT '0',
  `fId` int(10) unsigned DEFAULT NULL,
  `subscribePoster` tinyint(1) unsigned DEFAULT '0',
  `private` tinyint(3) unsigned DEFAULT '0',
  `submitted` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `thread c` (`tId`),
  KEY `target c` (`target`),
  KEY `notified` (`notified`),
  KEY `author` (`uId`),
  KEY `accepted` (`accepted`),
  KEY `submitted` (`submitted`),
  FULLTEXT KEY `subject` (`subject`)
) ENGINE=MyISAM AUTO_INCREMENT=5640 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `primary_ancestors`
--

DROP TABLE IF EXISTS `primary_ancestors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `primary_ancestors` (
  `aId` int(10) unsigned NOT NULL DEFAULT '0',
  `cId` int(10) unsigned NOT NULL DEFAULT '0',
  `distance` int(10) unsigned DEFAULT NULL,
  `id` int(14) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `aId_2` (`aId`,`cId`),
  KEY `aId` (`aId`),
  KEY `cId` (`cId`),
  KEY `id` (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=1394036 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `props`
--

DROP TABLE IF EXISTS `props`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `props` (
  `name` varchar(255) NOT NULL DEFAULT '',
  `value` text,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `queries`
--

DROP TABLE IF EXISTS `queries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `queries` (
  `id` int(15) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `mode` varchar(20) DEFAULT NULL,
  `searchStr` text,
  `minYear` int(11) DEFAULT NULL,
  `minRelevance` float DEFAULT NULL,
  `owner` int(11) NOT NULL,
  `inter` int(11) DEFAULT NULL,
  `freeOnly` varchar(5) DEFAULT NULL,
  `publishedOnly` varchar(5) DEFAULT NULL,
  `filterMode` varchar(20) DEFAULT NULL,
  `executed` datetime DEFAULT NULL,
  `w_a` text,
  `w_e` text,
  `w_g` text,
  `w_p` text,
  `w_n` text,
  `interval` int(10) unsigned DEFAULT '0',
  `examplar` tinyint(1) DEFAULT '0',
  `system` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `draftsOnly` tinyint(3) unsigned DEFAULT '0',
  `w_ez` text,
  `advMode` varchar(10) DEFAULT 'advanced',
  `w_ezn` text,
  `w_ezn2` text,
  `appendMSets` tinyint(1) unsigned DEFAULT '1',
  `trawler` int(10) unsigned DEFAULT '0',
  `proOnly` varchar(5) DEFAULT NULL,
  `maxYear` int(11) DEFAULT NULL,
  `authors` varchar(255) DEFAULT NULL,
  `all` varchar(255) DEFAULT NULL,
  `exact` varchar(255) DEFAULT NULL,
  `without` varchar(255) DEFAULT NULL,
  `atleast` varchar(255) DEFAULT NULL,
  `extended` varchar(1000) DEFAULT NULL,
  `onlineOnly` varchar(5) DEFAULT NULL,
  `publication` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `name` (`name`),
  KEY `owner` (`owner`),
  KEY `examplar` (`examplar`),
  CONSTRAINT `owner` FOREIGN KEY (`owner`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10354 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `questions`
--

DROP TABLE IF EXISTS `questions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `questions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `poId` int(10) unsigned DEFAULT NULL,
  `type` enum('position','yesno','dichotomy','multichoice','open') DEFAULT NULL,
  `question` varchar(1000) DEFAULT NULL,
  `options` varchar(1000) DEFAULT NULL,
  `prototype` int(10) unsigned DEFAULT NULL,
  `rank` int(10) unsigned DEFAULT '0',
  `optional` tinyint(1) unsigned DEFAULT '0',
  `showOtherOptions` tinyint(1) unsigned DEFAULT '1',
  `cachebin` blob,
  `metaOf` int(10) unsigned DEFAULT NULL,
  `cacheId` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `poId` (`poId`)
) ENGINE=InnoDB AUTO_INCREMENT=705 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `relations`
--

DROP TABLE IF EXISTS `relations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `relations` (
  `type` varchar(20) DEFAULT NULL,
  `eId1` varchar(11) DEFAULT NULL,
  `eId2` varchar(11) DEFAULT NULL,
  KEY `type` (`type`,`eId1`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `requests`
--

DROP TABLE IF EXISTS `requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `requests` (
  `uri` varchar(500) NOT NULL,
  `time` datetime DEFAULT NULL,
  `counter` bigint(20) DEFAULT '1',
  `ip` varchar(16) NOT NULL DEFAULT '',
  PRIMARY KEY (`ip`,`uri`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `resolvers`
--

DROP TABLE IF EXISTS `resolvers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `resolvers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `url` varchar(255) DEFAULT NULL,
  `weight` float DEFAULT NULL,
  `iId` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `url` (`url`),
  KEY `inst_id` (`iId`)
) ENGINE=MyISAM AUTO_INCREMENT=2448 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `review_relation`
--

DROP TABLE IF EXISTS `review_relation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `review_relation` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `reviewer_id` varchar(11) DEFAULT NULL,
  `reviewed_id` varchar(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=55 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sphinx_forums`
--

DROP TABLE IF EXISTS `sphinx_forums`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sphinx_forums` (
  `id` int(10) unsigned NOT NULL,
  `weight` int(11) NOT NULL,
  `query` varchar(3072) NOT NULL,
  `_sph_count` int(10) unsigned DEFAULT NULL,
  `_sph_groupby` int(10) unsigned DEFAULT NULL,
  KEY `query` (`query`)
) ENGINE=SPHINX DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sphinx_main`
--

DROP TABLE IF EXISTS `sphinx_main`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sphinx_main` (
  `id` int(10) unsigned NOT NULL,
  `weight` int(11) NOT NULL,
  `query` varchar(3072) NOT NULL,
  `true_id` varchar(15) DEFAULT NULL,
  `_sph_count` int(10) unsigned DEFAULT NULL,
  `_sph_groupby` int(10) unsigned DEFAULT NULL,
  KEY `query` (`query`)
) ENGINE=SPHINX DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `survey_props`
--

DROP TABLE IF EXISTS `survey_props`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `survey_props` (
  `uId` int(11) NOT NULL DEFAULT '0',
  `prop` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`uId`,`prop`),
  KEY `uId` (`uId`),
  KEY `prop` (`prop`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `survey_props_current`
--

DROP TABLE IF EXISTS `survey_props_current`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `survey_props_current` (
  `uId` int(11) NOT NULL DEFAULT '0',
  `prop` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`uId`,`prop`),
  KEY `uId` (`uId`),
  KEY `prop` (`prop`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `test_replication`
--

DROP TABLE IF EXISTS `test_replication`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `test_replication` (
  `dummy` tinyint(1) unsigned DEFAULT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `threads`
--

DROP TABLE IF EXISTS `threads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `threads` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `firstPostId` int(10) unsigned DEFAULT NULL,
  `latestPostId` int(10) unsigned DEFAULT NULL,
  `postCount` int(11) DEFAULT NULL,
  `latestPostTime` datetime DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `fId` int(10) unsigned NOT NULL,
  `sticky` tinyint(1) unsigned DEFAULT '0',
  `accepted` tinyint(1) unsigned DEFAULT '1',
  `blog` tinyint(1) unsigned DEFAULT '0',
  `private` tinyint(3) unsigned DEFAULT '0',
  `noReplies` tinyint(1) unsigned DEFAULT '0',
  `cacheId` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `forum c` (`fId`),
  KEY `latest` (`latestPostTime`),
  KEY `count` (`postCount`),
  KEY `sticky` (`sticky`),
  KEY `accepted` (`accepted`),
  KEY `blog` (`blog`),
  CONSTRAINT `forum c` FOREIGN KEY (`fId`) REFERENCES `forums` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=652 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `threads_m`
--

DROP TABLE IF EXISTS `threads_m`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `threads_m` (
  `tId` int(10) unsigned NOT NULL,
  `uId` int(11) NOT NULL,
  PRIMARY KEY (`tId`,`uId`),
  KEY `usersk` (`uId`),
  CONSTRAINT `thread` FOREIGN KEY (`tId`) REFERENCES `threads` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `usersk` FOREIGN KEY (`uId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tmp_pro_entries`
--

DROP TABLE IF EXISTS `tmp_pro_entries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tmp_pro_entries` (
  `eId` varchar(11) NOT NULL,
  `current` tinyint(1) unsigned DEFAULT NULL,
  `new` tinyint(1) unsigned DEFAULT NULL,
  PRIMARY KEY (`eId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tmp_pro_names`
--

DROP TABLE IF EXISTS `tmp_pro_names`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tmp_pro_names` (
  `mereFirstname` varchar(50) DEFAULT NULL,
  `lastname` varchar(100) DEFAULT NULL,
  KEY `lastname` (`lastname`,`mereFirstname`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tmp_pro_users`
--

DROP TABLE IF EXISTS `tmp_pro_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tmp_pro_users` (
  `uId` int(10) unsigned NOT NULL,
  `current` tinyint(1) unsigned DEFAULT NULL,
  `new` tinyint(1) unsigned DEFAULT NULL,
  `lastname` varchar(255) DEFAULT NULL,
  `fixedPro` tinyint(1) unsigned DEFAULT NULL,
  `phd` int(10) unsigned DEFAULT NULL,
  `myworks` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`uId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tmp_proworks`
--

DROP TABLE IF EXISTS `tmp_proworks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tmp_proworks` (
  `eId` varchar(11) NOT NULL,
  PRIMARY KEY (`eId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tmp_repos_count`
--

DROP TABLE IF EXISTS `tmp_repos_count`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tmp_repos_count` (
  `id` int(11) DEFAULT NULL,
  `nb` bigint(21) NOT NULL DEFAULT '0'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tmp_userareas`
--

DROP TABLE IF EXISTS `tmp_userareas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tmp_userareas` (
  `id` int(11) NOT NULL DEFAULT '0',
  `areas` longblob
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tmpcount`
--

DROP TABLE IF EXISTS `tmpcount`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tmpcount` (
  `nb` bigint(21) NOT NULL DEFAULT '0',
  `eId` varchar(11) NOT NULL DEFAULT ''
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `to_delete`
--

DROP TABLE IF EXISTS `to_delete`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `to_delete` (
  `id` varchar(11) NOT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `unparsed`
--

DROP TABLE IF EXISTS `unparsed`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `unparsed` (
  `content` varchar(1000) DEFAULT NULL,
  UNIQUE KEY `content` (`content`(300))
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lastname` varchar(128) DEFAULT NULL,
  `firstname` varchar(128) DEFAULT NULL,
  `initials` varchar(10) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `lastLogin` datetime DEFAULT NULL,
  `failedAttempts` int(11) DEFAULT '0',
  `passwd` varchar(255) DEFAULT NULL,
  `confirmed` tinyint(1) DEFAULT '0',
  `confToken` varchar(255) DEFAULT NULL,
  `tz` varchar(50) DEFAULT NULL,
  `proxy` varchar(255) DEFAULT NULL,
  `readingList` int(11) DEFAULT NULL,
  `pk` varchar(16) DEFAULT NULL,
  `publish` tinyint(1) DEFAULT '0',
  `blocked` tinyint(4) DEFAULT '0',
  `mybib` int(11) DEFAULT NULL,
  `alert` tinyint(1) DEFAULT '1',
  `blurb` text,
  `myworks` int(10) unsigned DEFAULT NULL,
  `homePage` varchar(500) DEFAULT NULL,
  `hide` tinyint(4) DEFAULT '0',
  `addToGroup` int(10) unsigned DEFAULT NULL,
  `phd` int(12) unsigned DEFAULT NULL,
  `pro` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `fixedPro` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `postQuota` int(10) unsigned DEFAULT '2',
  `lastIp` varchar(15) DEFAULT NULL,
  `showEmail` tinyint(3) unsigned DEFAULT '0',
  `noticeMode` varchar(10) DEFAULT 'instant',
  `alertFreq` int(8) unsigned DEFAULT '7',
  `alertChecked` datetime DEFAULT '0000-00-00 00:00:00',
  `alertJournals` tinyint(1) unsigned DEFAULT '1',
  `alertAreas` tinyint(1) unsigned DEFAULT '1',
  `nbEdit` int(10) unsigned DEFAULT NULL,
  `nbSubmit` int(10) unsigned DEFAULT NULL,
  `nbCatAdd` int(10) unsigned DEFAULT NULL,
  `nbCatDelete` int(10) unsigned DEFAULT NULL,
  `subAreas` tinyint(1) unsigned DEFAULT '1',
  `newNoticeMode` varchar(15) DEFAULT NULL,
  `flags` set('PROXY','AUTO','BANNED','DISABLED','NOFOLLOWERS') DEFAULT NULL,
  `pubRating` int(10) unsigned DEFAULT '0',
  `nbAct` int(10) unsigned DEFAULT '0',
  `nbEditL` int(10) unsigned DEFAULT NULL,
  `nbCatL` int(10) unsigned DEFAULT NULL,
  `pubRatingW` int(10) unsigned DEFAULT '0',
  `xId` int(10) unsigned DEFAULT NULL,
  `admin` tinyint(1) unsigned DEFAULT '0',
  `mereFirstname` varchar(100) DEFAULT NULL,
  `mysources` int(10) unsigned DEFAULT NULL,
  `cacheId` int(10) unsigned DEFAULT NULL,
  `rId` int(10) unsigned DEFAULT NULL,
  `locale` varchar(2) DEFAULT NULL,
  `anonymousFollowing` tinyint(1) DEFAULT NULL,
  `alertFollowed` tinyint(1) DEFAULT NULL,
  `betaTester` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `lastname` (`lastname`),
  KEY `firstname` (`firstname`),
  KEY `nbAct` (`nbAct`),
  KEY `pubRating` (`pubRating`)
) ENGINE=InnoDB AUTO_INCREMENT=23535 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `usersx`
--

DROP TABLE IF EXISTS `usersx`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `usersx` (
  `uId` int(11) NOT NULL,
  `yob` int(10) unsigned DEFAULT NULL,
  `gender` enum('M','F') DEFAULT NULL,
  `nationality` varchar(3) DEFAULT NULL,
  `tradition` varchar(100) DEFAULT NULL,
  `pollKey` varchar(50) DEFAULT NULL,
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `xian` varchar(255) DEFAULT NULL,
  `futurePasswd` varchar(255) DEFAULT NULL,
  `asKey` varchar(32) DEFAULT NULL,
  `publishView` tinyint(1) unsigned DEFAULT '0',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `uIdidx` (`uId`)
) ENGINE=MyISAM AUTO_INCREMENT=23523 DEFAULT CHARSET=utf8 COMMENT='extended information on users';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `userworks`
--

DROP TABLE IF EXISTS `userworks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `userworks` (
  `uId` int(10) unsigned NOT NULL DEFAULT '0',
  `eId` varchar(11) NOT NULL DEFAULT '',
  `good_journal` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`uId`,`eId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `viewings`
--

DROP TABLE IF EXISTS `viewings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `viewings` (
  `ip` varchar(16) CHARACTER SET latin1 DEFAULT '',
  `date` date DEFAULT NULL,
  `entryId` varchar(11) DEFAULT NULL,
  KEY `entryId` (`entryId`),
  KEY `date` (`date`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `viewings_c`
--

DROP TABLE IF EXISTS `viewings_c`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `viewings_c` (
  `entryId` varchar(11) DEFAULT NULL,
  `nb` bigint(21) NOT NULL DEFAULT '0',
  KEY `entryId` (`entryId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `volume_index`
--

DROP TABLE IF EXISTS `volume_index`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `volume_index` (
  `source` varchar(255) DEFAULT NULL,
  `volume` int(12) DEFAULT NULL,
  KEY `source` (`source`),
  KEY `volume` (`volume`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `year_index`
--

DROP TABLE IF EXISTS `year_index`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `year_index` (
  `source` varchar(255) DEFAULT NULL,
  `year` varchar(16) DEFAULT 'unknown',
  KEY `source` (`source`),
  KEY `year` (`year`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `z3950_prefixes`
--

DROP TABLE IF EXISTS `z3950_prefixes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `z3950_prefixes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `prefix` varchar(16) DEFAULT NULL,
  `lastSuccess` datetime DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=311 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2011-03-28 12:12:13
