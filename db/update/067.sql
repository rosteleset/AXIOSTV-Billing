CREATE TABLE IF NOT EXISTS  `storage_admins` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `percent` SMALLINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `aid` (`aid`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Storage admins settings';

ALTER TABLE `storage_suppliers` CHANGE COLUMN `icq` `telegram` VARCHAR(30) NOT NULL DEFAULT '';
ALTER TABLE `storage_accountability` ADD COLUMN `added_by_aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';