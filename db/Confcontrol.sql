SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

DROP TABLE IF EXISTS `confcontrol_controlled_files`;
DROP TABLE IF EXISTS `confcontrol_stats`;


CREATE TABLE IF NOT EXISTS `confcontrol_controlled_files` (
  `id` SMALLINT(6) AUTO_INCREMENT PRIMARY KEY,
  `path` VARCHAR(50) NOT NULL,
  `name` VARCHAR(50) NOT NULL,
  `comments` TEXT NOT NULL,
  UNIQUE (`path`, `name`)
)
  AUTO_INCREMENT = 1
  COMMENT = 'List of files to control';

CREATE TABLE IF NOT EXISTS `confcontrol_stats` (
  `file_id` SMALLINT(6) NOT NULL REFERENCES `confcontrol_controlled_files` (`id`),
  `mtime` DATETIME NOT NULL,
  `crc` VARCHAR(32) NOT NULL,
  UNIQUE (`mtime`, `file_id`)
)
  COMMENT = 'Stats for controlled files';