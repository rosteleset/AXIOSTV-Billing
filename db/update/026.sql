CREATE TABLE IF NOT EXISTS  `employees_duty` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `start_date` DATE NOT NULL DEFAULT '0000-00-00',
  `duration` INT NOT NULL DEFAULT 0
)
  COMMENT = 'Employees duty';

ALTER TABLE `reports_wizard` ADD COLUMN `quick_report` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `abon_user_list` ADD COLUMN `fees_period` smallint(4) unsigned DEFAULT 0;

