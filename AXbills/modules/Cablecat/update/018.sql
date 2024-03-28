DROP TABLE IF EXISTS `cablecat_links`;
CREATE TABLE IF NOT EXISTS `cablecat_links` (
  `id` INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `commutation_id` INT(6) UNSIGNED NOT NULL,
  `element_1_id` INT(6) UNSIGNED NOT NULL,
  `element_2_id` INT(6) UNSIGNED NOT NULL,
  `element_1_type` VARCHAR(32) NOT NULL,
  `element_2_type` VARCHAR(32) NOT NULL,
  `fiber_num_1` INT(6) UNSIGNED NOT NULL,
  `fiber_num_2` INT(6) UNSIGNED NOT NULL,
  `geometry` TEXT,
  `attenuation` DOUBLE NOT NULL DEFAULT 0,
  `comments` VARCHAR(40) NOT NULL DEFAULT '',
  `direction` TINYINT(1) UNSIGNED,
  INDEX `_links_element_1_key` (`element_1_type`, `element_1_id`),
  INDEX `_links_element_2_key` (`element_2_type`, `element_2_id`),
  INDEX `_links_commutation_key` (`commutation_id`)
)
  CHARSET = utf8
  COMMENT = 'Stores information about fiber links (end_points)';

ALTER TABLE cablecat_commutation_links ADD COLUMN `cable_side_1` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE cablecat_commutation_links ADD COLUMN `cable_side_2` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE cablecat_links ADD COLUMN `element_1_side` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE cablecat_links ADD COLUMN `element_2_side` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `cablecat_commutation_equipment` (
  `id` INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `nas_id` INT(11) UNSIGNED UNIQUE NOT NULL,
  `commutation_id` INT(11) UNSIGNED REFERENCES `cablecat_commutations` (`id`)
    ON DELETE CASCADE,
  `commutation_x` DOUBLE(5, 2) NULL,
  `commutation_y` DOUBLE(5, 2) NULL
)
  COMMENT = 'Stores equipment existance on commutation';