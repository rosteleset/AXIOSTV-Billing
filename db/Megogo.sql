SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';


CREATE TABLE IF NOT EXISTS `megogo_tp` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `name` CHAR(40) NOT NULL,
  `amount` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `serviceid` CHAR(40) NOT NULL,
  `additional` SMALLINT(1) NOT NULL DEFAULT '0',
  `free_period` SMALLINT(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) COMMENT = 'Megogo tp';

CREATE TABLE IF NOT EXISTS `megogo_users` (
  `uid` INT(11) UNSIGNED UNIQUE NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(5) UNSIGNED UNIQUE NOT NULL,
  `next_tp_id` SMALLINT(5) UNSIGNED NOT NULL,
  `subscribe_date` DATE NOT NULL DEFAULT '0000-00-00',
  `expiry_date` DATE NOT NULL DEFAULT '0000-00-00',
  `suspend` SMALLINT(1) NOT NULL DEFAULT '0',
  `active` SMALLINT(1) NOT NULL DEFAULT '0',
  FOREIGN KEY (`tp_id`) REFERENCES `megogo_tp` (`id`) ON DELETE RESTRICT
) COMMENT = 'Megogo user account';

CREATE TABLE IF NOT EXISTS `megogo_report` (
  `tp_id` SMALLINT(5) UNSIGNED NOT NULL,
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `days` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `free_days` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `year` SMALLINT(4) UNSIGNED NOT NULL,
  `month` SMALLINT(2) UNSIGNED NOT NULL,
  `payments` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  UNIQUE (`tp_id`, `uid`, `year`, `month`)
) COMMENT = 'Megogo report';

CREATE TABLE IF NOT EXISTS `megogo_free_period` (
  `uid` INT(11) UNSIGNED NOT NULL,
  `used` SMALLINT(1) NOT NULL,
  `date_start` DATE NOT NULL,
  UNIQUE (`uid`)
) COMMENT = 'Megogo users who used free period';
