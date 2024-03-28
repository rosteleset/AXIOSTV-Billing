CREATE TABLE `users_status` (
  `id`    TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `name`  VARCHAR(40)         NOT NULL DEFAULT '',
  `color` VARCHAR(6)          NOT NULL DEFAULT '',
  `descr` VARCHAR(120)        NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
)
  DEFAULT CHARSET=utf8
  COMMENT='User status list';

REPLACE INTO `users_status` (`id`, `name`, `color`, `descr`) VALUES (0, '$lang{ENABLE}', '4CAF50', '');
REPLACE INTO `users_status` (`id`, `name`, `color`, `descr`) VALUES (1, '$lang{DISABLED}', 'F44336', '');
REPLACE INTO `users_status` (`id`, `name`, `color`, `descr`) VALUES (2, '$lang{NOT_ACTIVE}', 'FF9800', '');
REPLACE INTO `users_status` (`id`, `name`, `color`, `descr`) VALUES (3, '$lang{HOLD_UP}', '2196F3', '');
REPLACE INTO `users_status` (`id`, `name`, `color`, `descr`) VALUES (4, '$lang{DISABLE} $lang{NON_PAYMENT}', '607D8B', '');
REPLACE INTO `users_status` (`id`, `name`, `color`, `descr`) VALUES (5, '$lang{ERR_SMALL_DEPOSIT}', '009688', '');

ALTER TABLE `crm_open_lines` ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `crm_info_fields` ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `crm_tp_info_fields` ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `crm_progressbar_steps` ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `crm_leads_sources` ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `crm_competitors` ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
