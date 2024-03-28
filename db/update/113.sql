ALTER TABLE `crm_leads` ADD `competitor_id` INT(10) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `crm_leads` ADD `tp_id` INT(10) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `crm_leads` ADD `assessment` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0';

ALTER TABLE `crm_leads` ADD KEY competitor_id (`competitor_id`);