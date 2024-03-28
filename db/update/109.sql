ALTER TABLE `equipment_models` ADD COLUMN `fdb_uses_port_number_index` TINYINT(1) NOT NULL DEFAULT 0 AFTER `auto_port_shift`;
UPDATE equipment_models SET fdb_uses_port_number_index = 1 WHERE id = 185;
UPDATE equipment_models SET fdb_uses_port_number_index = 1 WHERE id = 297;

ALTER TABLE `events`
  MODIFY COLUMN `extra` varchar(256) NOT NULL DEFAULT '';