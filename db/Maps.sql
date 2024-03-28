
/*
DROP TABLE IF EXISTS `maps_wells`;
DROP TABLE IF EXISTS `maps_wifi_zones`;
DROP TABLE IF EXISTS `maps_point_types`;
DROP TABLE IF EXISTS `maps_coords`;
DROP TABLE IF EXISTS `maps_points`;
DROP TABLE IF EXISTS `maps_layers`;
DROP TABLE IF EXISTS `maps_circles`;
DROP TABLE IF EXISTS `maps_polylines`;
DROP TABLE IF EXISTS `maps_polyline_points`;
DROP TABLE IF EXISTS `maps_polygons`;
DROP TABLE IF EXISTS `maps_polygon_points`;
DROP TABLE IF EXISTS `maps_text`;
DROP TABLE IF EXISTS `maps_icons`;
DROP TABLE IF EXISTS `maps_districts`;
*/

SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `maps_wells` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) DEFAULT NULL,
  `type_id` TINYINT(1) UNSIGNED DEFAULT '0',
  `coordx` DOUBLE(20, 14) DEFAULT '0.00000000000000',
  `coordy` DOUBLE(20, 14) DEFAULT '0.00000000000000',
  `comment` TEXT,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Wells coords';

CREATE TABLE IF NOT EXISTS `maps_wifi_zones` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `radius` INT(10) UNSIGNED DEFAULT '0',
  `coordx` DOUBLE(20, 14) DEFAULT '0.00000000000000',
  `coordy` DOUBLE(20, 14) DEFAULT '0.00000000000000',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Wifi zones';

CREATE TABLE IF NOT EXISTS `maps_point_types` (
  `id` SMALLINT(6) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(60) NOT NULL UNIQUE,
  `icon` VARCHAR(30) NOT NULL DEFAULT 'default',
  `layer_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `comments` TEXT
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Types of custom points';

REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (1, '$lang{WELL}', 'well_green', 11);
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (2, '$lang{WIFI}', '', 2);
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (3, '$lang{BUILD}', 'build_green', 1);
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (4, '$lang{DISTRICT}', '', 4);
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (5, '$lang{MUFF}', 'muff_green');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (6, '$lang{SPLITTER}', 'splitter_green');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (7, '$lang{CABLE}', '', 10);
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (8, '$lang{EQUIPMENT}', 'nas_green', 7);
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (20, 'PON', 'pon_normal', 20);
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`, `layer_id`) VALUES (33, '$lang{CAMERAS}', 'cams_main', 20);


CREATE TABLE IF NOT EXISTS `maps_coords` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `coordx` DOUBLE NOT NULL,
  `coordy` DOUBLE NOT NULL
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Coordinates for custom points';

