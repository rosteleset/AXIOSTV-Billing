ALTER TABLE equipment_mac_log ADD PRIMARY KEY(id);
ALTER TABLE equipment_mac_log DROP INDEX id;

ALTER TABLE `cablecat_commutation_cables` ADD COLUMN `commutation_x` double(6,2) DEFAULT NULL;
ALTER TABLE `cablecat_commutation_cables` ADD COLUMN `commutation_y` double(6,2) DEFAULT NULL;
ALTER TABLE `cablecat_commutation_cables` ADD COLUMN `id` INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE `cablecat_commutation_cables` ADD COLUMN `position` VARCHAR(10) NOT NULL DEFAULT '';

ALTER TABLE equipment_models ADD COLUMN epon_supported_onus SMALLINT(4) UNSIGNED;
ALTER TABLE equipment_models ADD COLUMN gpon_supported_onus SMALLINT(4) UNSIGNED;
ALTER TABLE equipment_models ADD COLUMN gepon_supported_onus SMALLINT(4) UNSIGNED;
UPDATE equipment_models SET gpon_supported_onus = 64 WHERE id = 262;
