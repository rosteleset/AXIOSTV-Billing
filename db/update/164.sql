ALTER TABLE `referral_requests` ADD COLUMN `location_id` INT(11) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `referral_requests` ADD COLUMN `address_flat` VARCHAR(10) NOT NULL DEFAULT '';
ALTER TABLE `referral_requests` ADD COLUMN `comments` VARCHAR(100) NOT NULL DEFAULT '';

ALTER TABLE `users_status` MODIFY COLUMN `id` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0';

ALTER TABLE `crm_progressbar_steps` ADD COLUMN `deal_step` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `tasks_main` ADD COLUMN `deal_id` INT(10) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `crm_progressbar_step_comments` ADD COLUMN `deal_id` INT(10) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `crm_progressbar_step_comments` DROP KEY `lead_id`;
ALTER TABLE `crm_progressbar_step_comments` ADD UNIQUE (`lead_id`, `deal_id`, `date`);
CREATE TABLE IF NOT EXISTS `crm_sections` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `title` VARCHAR(60) NOT NULL DEFAULT '',
  `deal_section` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Info sections';

CREATE TABLE IF NOT EXISTS `crm_section_fields` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `fields` TEXT NOT NULL,
  `section_id` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `admin_panel` (`aid`, `section_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Leads fields to show';

REPLACE INTO `events_group` (`id`, `name`, `modules`) VALUES (1, 'BASE', 'Events,Msgs,Paysys,SYSTEM');
