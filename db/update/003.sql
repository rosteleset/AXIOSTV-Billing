ALTER TABLE `equipment_infos`
  ADD COLUMN `snmp_version` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1;
ALTER TABLE `employees_positions`
  ADD COLUMN `vacancy` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `admins`
  ADD COLUMN `telegram_id` VARCHAR(15) NOT NULL DEFAULT '';

INSERT INTO `employees_positions` VALUES
  (1, "$lang{ADMIN}", 0, 0),
  (2, "$lang{ACCOUNTANT}", 0, 0),
  (3, "$lang{MANAGER}", 0, 0);

CREATE TABLE IF NOT EXISTS `employees_profile` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `fio` VARCHAR(188) NOT NULL DEFAULT '',
  `date_of_birth` DATE NOT NULL DEFAULT '0000-00-00',
  `email` VARCHAR(188) UNIQUE NOT NULL DEFAULT '',
  `phone` VARCHAR(188) UNIQUE NOT NULL DEFAULT '',
  `position_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `rating` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  COMMENT = 'Employees profile';

CREATE TABLE IF NOT EXISTS `employees_profile_question` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `position_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `question` TEXT NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY `position_id` (`position_id`) REFERENCES `employees_positions` (`id`)
    ON DELETE CASCADE
)
  COMMENT = 'Employees profile question';

CREATE TABLE IF NOT EXISTS `employees_profile_reply` (
  `question_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `profile_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `reply` TEXT NOT NULL,
  FOREIGN KEY `question_id` (`question_id`) REFERENCES `employees_profile_question` (`id`)
    ON DELETE CASCADE
)
  COMMENT = 'Employees profile reply';

CREATE TABLE IF NOT EXISTS `maps_icons` (
  `id` INT(11) UNSIGNED PRIMARY KEY  AUTO_INCREMENT,
  `name` VARCHAR(32) NOT NULL,
  `filename` VARCHAR(255) NOT NULL,
  `comments` TEXT
)
  COMMENT = 'User-defined icons';

REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (1, '$lang{WELL}', 'well_green.png');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (2, '$lang{WIFI}', 'wifi_green.png');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (3, '$lang{BUILD}', 'build_green.png');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (4, '$lang{ROUTE}', 'route_green.png');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (5, '$lang{MUFF}', 'muff_green.png');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (6, '$lang{SPLITTER}', 'splitter_green.png');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (7, '$lang{CABLE}', 'cable_green.png');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (8, '$lang{EQUIPMENT}', 'nas_green.png');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (9, '$lang{PILLAR}', 'route_black.png');

REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (1, '$lang{BUILD}', 'MARKER', 'build');
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (2, '$lang{WIFI}', 'MARKER_CIRCLE', 'wifi');
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (3, '$lang{ROUTE}', 'MARKERS_POLYLINE', 'route');
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (4, '$lang{WELL}', 'MARKER', 'well');
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (5, '$lang{TRAFFIC}', 'MARKER', 'build');
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (6, '$lang{OBJECT}', 'MARKER', 'custom');

DELETE FROM `maps_layers`
WHERE `id` IN (7, 8, 9);

ALTER TABLE `maps_points`
  ADD COLUMN `created` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP;

CREATE TABLE IF NOT EXISTS `hotspot_oses` (
  `id` SMALLINT(6) PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(32) NOT NULL DEFAULT 'UNKNOWN',
  `version` SMALLINT(6) NOT NULL DEFAULT 0,
  `mobile` TINYINT(1) NOT NULL DEFAULT 0
)
  COMMENT = 'Hotspot visitors OSes';

CREATE TABLE IF NOT EXISTS `hotspot_user_agents` (
  `id` VARCHAR(32) PRIMARY KEY NOT NULL REFERENCES `hotspot_visits` (`id`)
    ON DELETE CASCADE,
  `user_agent` TEXT
)
  COMMENT = 'Hotspot user agents';

CREATE TABLE IF NOT EXISTS `hotspot_browsers` (
  `id` SMALLINT(6) PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(32) NOT NULL DEFAULT 'UNKNOWN',
  `version` SMALLINT(6) NOT NULL DEFAULT 0
)
  COMMENT = 'Hotspot visitors browsers';

ALTER TABLE `hotspot_visits`
  ADD COLUMN `language` VARCHAR(32) NOT NULL DEFAULT '';
ALTER TABLE `hotspot_visits`
  ADD COLUMN `country` VARCHAR(32) NOT NULL DEFAULT '';
ALTER TABLE `hotspot_visits`
  ADD COLUMN `browser_id` SMALLINT(6) NOT NULL DEFAULT 0;
ALTER TABLE `hotspot_visits`
  ADD COLUMN `os_id` SMALLINT(6) NOT NULL DEFAULT 0;
ALTER TABLE `hotspot_visits`
  DROP COLUMN `browser`;

ALTER TABLE `msgs_unreg_requests`
  ADD COLUMN `reaction_time` VARCHAR(100) NOT NULL DEFAULT '';
