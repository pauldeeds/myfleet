CREATE TABLE gallery (
  id int(16) NOT NULL auto_increment,
  name varchar(40) NOT NULL default '',
  description text,
  hide tinyint(1) NOT NULL default '0',
  KEY id (id)
) TYPE=MyISAM;

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
  KEY gallery_id (gallery_id),
  KEY hide (hide)
) TYPE=MyISAM;
