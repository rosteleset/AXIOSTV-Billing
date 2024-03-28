ALTER TABLE `admin_settings` ADD COLUMN `sort_table` VARCHAR(30) NOT NULL DEFAULT '';
ALTER TABLE `tarif_plans` ADD COLUMN `describe_aid` VARCHAR(250) NOT NULL DEFAULT '';

ALTER TABLE `accident_address` ADD KEY `address_id` (`address_id`);
ALTER TABLE `accident_address` ADD KEY `type_id` (`type_id`);