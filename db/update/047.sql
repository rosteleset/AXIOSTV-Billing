CREATE TABLE IF NOT EXISTS  `storage_property` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL DEFAULT '',
  `comments` VARCHAR(60) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Storage property table';

CREATE TABLE IF NOT EXISTS `storage_articles_property` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `storage_incoming_articles_id` INT(10) UNSIGNED DEFAULT '0',
  `property_id` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  `value` TEXT,
  PRIMARY KEY (`id`)
)
DEFAULT CHARSET=utf8 COMMENT = 'Storage items property table';

SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';
CREATE TABLE IF NOT EXISTS  `storage_measure` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL DEFAULT '',
  `comments` VARCHAR(60) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Storage measuring';

REPLACE INTO `storage_measure` (`id`, `name`) VALUES (0, '$lang{UNIT}');
REPLACE INTO `storage_measure` (`id`, `name`) VALUES (1, '$lang{METERS}');
REPLACE INTO `storage_measure` (`id`, `name`) VALUES (2, '$lang{SM}');
REPLACE INTO `storage_measure` (`id`, `name`) VALUES (3, '$lang{MM}');
REPLACE INTO `storage_measure` (`id`, `name`) VALUES (4, '$lang{LITERS}');
REPLACE INTO `storage_measure` (`id`, `name`) VALUES (5, '$lang{BOXES}');