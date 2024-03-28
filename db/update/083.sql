ALTER TABLE `storage_suppliers` ADD COLUMN `location_id` int(11) unsigned NOT NULL DEFAULT '0';
ALTER TABLE `storage_suppliers` ADD COLUMN `district_id` int(11) unsigned NOT NULL DEFAULT '0';
ALTER TABLE `storage_suppliers` ADD COLUMN `street_id` int(11) unsigned NOT NULL DEFAULT '0';
ALTER TABLE `storage_suppliers` ADD COLUMN `build_id` int(11) unsigned NOT NULL DEFAULT '0';

ALTER TABLE `storage_suppliers` ADD COLUMN `comment` varchar(250) DEFAULT '';