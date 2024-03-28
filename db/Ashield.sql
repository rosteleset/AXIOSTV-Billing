SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `ashield_main` (
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `gid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `status` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `expire` DATE NOT NULL,
  PRIMARY KEY (`uid`),
  UNIQUE KEY `uid` (`uid`)
)
  COMMENT = 'Ashield users';

CREATE TABLE IF NOT EXISTS `ashield_avd_log` (
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `state` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `agentuuid` VARCHAR(36) NOT NULL DEFAULT '',
  `groupuuid` VARCHAR(36) NOT NULL DEFAULT '',
  `groupname` VARCHAR(20) NOT NULL DEFAULT '',
  `tariffplancode` VARCHAR(40) NOT NULL DEFAULT '',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `date` DATETIME NOT NULL,
  `work_period_begin` DATE NOT NULL,
  `id` INTEGER(11) NOT NULL AUTO_INCREMENT,
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `station_action` (`uid`, `agentuuid`, `state`)
)
  COMMENT = 'Ashield AV Desc Subscribes';


CREATE TABLE IF NOT EXISTS `ashield_tps` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(25) NOT NULL,
  `payment_type` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `daily_payment` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `monthly_payment` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `grace_period` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `drweb_id` VARCHAR(36) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
)
  COMMENT = 'Ashield tarif plans';


