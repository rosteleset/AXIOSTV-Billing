ALTER TABLE `crm_competitors` ADD COLUMN `color` VARCHAR(7) NOT NULL DEFAULT '';

ALTER TABLE `equipment_pon_onu` ADD COLUMN `onu_billing_desc` VARCHAR(50) NOT NULL DEFAULT '' AFTER `onu_desc`;
