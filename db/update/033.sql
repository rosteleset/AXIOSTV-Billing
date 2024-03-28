ALTER TABLE `hotspot_log` CHANGE COLUMN `id` `id` INT(8) UNSIGNED NOT NULL AUTO_INCREMENT;

CREATE TABLE IF NOT EXISTS `contracts_type` (
  `id` SMALLINT(5) unsigned NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(120) NOT NULL DEFAULT '',
  `template` VARCHAR(40) NOT NULL DEFAULT '',
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Contracts type';

DELETE FROM events_state WHERE id=4;
REPLACE INTO `events_state` VALUES
  (1, '_{NEW}_'),
  (2, '_{SEEN}_'),
  (3, '_{CLOSED}_')
;

REPLACE INTO `events_priority` VALUES
  (1, '_{VERY_LOW}_', 0),
  (2, '_{LOW}_', 1),
  (3, '_{NORMAL}_', 2),
  (4, '_{HIGH}_', 3),
  (5, '_{CRITICAL}_', 4);

REPLACE INTO `events_privacy` VALUES
  (1, '_{ALL}_', 0),
  (2, '_{ADMIN}_ _{GROUP}_', 1),
  (3, '_{ADMIN}_ _{USER}_ _{GROUP}_', 2),
  (4, '_{ADMIN}_ _{GEOZONE}_', 3);

ALTER TABLE `events` ADD COLUMN `aid` SMALLINT UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `internet_main` ADD COLUMN   `ipv6` VARBINARY(16) NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS paysys_connect (
  `id` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `status` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  UNIQUE KEY `id`(`id`)
) COMMENT = 'Paysys connected systems';

ALTER TABLE `events` ADD COLUMN `domain_id` SMALLINT NOT NULL DEFAULT 0;

ALTER TABLE `equipment_models` ADD COLUMN `port_shift` TINYINT(2) NOT NULL DEFAULT '0';
ALTER TABLE `equipment_models` ADD COLUMN `test_firmware` VARCHAR(20) NOT NULL DEFAULT '';

