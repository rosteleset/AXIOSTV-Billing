SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `accident_log` (
  `id`         INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `descr`      VARCHAR(100)         NOT NULL DEFAULT '',
  `priority`   TINYINT(3) UNSIGNED  NOT NULL DEFAULT 0,
  `date`       DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `aid`        SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `end_time`   DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `realy_time` DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status`     TINYINT(3) UNSIGNED  NOT NULL DEFAULT 0,
  `name`       VARCHAR(255)         NOT NULL DEFAULT '',
  `sent_open`  INT(10)    UNSIGNED  NOT NULL DEFAULT 0,
  `sent_close` INT(10)    UNSIGNED  NOT NULL DEFAULT 0,
  KEY `status` (`status`),
  CONSTRAINT `accident_log` FOREIGN KEY (`aid`) REFERENCES `admins` (`aid`) ON DELETE CASCADE
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Accident log';

CREATE TABLE IF NOT EXISTS `accident_address` (
  `id`         SMALLINT(3) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `ac_id`      INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `type_id`    INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `address_id` VARCHAR (255)    NOT NULL DEFAULT 0,
  KEY `address_id` (`address_id`),
  KEY `type_id` (`type_id`),
  CONSTRAINT `address` FOREIGN KEY (`ac_id`) REFERENCES `accident_log` (`id`) ON DELETE CASCADE
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Accident address';

CREATE TABLE IF NOT EXISTS `accident_equipments` (
  `id`           SMALLINT(3) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `id_equipment` SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,
  `date`         DATE                 NOT NULL DEFAULT '0000-00-00',
  `end_date`     DATE                 NOT NULL DEFAULT '0000-00-00',
  `aid`          SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `status`       TINYINT(3)  UNSIGNED NOT NULL DEFAULT 0,
  `sent_open`    INT(10)     UNSIGNED NOT NULL DEFAULT 0,
  `sent_close`   INT(10)     UNSIGNED NOT NULL DEFAULT 0
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Accident equipments';

CREATE TABLE IF NOT EXISTS `accident_compensation` (
  `id`         SMALLINT(3) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `procent`    FLOAT       UNSIGNED NOT NULL DEFAULT 0.0,
  `date`       DATE                 NOT NULL DEFAULT '0000-00-00',
  `service`    SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,
  `type_id`    SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,
  `address_id` SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Accident compensations';