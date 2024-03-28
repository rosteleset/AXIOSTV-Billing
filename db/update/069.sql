ALTER TABLE `cams_streams` ADD COLUMN `angel` int(11) unsigned NOT NULL DEFAULT '0';
ALTER TABLE `cams_streams` ADD COLUMN `length` int(11) unsigned NOT NULL DEFAULT '0';
ALTER TABLE `cams_streams` ADD COLUMN `location_angel` int(11) unsigned NOT NULL DEFAULT '0';
ALTER TABLE `storage_installation` ADD COLUMN `actual_sell_price` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00';