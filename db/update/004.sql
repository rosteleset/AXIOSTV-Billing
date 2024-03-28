CREATE TABLE IF NOT EXISTS `paysys_terminals_types` (
  `id` INT(3) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(40) NOT NULL DEFAULT '',
  `comment` TEXT,
  UNIQUE KEY `id` (`id`)
)
  COMMENT = 'Table for paysys terminals types';

REPLACE INTO `paysys_terminals_types` (`id`, `name`, `comment`) VALUES (1, 'EasyPay', '');
REPLACE INTO `paysys_terminals_types` (`id`, `name`, `comment`) VALUES (2, 'Privatbank', '');

REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (6, '$lang{OBJECT}', 'MARKER', 'custom');

ALTER TABLE `builds`
  MODIFY `coordx` DOUBLE(20, 14) NOT NULL DEFAULT 0;
ALTER TABLE `builds`
  MODIFY `coordy` DOUBLE(20, 14) NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `payments_type` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  `color` VARCHAR(7) NOT NULL DEFAULT '',
  UNIQUE KEY `id` (`id`)
)
  COMMENT = 'Add new payment type';

ALTER TABLE `cams_streams`
  ADD COLUMN `zoneminder_id` INT(11) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `cams_streams`
  CHANGE COLUMN `ip` `host` VARCHAR(255) NOT NULL DEFAULT '0.0.0.0';
ALTER TABLE `cams_streams`
  ADD COLUMN `rtsp_path` TEXT;
ALTER TABLE `cams_streams`
  ADD COLUMN `rtsp_port` SMALLINT(6) NOT NULL DEFAULT 554;

REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (9, '$lang{PILLAR}', 'pillar_green');
ALTER TABLE `maps_points`
  ADD COLUMN `parent_id` INT(11) REFERENCES `maps_points` (`id`)
  ON DELETE RESTRICT;
ALTER TABLE `maps_points`
  ADD COLUMN `planned` TINYINT(1) NOT NULL DEFAULT 0;
ALTER TABLE `maps_points`
  ADD COLUMN `location_id` INT(11) UNSIGNED;
ALTER TABLE `maps_points`
  ADD COLUMN `created` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE `maps_points`
  ADD CONSTRAINT `point_build` FOREIGN KEY `location_id`(`location_id`) REFERENCES `builds` (`id`)
  ON DELETE RESTRICT;
CREATE INDEX `_points_location_id`
  ON `maps_points` (`location_id`);

REPLACE INTO `payments_type` (`id`, `name`, `color`) VALUES
  (0, '$lang{CASH}', ''),
  (1, '$lang{BANK}', ''),
  (2, '$lang{EXTERNAL_PAYMENTS}', ''),
  (3, 'Credit Card', ''),
  (4, '$lang{BONUS}', ''),
  (5, '$lang{CORRECTION}', ''),
  (6, '$lang{COMPENSATION}', ''),
  (7, '$lang{MONEY_TRANSFER}', ''),
  (8, '$lang{RECALCULATE}', '');

ALTER TABLE `msgs_unreg_requests`
  ADD `last_contact` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `msgs_unreg_requests`
  ADD `planned_contact` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `msgs_unreg_requests`
  ADD `contact_note` TEXT NOT NULL;

