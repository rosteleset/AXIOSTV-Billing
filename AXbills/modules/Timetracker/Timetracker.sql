SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';
CREATE TABLE IF NOT EXISTS `timetracker` (
  `id`              INT(11)     UNSIGNED NOT NULL AUTO_INCREMENT,
  `aid`             SMALLINT(6) NOT NULL DEFAULT 0,
  `element_id`      SMALLINT(1) UNSIGNED DEFAULT 0,
  `time_per_element` SMALLINT(1) UNSIGNED DEFAULT 0,
  `date`            DATE NOT NULL DEFAULT '0000-00-00',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Time tracking';

CREATE TABLE IF NOT EXISTS `timetracker_element` ( 
	`id`            SMALLINT    UNSIGNED NOT NULL AUTO_INCREMENT,
	`element`       VARCHAR(40)          DEFAULT '',
	`priority`      TINYINT(1)  UNSIGNED DEFAULT 0,
	`external_system` SMALLINT(1) UNSIGNED DEFAULT 0,
	`date`          DATE NOT NULL DEFAULT '0000-00-00',
	PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Timetracker elements';





