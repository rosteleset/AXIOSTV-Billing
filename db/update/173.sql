CREATE TABLE IF NOT EXISTS `address_types` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  `position` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Address node types';

CREATE TABLE IF NOT EXISTS `building_types` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Build types';

ALTER TABLE `districts` ADD COLUMN `parent_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `districts` ADD COLUMN `type_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `districts` ADD COLUMN `path` VARCHAR(255) NOT NULL DEFAULT '';
ALTER TABLE `districts` ADD INDEX `idx_path` (`path`);
ALTER TABLE `districts` ADD INDEX `parent_id` (`parent_id`);

ALTER TABLE `builds` ADD COLUMN `type_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `equipment_models` ADD COLUMN `cont_num_extra_ports` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Continuation of numbering for extra port from main row';
