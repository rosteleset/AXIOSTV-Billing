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

CREATE TABLE IF NOT EXISTS temp_table(
  id INT(11) UNSIGNED KEY AUTO_INCREMENT,
  name VARCHAR(32) NOT NULL DEFAULT '',
  value INT(11) NOT NULL DEFAULT 0
)
  COMMENT = 'Temprorary table';


SET SESSION sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

REPLACE INTO `msgs_status` (`id`, `name`, `readiness`, `task_closed`, `color`) VALUE
  ('0', '$lang{OPEN}', '0', '0', '#0000FF'),
  ('1', '$lang{CLOSED_UNSUCCESSFUL}', '100', '1', '#ff0638'),
  ('2', '$lang{CLOSED_SUCCESSFUL}', '100', '1', '#009D00'),
  ('3', '$lang{IN_WORK}', '10', '0', '#707070'),
  ('4', '$lang{NEW_MESSAGE}', '0', '0', '#FF8000'),
  ('5', '$lang{HOLD_UP}', '0', '0', '0'),
  ('6', '$lang{ANSWER_WAIT}', '50', '0', ''),
  ('9', '$lang{NOTIFICATION_MSG}', '0', '0', ''),
  ('10', '$lang{NOTIFICATION_MSG}  $lang{READED}', '100', '0', ''),
  ('11', '$lang{POTENTIAL_CLIENT}', '0', '0', '');


CREATE TABLE IF NOT EXISTS `users_contacts` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `uid` INT(11) UNSIGNED NOT NULL,
  `type_id` SMALLINT(6),
  `value` VARCHAR(250) NOT NULL,
  `priority` SMALLINT(6) UNSIGNED,
  FOREIGN KEY (`uid`) REFERENCES `users` (`uid`) ON DELETE CASCADE,
  FOREIGN KEY (`type_id`) REFERENCES `users_contact_types` (`id`) ON DELETE CASCADE,
  UNIQUE `_type_value` (`type_id`, `value`),
  INDEX `_uid_contact` (`uid`)
)
  COMMENT = 'Main user contacts table';