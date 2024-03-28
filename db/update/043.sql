ALTER TABLE `storage_sn` ADD COLUMN `sn_comments` TEXT;

ALTER TABLE `tasks_main` CHANGE COLUMN `resposible` `responsible` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `tasks_admins` CHANGE COLUMN `resposible` `responsible` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0';

CREATE TABLE IF NOT EXISTS `tasks_plugins` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `enable` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `name` VARCHAR(60) NOT NULL DEFAULT '',
  `descr` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  COMMENT = 'Tasks plugins';