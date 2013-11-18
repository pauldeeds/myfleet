DROP TABLE IF EXISTS addr;
DROP TABLE IF EXISTS boats;
DROP TABLE IF EXISTS dues_paid;
DROP TABLE IF EXISTS email;
DROP TABLE IF EXISTS forum;
DROP TABLE IF EXISTS gallery;
DROP TABLE IF EXISTS photo;
DROP TABLE IF EXISTS html;
DROP TABLE IF EXISTS msg;
DROP TABLE IF EXISTS name;
DROP TABLE IF EXISTS person;
DROP TABLE IF EXISTS crew;
DROP TABLE IF EXISTS photo2;
DROP TABLE IF EXISTS regatta;
DROP TABLE IF EXISTS session;
DROP TABLE IF EXISTS thread;
DROP TABLE IF EXISTS title;
DROP TABLE IF EXISTS txt;
DROP TABLE IF EXISTS venue;
DROP TABLE IF EXISTS gps;

CREATE TABLE gps (
  gps_id int(11) NOT NULL auto_increment,
  regattaid INT(11) NOT NULL,
  start_time datetime NOT NULL DEFAULT 0,
  end_time datetime NOT NULL DEFAULT 0,
  day date NOT NULL,
  filename varchar(250) NOT NULL default '',
  boat varchar(50) NOT NULL default '',
  description varchar(500) NOT NULL DEFAULT '',
  upload_date DATETIME NOT NULL,
  PRIMARY KEY (gps_id),
  KEY (regattaid)
) TYPE=MyISAM;

CREATE TABLE addr (
  addr_id int(11) NOT NULL auto_increment,
  addr varchar(255) default NULL,
  PRIMARY KEY  (addr_id),
  KEY addr (addr)
) TYPE=MyISAM;


# patch
# ALTER TABLE boats MODIFY sailnumber mediumint not null default 0;

CREATE TABLE boats (
  regattaid int(12) NOT NULL default '0',
  sailnumber mediumint(5) NOT NULL default '0',
  skipper varchar(80) NOT NULL default '',
  crew varchar(80) NOT NULL default '',
  note text,
  status enum('Sailing','Available','Looking') NOT NULL default 'Sailing',
  lastupdate timestamp(14) NOT NULL,
  KEY regattaid (regattaid),
  KEY status (status),
  KEY sailnumber (sailnumber),
  KEY lastupdate (lastupdate)
) TYPE=MyISAM;

CREATE TABLE dues_paid (
  year int(10) unsigned NOT NULL default '0',
  hullnumber int(10) unsigned NOT NULL default '0',
  dues1 tinyint(3) unsigned NOT NULL default '0',
  dues2 tinyint(3) unsigned NOT NULL default '0',
  dues3 tinyint(3) unsigned NOT NULL default '0',
  dues4 tinyint(3) unsigned NOT NULL default '0',
  name varchar(200) NOT NULL default '',
  note text,
  modification_date timestamp(14) NOT NULL,
  PRIMARY KEY  (year,hullnumber)
) TYPE=MyISAM;

CREATE TABLE email (
  email_id int(11) NOT NULL auto_increment,
  email varchar(80) NOT NULL default '',
  modification_date timestamp(14) NOT NULL,
  PRIMARY KEY  (email_id),
  KEY email (email)
) TYPE=MyISAM;

CREATE TABLE forum (
  forum_id int(11) NOT NULL auto_increment,
  name varchar(30) NOT NULL default '',
  modification_date timestamp(14) NOT NULL,
  PRIMARY KEY  (forum_id),
  KEY modification_date (modification_date)
) TYPE=MyISAM;

INSERT INTO forum VALUES (1,'Messages',20030321144926);
INSERT INTO forum VALUES (2,'For Sale',20030321144926);

CREATE TABLE gallery (
  id int(16) NOT NULL auto_increment,
  name varchar(40) NOT NULL default '',
  description text,
  hide tinyint(1) NOT NULL default '0',
  KEY id (id)
) TYPE=MyISAM;

