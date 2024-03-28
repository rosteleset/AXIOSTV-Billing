ALTER TABLE `cablecat_cable_types` ADD COLUMN `line_width` SMALLINT(3) NOT NULL DEFAULT 1;
ALTER TABLE `cablecat_cable_types` MODIFY COLUMN `outer_color` VARCHAR(32) NOT NULL DEFAULT '#000000';

CREATE UNIQUE INDEX `_cablecat_cable_name` ON `cablecat_cables` (`name`);
CREATE UNIQUE INDEX `_cablecat_well_name` ON `cablecat_wells` (`name`);
CREATE UNIQUE INDEX `_cablecat_connecter_name` ON `cablecat_connecters` (`name`);

ALTER TABLE `groups`
  ADD COLUMN `bonus` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;


CREATE TABLE IF NOT EXISTS `employees_rfid_log` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `datetime` DATETIME NOT NULL DEFAULT NOW(),
  `rfid` INT(10) UNSIGNED,
  `aid` SMALLINT(6) NOT NULL DEFAULT 0
) COMMENT='All registered RFID entries';

CREATE INDEX `_ik_rfid`
  ON `employees_rfid_log` (`rfid`);

ALTER TABLE `users_contacts`
  DROP INDEX `_type_value`;

ALTER TABLE sharing_files ADD COLUMN `version` VARCHAR(32) NOT NULL DEFAULT '';
ALTER TABLE sharing_files ADD COLUMN `group_id` int(2) NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `sharing_download_log` (
  `id` smallint(6) NOT NULL auto_increment,
  `file_id` smallint(6) NOT NULL DEFAULT 0,
  `date` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `uid` smallint(11) NOT NULL default 0,
  `ip` int(11) unsigned NOT NULL default '0',
  `system_id` varchar(25) NOT NULL default '',
  PRIMARY KEY (`id`)
) COMMENT='Sharing download log';

CREATE TABLE `sharing_groups` (
  `id` smallint(6) NOT NULL auto_increment,
  `name` varchar(25) NOT NULL default '',
  `comment` text NOT NULL,
  PRIMARY KEY (`id`)
) COMMENT='Sharing groups for filese';

CREATE TABLE IF NOT EXISTS `admins_contact_types` (
  `id` smallint(6) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `hidden` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  COMMENT='Types of admin contacts';

REPLACE INTO `admins_contact_types` (`id`, `name`, `is_default`, `hidden`) VALUES
  (1, 'CELL_PHONE', 0, 0),
  (2, 'PHONE', 1, 0),
  (3, 'Skype', 0, 0),
  (4, 'ICQ', 0, 0),
  (5, 'Viber', 0, 0),
  (6, 'Telegram', 0, 0),
  (7, 'Facebook', 0, 0),
  (8, 'VK', 0, 0),
  (9, 'EMail', 1, 0),
  (10, 'Google push', 0, 1);

CREATE TABLE IF NOT EXISTS `admins_contacts` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `aid` int(11) unsigned NOT NULL,
  `type_id` smallint(6) DEFAULT NULL,
  `value` varchar(250) NOT NULL,
  `priority` smallint(6) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `_type_value` (`type_id`,`value`),
  KEY `_aid_contact` (`aid`)
)
  COMMENT='Main admin contacts table';

ALTER TABLE `dv_main` ADD COLUMN `traf_detail` smallint(1) unsigned NOT NULL default '0';

ALTER TABLE `users_social_info` ADD COLUMN `locale` VARCHAR(10) NOT NULL DEFAULT '';

ALTER TABLE `cablecat_commutation_links` ADD COLUMN `attenuation` DOUBLE NOT NULL DEFAULT 0;
ALTER TABLE `cablecat_commutation_links` ADD COLUMN `direction` TINYINT(2) NOT NULL DEFAULT 0;
ALTER TABLE `cablecat_commutation_links` ADD COLUMN `comments` VARCHAR(40) NOT NULL DEFAULT '';
ALTER TABLE `cablecat_links` ADD COLUMN `direction` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `maps_districts` (
  `district_id` SMALLINT(6) UNSIGNED REFERENCES `districts` (`id`)
    ON DELETE CASCADE,
  `object_id` INT(11) REFERENCES `maps_points` (`id`)
    ON DELETE CASCADE
)
  COMMENT = 'District polygons';
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (4, '$lang{DISTRICT}', 'POLYGON', 'district');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (4, '$lang{DISTRICT}', '');
