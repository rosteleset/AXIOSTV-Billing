# Comment

ALTER TABLE `shedule` ADD KEY uid (uid);

CREATE TABLE IF NOT EXISTS `storage_inner_use` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `storage_incoming_articles_id` INT(10) UNSIGNED DEFAULT '0',
  `count` INT(10) UNSIGNED DEFAULT '0',
  `aid` INT(10) UNSIGNED DEFAULT '0',
  `date` DATETIME DEFAULT NULL,
  `sum` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `comments` TEXT,
  PRIMARY KEY (`id`),
  KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`)
);

CREATE TABLE IF NOT EXISTS `crm_actions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` char(40) NOT NULL DEFAULT '',
  `action` TEXT NOT NULL,
  PRIMARY KEY (`id`)
) COMMENT = 'Actions for leads';

ALTER TABLE `crm_progressbar_step_comments` ADD COLUMN `action_id` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `crm_progressbar_step_comments` ADD COLUMN `status` SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `crm_progressbar_step_comments` ADD COLUMN `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `crm_progressbar_step_comments` ADD COLUMN `planned_date` DATE NOT NULL DEFAULT '0000-00-00';

ALTER TABLE `builds` ADD COLUMN `numbering_direction` tinyint(1) unsigned NOT NULL default '0';

ALTER TABLE `billd_plugins` ADD COLUMN `last_end` DATETIME NOT NULL;
ALTER TABLE `billd_plugins` MODIFY COLUMN `last_execute` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE `fees_types` ADD COLUMN `tax` DOUBLE(10, 2) NOT NULL DEFAULT '0.00';
ALTER TABLE `docs_invoice_orders` ADD COLUMN `fees_type` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;
