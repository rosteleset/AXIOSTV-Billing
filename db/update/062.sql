ALTER TABLE `cashbox_spending` ADD COLUMN `admin_spending` INT(11) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `cashbox_coming` ADD COLUMN `uid` INT(11) UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `admins` ADD COLUMN `expire` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00';

REPLACE INTO `admin_permits` (`aid`, `section`, `actions`) SELECT aid, 0, 30 FROM `admins` WHERE aid > 3;

ALTER TABLE `cams_services` ADD COLUMN `login` VARCHAR(72) NOT NULL DEFAULT '';
ALTER TABLE `cams_services` ADD COLUMN `password` BLOB;

ALTER TABLE `admins` ADD COLUMN `rfid_number` VARCHAR(15) NOT NULL DEFAULT '';