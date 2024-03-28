CREATE TABLE IF NOT EXISTS `crm_working_time_norms` (
  `year` SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0,
  `month` SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
  `hours` SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,
  `days`SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,
  UNIQUE KEY `year_month` (`year`, `month`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Entity working time norms';

ALTER TABLE `builds` ADD COLUMN `build_schema` VARCHAR(150) NOT NULL DEFAULT '';
ALTER TABLE `builds` ADD COLUMN `numbering_direction` tinyint(1) unsigned NOT NULL default '0';

ALTER TABLE `reports_groups` ADD COLUMN `admins` VARCHAR(60) NOT NULL DEFAULT '';

ALTER TABLE `iptv_extra_params` ADD COLUMN `pin` VARCHAR(10) NOT NULL DEFAULT '';
ALTER TABLE `builds` ADD COLUMN `numbering_direction` tinyint(1) unsigned NOT NULL default '0';
ALTER TABLE `iptv_extra_params` ADD COLUMN `pin` VARCHAR(10) NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS `msgs_chat`
(
  `id`         INT AUTO_INCREMENT
    PRIMARY KEY,
  `message`    VARCHAR(100) DEFAULT ''            NOT NULL,
  `aid`        INT DEFAULT '0'                    NOT NULL,
  `uid`        INT DEFAULT '0'                    NOT NULL,
  `date`       DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
  `num_ticket` INT DEFAULT '0'                    NOT NULL
)
  ENGINE = InnoDB;

ALTER TABLE `iptv_devices` ADD COLUMN `code` VARCHAR(10) NOT NULL DEFAULT '';

CREATE TABLE `cablecat_coil` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(32) NOT NULL,
  `point_id` int(11) unsigned DEFAULT NULL,
  `cable_id` int(11) unsigned DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Cablecat coil'