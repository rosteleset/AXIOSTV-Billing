ALTER TABLE `portal_articles` ADD COLUMN `domain_id` SMALLINT(4) NOT NULL DEFAULT 0;

ALTER TABLE `events` ADD COLUMN `title` VARCHAR(32) NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS `crm_progressbar_step_comments` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `step_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `lead_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `message` TEXT NOT NULL,
  `date` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) COMMENT = 'Comments for each step in progressbar';

ALTER TABLE `msgs_quick_replys` ADD COLUMN  `color` varchar(7) NOT NULL default '';

ALTER TABLE `crm_leads` ADD COLUMN `responsible` SMALLINT(4) NOT NULL DEFAULT 0;

ALTER TABLE `crm_progressbar_steps` ADD COLUMN `color` VARCHAR(7) NOT NULL DEFAULT '';