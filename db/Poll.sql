SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `poll_polls` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `subject` CHAR(40) NOT NULL DEFAULT '',
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `description` TEXT NULL,
  `status` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `expiration_date` DATE NOT NULL DEFAULT '0000-00-00',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Table for polls';

CREATE TABLE IF NOT EXISTS `poll_answers` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `poll_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `answer` CHAR(40) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`poll_id`) REFERENCES `poll_polls` (`id`) ON DELETE CASCADE
)
  DEFAULT CHARSET=utf8 COMMENT = 'Table for polls answers';

CREATE TABLE IF NOT EXISTS `poll_votes` (
  `answer_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `poll_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `voter` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`poll_id`, `voter`),
  FOREIGN KEY (`poll_id`) REFERENCES `poll_polls` (`id`) ON DELETE CASCADE
)
  DEFAULT CHARSET=utf8 COMMENT = 'Table for votes';

CREATE TABLE IF NOT EXISTS `poll_discussion` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `poll_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `message` TEXT NOT NULL,
  `voter` VARCHAR(20) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`poll_id`) REFERENCES `poll_polls` (`id`) ON DELETE CASCADE
)
  DEFAULT CHARSET=utf8 COMMENT = 'Table for discussion';