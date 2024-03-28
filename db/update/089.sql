CREATE TABLE `msgs_team_ticket` (
  `id`          INT(11)      UNSIGNED NOT NULL DEFAULT 0,
  `responsible` SMALLINT(6)  UNSIGNED NOT NULL DEFAULT 0,
  `state`       TINYINT(3)   UNSIGNED NOT NULL DEFAULT 0,
  `id_team`     INT(11)      UNSIGNED NOT NULL DEFAULT 0,
  
  PRIMARY KEY (`id`),
  KEY `msgs_id_team_fk` (`id_team`),

  CONSTRAINT `msgs_dispatch_fk` FOREIGN KEY (`id`) REFERENCES `msgs_messages` (`id`),
  CONSTRAINT `msgs_id_team_fk` FOREIGN KEY (`id_team`) REFERENCES `msgs_dispatch` (`id`)
)
DEFAULT CHARSET=utf8 
COMMENT='test';


CREATE TABLE `msgs_team_address` (
  `id`          SMALLINT(3)   UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_team`     INT(11)       UNSIGNED NOT NULL DEFAULT 0,
  `district_id` SMALLINT(3)   UNSIGNED NOT NULL DEFAULT 0,
  `street_id`   SMALLINT(3)   UNSIGNED NOT NULL DEFAULT 0,
  `build_id`    SMALLINT(3)   UNSIGNED NOT NULL DEFAULT 0,
  
  PRIMARY KEY (`id`)
) 
DEFAULT CHARSET=utf8 
COMMENT='Dispatch ticket';

ALTER TABLE `cams_folder` DROP KEY `title`;

ALTER TABLE `maps_point_types` ADD COLUMN `layer_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;

REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (1, '$lang{WELL}', 'well_green', 11);
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (2, '$lang{WIFI}', '', 2);
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (3, '$lang{BUILD}', 'build_green', 1);
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (4, '$lang{DISTRICT}', '', 4);
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (5, '$lang{MUFF}', 'muff_green', 0);
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (6, '$lang{SPLITTER}', 'splitter_green', 0);
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (7, '$lang{CABLE}', '', 10);
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (8, '$lang{EQUIPMENT}', 'nas_green', 7);
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (20, 'PON', 'pon_normal', 20);
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (33, '$lang{CAMERAS}', 'cams_main', 33);

ALTER TABLE `users_pi` ADD COLUMN `tax_number` VARCHAR(30) NOT NULL DEFAULT '0';
