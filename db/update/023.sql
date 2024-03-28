ALTER TABLE `crm_leads` ADD COLUMN `priority` SMALLINT(1) UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `crm_progressbar_step_comments` ADD UNIQUE (`lead_id`, `date`);

ALTER TABLE `crm_leads` MODIFY `phone` VARCHAR(120) NOT NULL DEFAULT '';