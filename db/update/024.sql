ALTER TABLE `msgs_chapters` ADD COLUMN `autoclose` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `cablecat_cable_types` ADD COLUMN `attenuation` DOUBLE NOT NULL DEFAULT 0;

REPLACE INTO `events_group` (`id`, `name`, `modules`) VALUES (3, 'EQUIPMENT', 'Equipment, Cablecat');

CREATE TABLE IF NOT EXISTS `events_admin_group`(
  `aid` SMALLINT(6) UNSIGNED NOT NULL
    REFERENCES `admins`(`aid`),
  `group_id` SMALLINT(6) UNSIGNED NOT NULL
    REFERENCES `events_group` (`id`),
  UNIQUE `_aid_group` (`aid`, `group_id`)
);

ALTER TABLE internet_online ADD COLUMN `service_id` INT(11) UNSIGNED NOT NULL DEFAULT '0';

REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (8, '$lang{EQUIPMENT}', 'nas_green');
CREATE TABLE IF NOT EXISTS `employees_vacations` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `start_date` DATE NOT NULL DEFAULT '0000-00-00',
  `end_date` DATE NOT NULL DEFAULT '0000-00-00'
)
  COMMENT = 'Employees vacations';

ALTER TABLE `hotspot_advert_pages` MODIFY COLUMN `action` VARCHAR(20) NOT NULL DEFAULT '';
ALTER TABLE `hotspot_log` ADD COLUMN `hotspot` VARCHAR(20) NOT NULL DEFAULT '';