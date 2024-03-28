CREATE TABLE IF NOT EXISTS `msgs_address` (
	`id`        INT(11)     UNSIGNED            NOT NULL PRIMARY KEY,
	`districts` SMALLINT(6) UNSIGNED DEFAULT 0  NOT NULL,
	`street`    SMALLINT(6) UNSIGNED DEFAULT 0  NOT NULL,
	`build`     SMALLINT(6) UNSIGNED DEFAULT 0  NOT NULL,
	`flat`      VARCHAR(5)           DEFAULT '' NOT NULL,
  
  CONSTRAINT `msgs_id` FOREIGN KEY (`id`)
      REFERENCES `msgs_messages` (`id`) ON DELETE CASCADE
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Msgs set address';

CREATE TABLE IF NOT EXISTS `accident_equipments`
(
    `id`             SMALLINT(3) UNSIGNED AUTO_INCREMENT
        PRIMARY KEY,
    `id_equipment`   SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,
    `date`           DATE                 NOT NULL DEFAULT '0000-00-00',
    `end_date`       DATE                 NOT NULL DEFAULT '0000-00-00',
    `aid`            SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
    `status`         TINYINT(3)  UNSIGNED NOT NULL DEFAULT 0
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Accident address';