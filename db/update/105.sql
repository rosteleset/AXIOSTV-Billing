ALTER TABLE `employees_coming_types` ADD COLUMN `default_coming` TINYINT(3) UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `employees_cashboxes` ADD COLUMN `aid` INT(11) UNSIGNED                 NOT NULL DEFAULT 0;

ALTER TABLE `equipment_models` DROP COLUMN `snmp_port_shift`;
