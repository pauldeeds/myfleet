# ALTER TABLE msg ADD COLUMN password varchar(40) NOT NULL default '' AFTER bad;
ALTER TABLE msg ADD COLUMN deleted tinyint(1) NOT NULL default 0 AFTER bad;
