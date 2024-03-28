ALTER TABLE `crm_leads` ADD `build_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `crm_leads` ADD `address_flat` VARCHAR(10) NOT NULL DEFAULT '';

ALTER TABLE `tags` ADD `color` VARCHAR(7) NOT NULL DEFAULT '';
ALTER TABLE `internet_log` ADD `guest` TINYINT(1) UNSIGNED  NOT NULL DEFAULT '0';

DELETE i FROM equipment_infos i LEFT JOIN nas n ON i.nas_id = n.id WHERE n.id IS NULL;
DELETE p FROM equipment_pon_ports p LEFT JOIN equipment_infos i ON p.nas_id = i.nas_id WHERE i.nas_id IS NULL;
DELETE onu FROM equipment_pon_onu onu LEFT JOIN equipment_pon_ports p ON onu.port_id = p.id WHERE p.id IS NULL;
DELETE tr_069 FROM equipment_tr_069_settings tr_069 LEFT JOIN equipment_pon_onu onu ON tr_069.onu_id = onu.id WHERE onu.id IS NULL;
DELETE p FROM equipment_ports p LEFT JOIN equipment_infos i ON p.nas_id = i.nas_id WHERE i.nas_id IS NULL;
UPDATE equipment_ports p LEFT JOIN equipment_infos i ON p.uplink = i.nas_id SET p.uplink = 0 WHERE i.nas_id IS NULL AND p.uplink <> 0;
DELETE ml FROM equipment_mac_log ml LEFT JOIN equipment_infos i ON ml.nas_id = i.nas_id WHERE i.nas_id IS NULL;
DELETE pl FROM equipment_ping_log pl LEFT JOIN equipment_infos i ON pl.nas_id = i.nas_id WHERE i.nas_id IS NULL;
DELETE g FROM equipment_graphs g LEFT JOIN equipment_infos i ON g.nas_id = i.nas_id WHERE i.nas_id IS NULL;
DELETE b FROM equipment_backup b LEFT JOIN equipment_infos i ON b.nas_id = i.nas_id WHERE i.nas_id IS NULL;
