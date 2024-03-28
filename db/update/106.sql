ALTER TABLE `equipment_models` ADD COLUMN `auto_port_shift` TINYINT(1) NOT NULL DEFAULT 0 AFTER `port_shift`;

UPDATE equipment_models SET auto_port_shift = 1 WHERE id = 185;
