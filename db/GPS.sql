SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `gps_tracker_locations` (
  `id` INT(11) PRIMARY KEY AUTO_INCREMENT,
  `aid` SMALLINT(6) NOT NULL,
  `gps_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `coord_x` DOUBLE NOT NULL,
  `coord_y` DOUBLE NOT NULL,
  `speed` DOUBLE NOT NULL DEFAULT '0',
  `altitude` DOUBLE NOT NULL DEFAULT '0',
  `bearing` DOUBLE NOT NULL DEFAULT '0',
  `batt` DOUBLE NOT NULL DEFAULT '0',
  INDEX `aid` (`aid`),
  INDEX `gps_time`(`gps_time`)
)
  COMMENT = 'Locations got from GPS trackers';

CREATE TABLE IF NOT EXISTS `gps_admins_color` (
   `id` SMALLINT(6) PRIMARY KEY AUTO_INCREMENT,
   `aid` SMALLINT(6) UNSIGNED NOT NULL UNIQUE REFERENCES `admins` (`aid`),
   `color` VARCHAR(7) NOT NULL DEFAULT '#0000FF',
   `show_admin` INT NOT NULL DEFAULT 1,
   UNIQUE KEY (`aid`)
)
  COMMENT = 'GPS Admins color';

CREATE TABLE IF NOT EXISTS `gps_admins_thumbnails` (
  `id` SMALLINT(6) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `aid` SMALLINT(6) UNSIGNED NOT NULL UNIQUE REFERENCES `admins` (`aid`),
  `thumbnail_path` VARCHAR(40) NOT NULL DEFAULT ''
)
  COMMENT = 'GPS Admin Thumbnails';

CREATE TABLE IF NOT EXISTS `gps_unregistered_trackers` (
  `gps_imei` VARCHAR(30) PRIMARY KEY NOT NULL,
  `gps_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ip` INT(11) UNSIGNED NOT NULL DEFAULT 0
)
  COMMENT = 'Trackers that were not registered when location got';