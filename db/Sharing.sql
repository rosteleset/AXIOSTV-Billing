SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `sharing_main` (
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `type` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `cid` VARCHAR(15) NOT NULL DEFAULT '',
  `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `speed` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `filter_id` VARCHAR(15) NOT NULL DEFAULT '',
  `logins` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `extra_byte` DOUBLE(15, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  KEY `uid` (`uid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Sharing main info';

CREATE TABLE IF NOT EXISTS `sharing_log` (
  `virtualhost` TEXT,
  `remoteip` INT(10) UNSIGNED DEFAULT '0',
  `remoteport` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `serverid` TEXT,
  `connectionstatus` CHAR(3) DEFAULT NULL,
  `username` VARCHAR(20) DEFAULT NULL,
  `identuser` VARCHAR(40) DEFAULT NULL,
  `start` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `requestmethod` TEXT,
  `url` TEXT,
  `protocol` TEXT,
  `statusbeforeredir` INT(10) UNSIGNED DEFAULT NULL,
  `statusafterredir` INT(10) UNSIGNED DEFAULT NULL,
  `processid` INT(10) UNSIGNED DEFAULT NULL,
  `threadid` INT(10) UNSIGNED DEFAULT NULL,
  `duration` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `microseconds` INT(10) UNSIGNED DEFAULT NULL,
  `recv` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `sent` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `bytescontent` INT(10) UNSIGNED DEFAULT NULL,
  `useragent` TEXT,
  `referer` TEXT,
  `uniqueid` TEXT,
  `nas_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  KEY `username` (`username`)
) DEFAULT CHARSET = utf8
  COMMENT = 'Sharing log file';

CREATE TABLE IF NOT EXISTS `sharing_trafic_tarifs` (
  `id` TINYINT(4) NOT NULL DEFAULT '0',
  `descr` VARCHAR(30) DEFAULT NULL,
  `nets` TEXT,
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `prepaid` INT(11) UNSIGNED DEFAULT '0',
  `in_price` DOUBLE(13, 5) UNSIGNED NOT NULL DEFAULT '0.00000',
  `out_price` DOUBLE(13, 5) UNSIGNED NOT NULL DEFAULT '0.00000',
  `in_speed` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `interval_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `rad_pairs` TEXT NOT NULL,
  `out_speed` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `expression` VARCHAR(255) NOT NULL DEFAULT '',
  UNIQUE KEY `id` (`id`, `tp_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Sharing Traffic Class';

CREATE TABLE IF NOT EXISTS `sharing_errors` (
  `datetime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `username` VARCHAR(20) NOT NULL DEFAULT '',
  `file_and_path` VARCHAR(200) NOT NULL DEFAULT '',
  `client_name` VARCHAR(127) NOT NULL DEFAULT '',
  `ip` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `client_command` VARCHAR(250) NOT NULL DEFAULT ''
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Sharing errors';


CREATE TABLE IF NOT EXISTS `sharing_priority` (
  `server` VARCHAR(60) DEFAULT NULL,
  `file` VARCHAR(250) NOT NULL DEFAULT '',
  `size` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `priority` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `datetime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `file` (`file`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Sharing file priority';

# NEW TABLES
CREATE TABLE `sharing_additions` (
  `id` smallint(6) NOT NULL auto_increment,
  `name` varchar(25) NOT NULL default '',
  `quantity` int(11) unsigned NOT NULL default '0',
  `price` double(14,2) default NULL,
  `tp_id` smallint(6) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Sharing Additions';

CREATE TABLE IF NOT EXISTS `sharing_files` (
  `id` smallint(6) NOT NULL auto_increment,
  `name` varchar(25) NOT NULL default '',
  `amount` double(10,2) NOT NULL default '0.00',
  `link_time` smallint(3) NOT NULL default 0,
  `file_time` smallint(3) NOT NULL default 0,
  `group_id` int(2) NOT NULL DEFAULT 0,
  `version` VARCHAR(32) NOT NULL DEFAULT '',
  `remind_for` int(10) NOT NULL DEFAULT 0,
  `comment` text NOT NULL,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'File for download';

CREATE TABLE IF NOT EXISTS `sharing_users` (
  `uid` INT(11) unsigned NOT NULL DEFAULT 0,
  `file_id` SMALLINT(6) NOT NULL DEFAULT 0,
  `date_to` DATE NOT NULL DEFAULT '0000-00-00',
  `demo` tinyint(3) unsigned NOT NULL DEFAULT 0,
  UNIQUE (`uid`, `file_id`),
  FOREIGN KEY (file_id) REFERENCES sharing_files(id)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Users and their files';

CREATE TABLE IF NOT EXISTS `sharing_download_log` (
  `id` smallint(6) NOT NULL auto_increment,
  `file_id` smallint(6) NOT NULL DEFAULT 0,
  `date` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `uid` int(11) unsigned NOT NULL default 0,
  `ip` int(11) unsigned NOT NULL default '0',
  `system_id` varchar(25) NOT NULL default '',
  PRIMARY KEY (`id`)
) DEFAULT CHARSET = utf8
  COMMENT='Sharing download log';

CREATE TABLE IF NOT EXISTS `sharing_groups` (
  `id` smallint(6) NOT NULL auto_increment,
  `name` varchar(25) NOT NULL default '',
  `comment` text NOT NULL,
  PRIMARY KEY (`id`)
) DEFAULT CHARSET = utf8
  COMMENT='Sharing groups for files';
