CREATE TABLE IF NOT EXISTS `cablecat_commutation_onu` (
  `id` INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `service_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `commutation_id` INT(11) UNSIGNED REFERENCES `cablecat_commutations` (`id`) ON DELETE CASCADE,
  `commutation_x` double(6,2) DEFAULT NULL,
  `commutation_y` double(6,2) DEFAULT NULL,
  `commutation_rotation` smallint(6) DEFAULT 0,
  INDEX `_commutation_ik` (`commutation_id`),
  INDEX `_uid_ik` (`uid`),
  INDEX `_service_ik` (`service_id`)
)

  COMMENT = 'Stores onu existance on commutation';


ALTER TABLE admins ADD `g2fa` VARCHAR(255) NOT NULL DEFAULT '';

ALTER TABLE `msgs_quick_replys` ADD COLUMN `comment` VARCHAR(250) DEFAULT '';