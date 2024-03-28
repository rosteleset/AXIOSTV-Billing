CREATE TABLE IF NOT EXISTS `economizer_user_info` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `light` INT UNSIGNED NOT NULL DEFAULT 0,
  `gas` INT UNSIGNED NOT NULL DEFAULT 0,
  `water` INT UNSIGNED NOT NULL DEFAULT 0,
  `communal` DOUBLE(6, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `comments` TEXT NOT NULL,
  PRIMARY KEY (`uid`, `date`),
  KEY `id` (`id`)
)
  COMMENT = 'Users data';

CREATE TABLE IF NOT EXISTS `economizer_tariffs` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `light` TEXT NOT NULL,
  `gas` DOUBLE(6, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `light` DOUBLE(6, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  PRIMARY KEY (`id`),
  KEY `id` (`id`)
)
  COMMENT = 'Public utilities tariffs';