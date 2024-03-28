ALTER TABLE `cams_folder` ADD COLUMN `subfolder_id` VARCHAR(32) NOT NULL DEFAULT '' COMMENT 'External folder ID for syncronization';
CREATE TABLE IF NOT EXISTS `paysys_merchant_settings` (
  `id` TINYINT(4) UNSIGNED NOT NULL AUTO_INCREMENT,
  `merchant_name` VARCHAR(40) NOT NULL DEFAULT '',
  `system_id` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY `id`(`id`),
  FOREIGN KEY (`system_id`) REFERENCES `paysys_connect` (`id`) ON DELETE CASCADE
)
  CHARSET = 'utf8'
  COMMENT = 'Paysys merchant settings';

CREATE TABLE IF NOT EXISTS `paysys_merchant_params` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `param`     VARCHAR(50)          NOT NULL DEFAULT '',
  `value`     VARCHAR(400)         NOT NULL DEFAULT '',
  `merchant_id` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY `id`(`id`),
  FOREIGN KEY (`merchant_id`) REFERENCES `paysys_merchant_settings` (`id`) ON DELETE CASCADE
)
  CHARSET = 'utf8'
  COMMENT = 'Paysys merchant params';

CREATE TABLE IF NOT EXISTS `paysys_merchant_to_groups_settings` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `gid` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `paysys_id` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `merch_id`  TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY `id` (`id`),
  FOREIGN KEY (`merch_id`) REFERENCES `paysys_merchant_settings` (`id`) ON DELETE CASCADE
)
  CHARSET = 'utf8'
  COMMENT = 'Settings for each group';