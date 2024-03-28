ALTER TABLE `info_fields` ADD COLUMN `required` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `cablecat_storage_installation` (
  `id`              INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `object_id`       INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `type`            SMALLINT(6) UNSIGNED NOT NULL NOT NULL DEFAULT 0,
  `installation_id` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  `date`            DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `aid`             SMALLINT(6)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) DEFAULT CHARSET = utf8
  COMMENT = 'Storage installation to Cablecat objects';

INSERT INTO `cablecat_storage_installation` (`object_id`, `type`, `installation_id`, `date`, `aid`)
SELECT `cable_id`, 1, `installation_id`, `date`, `aid` FROM `cablecat_storage`;