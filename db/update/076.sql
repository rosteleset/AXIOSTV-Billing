ALTER TABLE `iptv_main` ADD COLUMN `iptv_login` varchar(32) NOT NULL DEFAULT '';
ALTER TABLE `iptv_main` ADD COLUMN `iptv_password` varchar(32) NOT NULL DEFAULT '';
ALTER TABLE `crm_progressbar_steps` ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `crm_leads_sources` ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `crm_actions` ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `crm_leads` ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `crm_progressbar_step_comments` ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';