INSERT INTO gallery VALUES (1,'Best Shots',NULL,0);

CREATE TABLE photo (
  id int(16) NOT NULL auto_increment,
  width int(16) NOT NULL default '0',
  height int(16) NOT NULL default '0',
  caption varchar(80) NOT NULL default '',
  gallery_id int(16) NOT NULL default '0',
  thumb_width int(16) NOT NULL default '0',
  thumb_height int(16) NOT NULL default '0',
  hide tinyint(4) NOT NULL default '0',
  filename varchar(250) NOT NULL default '',
  KEY id (id),
  KEY gallery_id (gallery_id)
) TYPE=MyISAM;

CREATE TABLE html (
  id int(12) NOT NULL auto_increment,
  uniquename varchar(32) NOT NULL default '',
  title varchar(64) NOT NULL default '',
  html text,
  lastupdate timestamp(14) NOT NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY uniquename (uniquename)
) TYPE=MyISAM;

CREATE TABLE msg (
  msg_id int(11) NOT NULL auto_increment,
  reply_to int(11) NOT NULL default '0',
  name_id int(11) NOT NULL default '0',
  email_id int(11) NOT NULL default '0',
  txt_id int(11) NOT NULL default '0',
  addr_id int(11) NOT NULL default '0',
  title_id int(11) NOT NULL default '0',
  session_id int(11) NOT NULL default '0',
  thread_id int(11) NOT NULL default '0',
  nomessage tinyint(1) NOT NULL default '0',
  views smallint(6) NOT NULL default '0',
  good smallint(6) NOT NULL default '0',
  bad smallint(6) NOT NULL default '0',
  deleted tinyint(1) NOT NULL default 0,
  password varchar(30) NOT NULL default '',
  insert_date datetime NOT NULL default '0000-00-00 00:00:00',
  modification_date timestamp(14) NOT NULL,
  PRIMARY KEY  (msg_id),
  KEY reply_to (reply_to),
  KEY name_id (name_id),
  KEY email_id (email_id),
  KEY txt_id (txt_id),
  KEY title_id (title_id),
  KEY insert_date (insert_date)
) TYPE=MyISAM;

CREATE TABLE name (
  name_id int(11) NOT NULL auto_increment,
  name varchar(80) NOT NULL default '',
  modification_date timestamp(14) NOT NULL,
  PRIMARY KEY  (name_id),
  FULLTEXT ftname (name),
  KEY name (name)
) TYPE=MyISAM;

CREATE TABLE person (
  id smallint(6) NOT NULL auto_increment,
  firstname varchar(32) NOT NULL default '',
  lastname varchar(48) NOT NULL default '',
  street varchar(64) NOT NULL default '',
  city varchar(32) NOT NULL default '',
  state char(2) NOT NULL default '',
  zip varchar(10) default NULL,
  phone varchar(20) NOT NULL default '',
  email varchar(100) NOT NULL default '',
  url varchar(128) NOT NULL default '',
  type enum('Owner','Crew','Other') default 'Other',
  hullnumber smallint(5) default NULL,
  special varchar(64) NOT NULL default '',
  specialorder smallint(6) NOT NULL default 0,
  note VARCHAR(500) NOT NULL default '',
  boatname varchar(64) NOT NULL default '',
  sailnumber varchar(8) NOT NULL default '',
  password varchar(16) NOT NULL default '',
  photo_id int(16) NOT NULL default 0,
  lastupdateip varchar(128) NOT NULL default '',
  lastupdate timestamp(14) NOT NULL,
  PRIMARY KEY (id),
  KEY specialorder (specialorder),
  KEY firstname (lastname,firstname),
  KEY hullnumber (hullnumber)
) TYPE=MyISAM;

