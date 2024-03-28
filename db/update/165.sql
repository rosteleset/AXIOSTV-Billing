ALTER TABLE `sqlcmd_history` ADD COLUMN `status` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0';

ALTER TABLE `portal_articles` ADD COLUMN `permalink` VARCHAR(255) DEFAULT NULL;
ALTER TABLE `portal_articles` ADD UNIQUE KEY `permalink` (`permalink`);

ALTER TABLE `tasks_main` ADD COLUMN `closed_date` DATE NOT NULL DEFAULT '0000-00-00';
ALTER TABLE `crm_progressbar_step_comments` ADD COLUMN `plan_time` TIME NOT NULL DEFAULT '00:00:00';
ALTER TABLE `crm_progressbar_step_comments` ADD COLUMN `plan_interval` SMALLINT(6) UNSIGNED NOT NULL  DEFAULT '0';

CREATE TABLE IF NOT EXISTS `portal_newsletters`
(
  `id`                INT(10)     UNSIGNED NOT NULL AUTO_INCREMENT,
  `portal_article_id` INT(10)     UNSIGNED NOT NULL DEFAULT 0,
  `send_method`       TINYINT(2)  UNSIGNED NOT NULL DEFAULT 0,
  `status`            TINYINT(1)  UNSIGNED NOT NULL DEFAULT 0,
  `sent`              INT(10)     UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `portal_article_id` (`portal_article_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Portal newsletters';
A