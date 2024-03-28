ALTER TABLE `ippools` ADD COLUMN `ip_skip` MEDIUMTEXT NULL;

CREATE TABLE IF NOT EXISTS `gps_admins_color` (
   `id` SMALLINT(6) NOT NULL AUTO_INCREMENT PRIMARY KEY,
   `aid` SMALLINT(6) UNSIGNED NOT NULL UNIQUE REFERENCES `admins` (`aid`),
   `color` VARCHAR(7) NOT NULL DEFAULT '#0000FF',
   UNIQUE KEY (`aid`)
)

ALTER TABLE `cams_main` ADD COLUMN `expire` DATE NOT NULL DEFAULT '0000-00-00';

ALTER TABLE `gps_admins_color` ADD COLUMN `show_admin` INT NOT NULL DEFAULT 1;