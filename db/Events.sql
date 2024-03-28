SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `events_state` (
  `id` SMALLINT(6) UNSIGNED AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL DEFAULT '',
  PRIMARY KEY `event_state_id` (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Events_state and name';

CREATE TABLE IF NOT EXISTS `events_priority` (
  `id` SMALLINT(6) UNSIGNED AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL,
  `value` SMALLINT(6) NOT NULL DEFAULT 2 COMMENT 'NORMAL',
  PRIMARY KEY `event_priority_id` (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Events priorities name';

CREATE TABLE IF NOT EXISTS `events_priority_send_types` (
  `aid` SMALLINT(6) UNSIGNED NOT NULL REFERENCES `admins` (`aid`)
    ON DELETE CASCADE,
  `priority_id` SMALLINT(6) UNSIGNED NOT NULL REFERENCES `events_priority` (`id`)
    ON DELETE RESTRICT,
  `send_types` VARCHAR(255) NOT NULL DEFAULT '',
  UNIQUE `aid_priority` (`aid`, `priority_id`),
  KEY `priority_id` (`priority_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Defines how each admin will recieve notifications for defined priority';

CREATE TABLE IF NOT EXISTS `events_privacy` (
  `id` SMALLINT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(40) NOT NULL DEFAULT '',
  `value` SMALLINT(6) NOT NULL DEFAULT 0
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Events privacy settings';

CREATE TABLE IF NOT EXISTS `events_group` (
  `id` SMALLINT(6) UNSIGNED AUTO_INCREMENT,
  `name` VARCHAR(40) NOT NULL DEFAULT '',
  `modules` TEXT NOT NULL,
  PRIMARY KEY `event_groups_id` (`id`),
  UNIQUE `event_group_name` (`name`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Events privacy settings';

CREATE TABLE IF NOT EXISTS `events_admin_group`(
  `aid` SMALLINT(6) UNSIGNED NOT NULL
  REFERENCES `admins`(`aid`),
  `group_id` SMALLINT(6) UNSIGNED NOT NULL
  REFERENCES `events_group` (`id`),
  UNIQUE `_aid_group` (`aid`, `group_id`)
)
 DEFAULT CHARSET = utf8 COMMENT = 'Events admin group';

CREATE TABLE IF NOT EXISTS `events` (
  `id` INT(6) UNSIGNED AUTO_INCREMENT,
  `module` VARCHAR(30) NOT NULL DEFAULT 'EXTERNAL',
  `title` VARCHAR(32) NOT NULL DEFAULT '',
  `comments` TEXT,
  `extra` VARCHAR(256) NOT NULL DEFAULT '',
  `state_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 1 REFERENCES `events_state` (`id`)
    ON DELETE RESTRICT,
  `priority_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 1 REFERENCES `events_priority` (`id`)
    ON DELETE RESTRICT,
  `privacy_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 1 REFERENCES `events_privacy` (`id`)
    ON DELETE RESTRICT,
  `group_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 1 REFERENCES `events_group` (`id`)
    ON DELETE RESTRICT,
  `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `aid` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `domain_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY `event_id` (`id`),
  KEY `group_id` (`group_id`),
  KEY `privacy_id` (`privacy_id`),
  KEY `priority_id` (`priority_id`),
  KEY `aid` (`aid`),
  KEY `state_id` (`state_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Events is some information that admin have to see';


REPLACE INTO `events_state` VALUES
  (1, '_{NEW}_'),
  (2, '_{RECV}_'),
  (3, '_{CLOSED}_')
;

REPLACE INTO `events_priority` VALUES
  (1, '_{VERY_LOW}_', 0),
  (2, '_{LOW}_', 1),
  (3, '_{NORMAL}_', 2),
  (4, '_{HIGH}_', 3),
  (5, '_{CRITICAL}_', 4);

REPLACE INTO `events_privacy` VALUES
  (1, '_{ALL}_', 0),
  (2, '_{ADMIN}_ _{GROUP}_', 1),
  (3, '_{ADMIN}_ _{USER}_ _{GROUP}_', 2),
  (4, '_{ADMIN}_ _{GEOZONE}_', 3);


REPLACE INTO `events_group` (`id`, `name`, `modules`) VALUES (1, 'BASE', 'Events,Msgs,Paysys,SYSTEM');
REPLACE INTO `events_group` (`id`, `name`, `modules`) VALUES (2, 'CLIENTS', 'Events,Msgs,SYSTEM');
REPLACE INTO `events_group` (`id`, `name`, `modules`) VALUES (3, 'EQUIPMENT', 'Equipment, Cablecat');