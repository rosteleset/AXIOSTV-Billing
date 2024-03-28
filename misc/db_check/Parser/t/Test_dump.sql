CREATE TABLE IF NOT EXISTS `users_pi` (
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `fio` VARCHAR(120) NOT NULL DEFAULT '',
  `phone` VARCHAR(16) NOT NULL DEFAULT '',
  `email` VARCHAR(250) NOT NULL DEFAULT '',
  `country_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `address_street` VARCHAR(100) NOT NULL DEFAULT '',
  `address_build` VARCHAR(10) NOT NULL DEFAULT '',
  `address_flat` VARCHAR(10) NOT NULL DEFAULT '',
  `comments` TEXT NOT NULL,
  `contract_id` VARCHAR(10) NOT NULL DEFAULT '',
  `contract_date` DATE NOT NULL DEFAULT '0000-00-00',
  `contract_sufix` VARCHAR(5) NOT NULL DEFAULT '',
  `pasport_num` VARCHAR(16) NOT NULL DEFAULT '',
  `pasport_date` DATE NOT NULL DEFAULT '0000-00-00',
  `pasport_grant` VARCHAR(100) NOT NULL DEFAULT '',
  `zip` VARCHAR(7) NOT NULL DEFAULT '',
  `city` VARCHAR(20) NOT NULL DEFAULT '',
  `accept_rules` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `location_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`uid`),
  KEY `location_id` (`location_id`)
)
  COMMENT = 'Users personal info';