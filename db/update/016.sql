ALTER TABLE `users_contacts` MODIFY COLUMN `value` VARCHAR(128) NOT NULL;
ALTER TABLE `admins_contacts` MODIFY COLUMN `value` VARCHAR(128) NOT NULL;

ALTER TABLE `companies` ADD COLUMN `location_id` int(11) unsigned NOT NULL DEFAULT '0';
ALTER TABLE `companies` ADD COLUMN `address_flat` varchar(10) NOT NULL DEFAULT '';
ALTER TABLE `ippools`    ADD COLUMN `vlan` smallint(2) unsigned not null default 0;
ALTER TABLE `equipment_ports`    ADD COLUMN `vlan` smallint(2) unsigned not null default 0;
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (12, '$lang{BUILD} POLYGON', 'POLYGON', 'build');

ALTER TABLE `builds` DROP COLUMN `map_x`;
ALTER TABLE `builds` DROP COLUMN `map_y`;
ALTER TABLE `builds` DROP COLUMN `map_x2`;
ALTER TABLE `builds` DROP COLUMN `map_y2`;
ALTER TABLE `builds` DROP COLUMN `map_x3`;
ALTER TABLE `builds` DROP COLUMN `map_y3`;
ALTER TABLE `builds` DROP COLUMN `map_x4`;
ALTER TABLE `builds` DROP COLUMN `map_y4`;

