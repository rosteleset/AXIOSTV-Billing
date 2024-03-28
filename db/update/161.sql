CREATE TABLE IF NOT EXISTS `cablecat_storage` (
  `id`              INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `cable_id`        INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `installation_id` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  `date`            DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `aid`             SMALLINT(6)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) DEFAULT CHARSET = utf8
  COMMENT = 'Storage items to cablecat';