CREATE TABLE crew (
  id smallint(6) NOT NULL auto_increment,
  firstname varchar(32) NOT NULL default '',
  lastname varchar(48) NOT NULL default '',
  city varchar(32) NOT NULL default '',
  state char(2) NOT NULL default '',
  phone varchar(20) NOT NULL default '',
  email varchar(100) NOT NULL default '',
  height smallint(3) NOT NULL default 0,
  weight smallint(3) NOT NULL default 0,
  positions VARCHAR(200) NOT NULL default '',
  note VARCHAR(500) NOT NULL default '',
  password varchar(16) NOT NULL default '',
  lastupdateip varchar(128) NOT NULL default '',
  lastupdate timestamp(14) NOT NULL,
  PRIMARY KEY (id),
  KEY name (lastname,firstname)
) TYPE=MyISAM;

CREATE TABLE photo2 (
  id int(16) NOT NULL auto_increment,
  width smallint(6) NOT NULL default '0',
  height smallint(6) NOT NULL default '0',
  caption varchar(120) NOT NULL default '',
  gallery_id smallint(6) NOT NULL default '0',
  thumb_width smallint(6) NOT NULL default '0',
  thumb_height smallint(6) NOT NULL default '0',
  hide tinyint(4) NOT NULL default '0',
  filename varchar(250) NOT NULL default '',
  KEY id (id),
  KEY gallery_id (gallery_id)
) TYPE=MyISAM;

CREATE TABLE regatta (
  id int(12) NOT NULL auto_increment,
  startdate date NOT NULL default '0000-00-00',
  enddate date default NULL,
  lastupdate timestamp(14) NOT NULL,
  name varchar(64) NOT NULL default '',
  venue int(12) NOT NULL default '0',
  contact int(12) NOT NULL default '0',
  series1 tinyint(3) NOT NULL default 0,
  series2 tinyint(3) NOT NULL default 0,
  series3 tinyint(3) NOT NULL default 0,
  series4 tinyint(3) NOT NULL default 0,
  series5 tinyint(3) NOT NULL default 0,
  url varchar(128) NOT NULL default '',
  result text,
  description text,
  story text,
  PRIMARY KEY  (id),
  KEY startdate (startdate),
  KEY venue (venue),
  KEY contact (contact)
) TYPE=MyISAM;

CREATE TABLE session (
  session_id int(11) NOT NULL auto_increment,
  session char(32) default NULL,
  modification_date timestamp(14) NOT NULL,
  PRIMARY KEY  (session_id),
  KEY session (session)
) TYPE=MyISAM;

CREATE TABLE thread (
  thread_id int(11) NOT NULL auto_increment,
  forum_id int(11) NOT NULL default '0',
  first_msg int(11) NOT NULL default '0',
  modification_date timestamp(14) NOT NULL,
  PRIMARY KEY  (thread_id),
  KEY forum_id (forum_id),
  KEY modification_date (modification_date)
) TYPE=MyISAM;

CREATE TABLE title (
  title_id int(11) NOT NULL auto_increment,
  title varchar(80) NOT NULL default '',
  modification_date timestamp(14) NOT NULL,
  PRIMARY KEY  (title_id),
  KEY title (title),
  FULLTEXT fttitle (title)
) TYPE=MyISAM;

CREATE TABLE txt (
  txt_id int(11) NOT NULL auto_increment,
  txt text,
  PRIMARY KEY (txt_id),
  FULLTEXT fttxt (txt)
) TYPE=MyISAM;

CREATE TABLE venue (
  id int(12) NOT NULL auto_increment,
  name varchar(64) NOT NULL default '',
  url varchar(64) NOT NULL default '',
  address varchar(128) NOT NULL default '',
  city varchar(64) NOT NULL default '',
  zip varchar(10) NOT NULL default '',
  state char(2) NOT NULL default '',
  lastupdate timestamp(14) NOT NULL,
  PRIMARY KEY  (id)
) TYPE=MyISAM;
