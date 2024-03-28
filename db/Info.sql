SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `info_info`
(
  `id` INT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `obj_type` VARCHAR(30) DEFAULT ''         NOT NULL,
  `obj_id` INT DEFAULT 0                  NOT NULL,
  `comment_id` SMALLINT(6) DEFAULT 0          NOT NULL,
  `media_id` SMALLINT(6) DEFAULT 0          NOT NULL,
  `location_id` INT(11) NOT NULL DEFAULT '0',
  `date` DATETIME NOT NULL,
  `admin_id` SMALLINT NOT NULL DEFAULT 0,
  `document_id` SMALLINT(6) NOT NULL DEFAULT '0',
  KEY `location_id` (`location_id`),
  KEY `comment_id` (`comment_id`),
  KEY `admin_id` (`admin_id`),
  PRIMARY KEY `id` (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Info universal info';

CREATE TABLE IF NOT EXISTS `info_media`
(
  `id` SMALLINT(6) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `filename` VARCHAR(250) NOT NULL,
  `real_name` TEXT,
  `content_type` VARCHAR(30) NOT NULL,
  `file` BLOB NULL,
  `content_size` VARCHAR(30) DEFAULT '0' NOT NULL
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Info universal media';

CREATE TABLE IF NOT EXISTS `info_comments`
(
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `text` TEXT,
  PRIMARY KEY `id` (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Info universal comments';

CREATE TABLE IF NOT EXISTS `info_locations` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `coordx` DOUBLE NOT NULL DEFAULT 0,
  `coordy` DOUBLE NOT NULL DEFAULT 0,
  `comment` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Info universal GPS location';


CREATE TABLE IF NOT EXISTS `info_documents`
(
  `id` SMALLINT(6) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `filename` VARCHAR(250) NOT NULL DEFAULT '',
  `real_name` TEXT,
  `file` BLOB NULL,
  `content_type` VARCHAR(30) NOT NULL DEFAULT '',
  `content_size` VARCHAR(30) DEFAULT '0' NOT NULL,
  `comment_id` SMALLINT(6) NOT NULL DEFAULT 0
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8
  COMMENT = 'Info universal documents';

CREATE TABLE IF NOT EXISTS `info_change_comments`
(
    `id`          BIGINT UNSIGNED AUTO_INCREMENT
        PRIMARY KEY,
    `id_comments` BIGINT           NOT NULL DEFAULT 0,
    `date_change` DATE             NOT NULL DEFAULT '0000-00-00',
    `aid`         INT(11) UNSIGNED NOT NULL DEFAULT 0,
    `uid`         INT(11) UNSIGNED NOT NULL DEFAULT 0,
    `text`        VARCHAR(300)     NOT NULL DEFAULT '',
    `old_comment` VARCHAR(300)     NOT NULL DEFAULT '',
    KEY `aid` (`aid`),
    KEY `uid` (`uid`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = utf8
    COMMENT = 'Info change comment';