CREATE TABLE IF NOT EXISTS `maps_points` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(64) NOT NULL DEFAULT '',
  `coord_id` INT(11) UNSIGNED REFERENCES `maps_coords` (`id`)
    ON DELETE CASCADE,
  `type_id` SMALLINT(6) UNSIGNED REFERENCES `maps_point_types` (`id`)
    ON DELETE RESTRICT,
  `created` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `parent_id` INT(11) UNSIGNED REFERENCES `maps_points` (`id`)
    ON DELETE RESTRICT,
  `comments` TEXT,
  `location_id` INT(11) UNSIGNED REFERENCES `builds` (`id`)
    ON DELETE RESTRICT,
  `planned` TINYINT(1) NOT NULL DEFAULT 0,
  `installed` DATETIME,
  `external` TINYINT(1) NOT NULL DEFAULT 0,
  KEY `location_id` (`location_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Custom points';

CREATE TABLE IF NOT EXISTS `maps_layers` (
  `id` SMALLINT(6) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL DEFAULT '',
  `type` VARCHAR(32) NOT NULL DEFAULT 'build',
  `structure` VARCHAR(32) NOT NULL DEFAULT 'MARKER',
  `module` VARCHAR(32) NOT NULL DEFAULT 'Maps',
  `markers_in_cluster` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  `comments` TEXT
)
  AUTO_INCREMENT = 100
  DEFAULT CHARSET = utf8
  COMMENT = 'Map layers';

REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (1, '$lang{BUILD}', 'MARKER', 'build');
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (2, '$lang{WIFI}', 'POLYGON', 'wifi');
DELETE FROM `maps_layers` WHERE `id`='3';
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (4, '$lang{DISTRICT}', 'POLYGON', 'district');
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (5, '$lang{TRAFFIC}', 'MARKER', 'build');
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (6, '$lang{OBJECTS}', 'MARKER', 'custom');
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (12, '$lang{PLOT}', 'POLYGON', 'build');

CREATE TABLE IF NOT EXISTS `maps_circles` (
  `id` INT(11) UNSIGNED PRIMARY KEY  AUTO_INCREMENT,
  `layer_id` SMALLINT(6) UNSIGNED REFERENCES `maps_layers` (`id`)
    ON DELETE CASCADE,
  `object_id` INT(11) UNSIGNED REFERENCES `maps_points` (`id`)
    ON DELETE CASCADE,
  `coordx` DOUBLE NOT NULL,
  `coordy` DOUBLE NOT NULL,
  `radius` DOUBLE NOT NULL  DEFAULT 1.0,
  `name` VARCHAR(32) NOT NULL,
  `comments` TEXT
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Custom drew circles';

CREATE TABLE IF NOT EXISTS `maps_polylines` (
  `id` INT(11) UNSIGNED PRIMARY KEY  AUTO_INCREMENT,
  `layer_id` SMALLINT(6) UNSIGNED REFERENCES `maps_layers` (`id`)
    ON DELETE CASCADE,
  `object_id` INT(11) UNSIGNED REFERENCES `maps_points` (`id`)
    ON DELETE CASCADE,
  `name` VARCHAR(32) NOT NULL DEFAULT '',
  `comments` TEXT,
  `length` DOUBLE NOT NULL DEFAULT 0,
  KEY `object_id` (`object_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Custom drew polylines';

CREATE TABLE IF NOT EXISTS `maps_polyline_points` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `polyline_id` INT(11) UNSIGNED REFERENCES `maps_polylines` (`id`)
    ON DELETE CASCADE,
  `coordx` DOUBLE NOT NULL,
  `coordy` DOUBLE NOT NULL,
  KEY `polyline_id` (`polyline_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Custom drew polyline points';

CREATE TABLE IF NOT EXISTS `maps_polygons` (
  `id` INT(11) UNSIGNED PRIMARY KEY  AUTO_INCREMENT,
  `layer_id` SMALLINT(6) UNSIGNED REFERENCES `maps_layers` (`id`)
    ON DELETE CASCADE,
  `object_id` INT(11) UNSIGNED REFERENCES `maps_points` (`id`)
    ON DELETE CASCADE,
  `name` VARCHAR(32) NOT NULL,
  `color` VARCHAR(32) NOT NULL  DEFAULT 'silver',
  `comments` TEXT,
  KEY `object_id` (`object_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Custom drew polygons';

CREATE TABLE IF NOT EXISTS `maps_polygon_points` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `polygon_id` INT(11) UNSIGNED REFERENCES `maps_polygons` (`id`)
    ON DELETE CASCADE,
  `coordx` DOUBLE NOT NULL,
  `coordy` DOUBLE NOT NULL,
  KEY `polygon_id` (`polygon_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Custom drew polygons points';

CREATE TABLE IF NOT EXISTS `maps_text` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `layer_id` SMALLINT(6) UNSIGNED REFERENCES `maps_layers` (`id`)
    ON DELETE CASCADE,
  `object_id` INT(11) UNSIGNED REFERENCES `maps_points` (`id`)
    ON DELETE CASCADE,
  `coordx` DOUBLE NOT NULL,
  `coordy` DOUBLE NOT NULL,
  `text` TEXT
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Custom drew text';

CREATE TABLE IF NOT EXISTS `maps_icons` (
  `id` INT(11) UNSIGNED PRIMARY KEY  AUTO_INCREMENT,
  `name` VARCHAR(32) NOT NULL DEFAULT '',
  `filename` VARCHAR(255) NOT NULL DEFAULT '',
  `comments` TEXT
)
  DEFAULT CHARSET = utf8
  COMMENT = 'User-defined icons';

CREATE TABLE IF NOT EXISTS `maps_districts` (
  `district_id` SMALLINT(6) UNSIGNED REFERENCES `districts` (`id`)
    ON DELETE CASCADE,
  `object_id` INT(11) UNSIGNED REFERENCES `maps_points` (`id`)
    ON DELETE CASCADE
)
  DEFAULT CHARSET = utf8
  COMMENT = 'District polygons';
