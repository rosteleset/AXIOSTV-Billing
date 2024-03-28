ALTER TABLE `ureports_users_reports` ADD COLUMN `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';


CREATE TABLE IF NOT EXISTS `employees_department` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` char(60) NOT NULL DEFAULT '',
  `comments` TEXT,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Employees departments';

ALTER TABLE `admins` ADD COLUMN `department` SMALLINT(3) UNSIGNED NOT NULL DEFAULT '0';

ALTER TABLE `crm_salaries_payed` ADD COLUMN `spending_id` SMALLINT UNSIGNED NOT NULL DEFAULT '0';