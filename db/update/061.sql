ALTER TABLE `cams_streams` ADD COLUMN `extra_url` varchar(64) NOT NULL DEFAULT '0.0.0.0';
ALTER TABLE `cams_streams` ADD COLUMN `screenshot_url` varchar(64) NOT NULL DEFAULT '0.0.0.0';
ALTER TABLE `cams_tp` ADD COLUMN `dvr` smallint(6) unsigned DEFAULT 0;
ALTER TABLE `cams_tp` ADD COLUMN `ptz` smallint(6) unsigned DEFAULT 0;

CREATE TABLE IF NOT EXISTS `employees_ext_params` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `phone` VARCHAR(16) NOT NULL DEFAULT '' UNIQUE,
  `sum` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `day_num` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `status` SMALLINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY `id` (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Employees extra parameters';

CREATE TABLE IF NOT EXISTS `employees_mobile_reports` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `phone` VARCHAR(16) NOT NULL DEFAULT '',
  `sum` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `date` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `transaction_id` VARCHAR(24) NOT NULL DEFAULT '',
  `status` SMALLINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY `id` (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Employees mobile reports';

CREATE TABLE IF NOT EXISTS `netblock_ssl` (
  `id` int(10) unsigned NOT NULL DEFAULT 0,
  `ssl_name` varchar(255) NOT NULL DEFAULT '',
  `skip` tinyint(1) NOT NULL DEFAULT '0',
  KEY `id` (`id`),
  FOREIGN KEY (`id`) REFERENCES `netblock_main` (`id`) ON DELETE CASCADE
) COMMENT='Netblock ssl table';

CREATE TABLE IF NOT EXISTS `netblock_ports` (
  `id` int(10) unsigned NOT NULL DEFAULT 0,
  `ports` varchar(255) NOT NULL DEFAULT '',
  `skip` tinyint(1) NOT NULL DEFAULT '0',
  KEY `id` (`id`),
  FOREIGN KEY (`id`) REFERENCES `netblock_main` (`id`) ON DELETE CASCADE
) COMMENT='Netblock ports table';

ALTER TABLE `equipment_models` ADD COLUMN `electric_power` INT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `employees_ext_params` ADD COLUMN `mob_comment` VARCHAR(255) NOT NULL DEFAULT '';

