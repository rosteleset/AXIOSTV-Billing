SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `filearch` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `filename` VARCHAR(100) NOT NULL DEFAULT '',
  `path` VARCHAR(250) NOT NULL DEFAULT '',
  `name` VARCHAR(200) NOT NULL DEFAULT '',
  `checksum` VARCHAR(150) NOT NULL DEFAULT '',
  `added` DATE NOT NULL DEFAULT '0000-00-00',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `size` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT NOT NULL,
  `state` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `filename` (`filename`, `path`)
)
  COMMENT = 'Filearch';


CREATE TABLE IF NOT EXISTS `filearch_film_actors` (
  `video_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `actor_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  UNIQUE KEY `video_id` (`video_id`, `actor_id`),
  KEY `actor_id` (`actor_id`)
)
  COMMENT = 'Filearch actors';


CREATE TABLE IF NOT EXISTS `filearch_film_genres` (
  `video_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `genre_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  KEY `video_id` (`video_id`)
)
  COMMENT = 'Filearch genres';

CREATE TABLE IF NOT EXISTS `filearch_state` (
  `file_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `state` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  KEY `file_id` (`file_id`)
)
  COMMENT = 'Filearch state';

CREATE TABLE IF NOT EXISTS `filearch_video` (
  `id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `original_name` VARCHAR(200) NOT NULL DEFAULT '',
  `year` SMALLINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `genre` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `producer` VARCHAR(50) NOT NULL DEFAULT '',
  `descr` TEXT NOT NULL,
  `studio` VARCHAR(150) NOT NULL DEFAULT '',
  `duration` TIME NOT NULL DEFAULT '00:00:00',
  `language` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `file_format` VARCHAR(20) NOT NULL DEFAULT '',
  `file_quality` VARCHAR(20) NOT NULL DEFAULT '',
  `file_vsize` VARCHAR(50) NOT NULL DEFAULT '',
  `file_sound` VARCHAR(50) NOT NULL DEFAULT '',
  `cover_url` VARCHAR(200) NOT NULL DEFAULT '',
  `imdb` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `parent` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `extra` VARCHAR(200) NOT NULL DEFAULT '',
  `country` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `cover_small_url` VARCHAR(200) NOT NULL DEFAULT '',
  `pin_access` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `updated` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `id` (`id`)
)
  COMMENT = 'Filearch';

CREATE TABLE IF NOT EXISTS `filearch_video_actors` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(60) NOT NULL DEFAULT '',
  `bio` TEXT NOT NULL,
  `origin_name` VARCHAR(60) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `origin_name` (`origin_name`)
)
  COMMENT = 'Filearch';

CREATE TABLE IF NOT EXISTS `filearch_video_genres` (
  `id` TINYINT(4) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(20) NOT NULL DEFAULT '',
  `imdb` VARCHAR(20) DEFAULT NULL,
  `sharereactor` VARCHAR(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
)
  COMMENT = 'Filearch';

CREATE TABLE IF NOT EXISTS `filearch_countries` (
  `id` TINYINT(4) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
)
  COMMENT = 'Filearch';
