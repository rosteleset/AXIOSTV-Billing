CREATE TABLE IF NOT EXISTS `paysys_groups_settings` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `gid` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `paysys_id` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  UNIQUE KEY `id` (`id`)
)
  COMMENT = 'Settings for each group';

CREATE TABLE IF NOT EXISTS `users_contracts` (
  `id` SMALLINT(5) unsigned NOT NULL AUTO_INCREMENT,
  `parrent_id` SMALLINT(5) unsigned NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `company_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `number` VARCHAR(40) NOT NULL DEFAULT '',
  `name` VARCHAR(120) NOT NULL DEFAULT '',
  `date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `type` SMALLINT(3) NOT NULL DEFAULT '0',
  `reg_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `aid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `signature` TEXT,
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Contracts';

ALTER TABLE equipment_mac_log ADD COLUMN port_name VARCHAR(50) NOT NULL DEFAULT '';
ALTER TABLE equipment_mac_log CHANGE COLUMN port port VARCHAR(50) COLLATE utf8_general_ci DEFAULT '';


CREATE TABLE IF NOT EXISTS `cablecat_commutation_crosses` (
  `commutation_id` INT(11) UNSIGNED REFERENCES `cablecat_commutations` (`id`)
    ON DELETE CASCADE,
  `cross_id` INT(11) UNSIGNED REFERENCES `cablecat_crosses` (`id`)
    ON DELETE CASCADE,
  `port_start` SMALLINT(6) UNSIGNED NOT NULL,
  `port_finish` SMALLINT(6) UNSIGNED NOT NULL,
  `commutation_x` DOUBLE(5, 2) NULL,
  `commutation_y` DOUBLE(5, 2) NULL,
  `commutation_rotation` SMALLINT NOT NULL DEFAULT 0,
  INDEX `_cross_commutation` (`commutation_id`, `cross_id`)
)
  COMMENT = 'Stores information about cross on commutation links and images';

CREATE TABLE IF NOT EXISTS `cablecat_cross_links` (
  `cross_id` INT(11) UNSIGNED REFERENCES `cablecat_crosses` (`id`)
    ON DELETE CASCADE,
  `cross_port` INT(6) UNSIGNED NOT NULL,
  `link_type` SMALLINT(3) UNSIGNED NOT NULL,
  `link_value` VARCHAR(32) NOT NULL DEFAULT '',
  UNIQUE `_cross_port` (`cross_id`, `cross_port`)
)
  COMMENT = 'Logical values for port connection';

