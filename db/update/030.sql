ALTER TABLE `cablecat_cable_types` ADD COLUMN `can_be_splitted` TINYINT(1) NOT NULL DEFAULT 1;
ALTER TABLE `streets` ADD COLUMN `type` TINYINT(1) NOT NULL DEFAULT '0';

REPLACE INTO `service_status` (`id`, `name`, `color`, `type`, `get_fees`) VALUES (10, '$lang{TRAF_LIMIT}', '9F9F9F', 0, 0);

