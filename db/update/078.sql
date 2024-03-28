ALTER TABLE `crm_leads` MODIFY COLUMN  `current_step` int NOT NULL DEFAULT 1;
ALTER TABLE `crm_progressbar_steps` MODIFY COLUMN  `step_number` INT UNSIGNED NOT NULL DEFAULT 1;