ALTER TABLE `admin_settings` MODIFY COLUMN `object` VARCHAR(48) NOT NULL DEFAULT '';
ALTER TABLE `equipment_infos` ADD COLUMN `server_vlan` smallint(6) unsigned NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `employees_daily_notes` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `day` DATE NOT NULL DEFAULT '0000-00-00',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT NOT NULL
)
  COMMENT = 'Admins daily notes';
  
CREATE TABLE IF NOT EXISTS `hotspot_advert_pages` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `hostname` VARCHAR(20) NOT NULL DEFAULT '',
  `page` TEXT,
  `action` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',

  PRIMARY KEY (`id`)
) 
  COMMENT = 'Hotspot advert pages';