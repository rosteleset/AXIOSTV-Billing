INSERT INTO `equipment_types` (`name`) VALUES ('Cams');
ALTER TABLE `equipment_models` ADD UNIQUE KEY `model` (`vendor_id`, `type_id`, `model_name`);