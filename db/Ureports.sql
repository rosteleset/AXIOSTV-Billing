SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `ureports_log` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `execute` DATETIME NOT NULL,
  `body` TEXT NOT NULL,
  `destination` VARCHAR(60) NOT NULL DEFAULT '',
  `report_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `status` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Ureports log';

CREATE TABLE IF NOT EXISTS `ureports_main` (
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `registration` DATE NOT NULL,
  `status` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`uid`),
  KEY `tp_id` (`tp_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Ureports user account';

CREATE TABLE IF NOT EXISTS `ureports_user_send_types` (
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `type` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `destination` VARCHAR(60) NOT NULL DEFAULT '',
  KEY (`uid`),
  KEY (`type`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Ureports user send types';

CREATE TABLE IF NOT EXISTS `ureports_spool` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `added` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `execute` DATE NOT NULL,
  `body` TEXT NOT NULL,
  `destination` VARCHAR(60) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Ureports spool';


CREATE TABLE IF NOT EXISTS `ureports_tp` (
  `msg_price` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `tp_id` SMALLINT(6) UNSIGNED DEFAULT '0',
  `last_active` DATE DEFAULT '0000-00-00',
  KEY `tp_id` (`tp_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Ureports tariff plans';


CREATE TABLE IF NOT EXISTS `ureports_tp_reports` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `msg_price` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `report_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT,
  `module` VARCHAR(32) NOT NULL DEFAULT '',
  `visual` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `tp_id` (`tp_id`, `report_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Ureports users Tarif plans';

CREATE TABLE IF NOT EXISTS `ureports_users_reports` (
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `report_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `date` DATE NOT NULL,
  `value` VARCHAR(10) NOT NULL DEFAULT '',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  UNIQUE KEY uid_reports_id (`uid`, `report_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Ureports users reports';
