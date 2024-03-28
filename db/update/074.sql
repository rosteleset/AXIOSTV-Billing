ALTER TABLE `employees_department` ADD COLUMN `positions` VARCHAR(25) NOT NULL DEFAULT '';

ALTER TABLE `cams_main` ADD COLUMN `subscribe_id` VARCHAR(32) NOT NULL DEFAULT '' COMMENT 'External service ID for syncronization';

ALTER TABLE `cams_groups` MODIFY COLUMN `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
ALTER TABLE `cams_groups` MODIFY COLUMN `location_id` int(11) unsigned NOT NULL DEFAULT '0';
ALTER TABLE `cams_groups` MODIFY COLUMN `district_id` int(11) unsigned NOT NULL DEFAULT '0';
ALTER TABLE `cams_groups` MODIFY COLUMN `street_id` int(11) unsigned NOT NULL DEFAULT '0';
ALTER TABLE `cams_groups` MODIFY COLUMN `build_id` int(11) unsigned NOT NULL DEFAULT '0';
ALTER TABLE `cams_groups` MODIFY COLUMN `service_id` int(6) unsigned NOT NULL DEFAULT 0;

ALTER TABLE `msgs_unreg_requests` MODIFY COLUMN `phone` varchar(16) NOT NULL DEFAULT '';

ALTER TABLE `cams_groups` ADD COLUMN `subgroup_id` VARCHAR(32) NOT NULL DEFAULT '' COMMENT 'External group ID for syncronization';
ALTER TABLE `cams_streams` ADD COLUMN `number_id` VARCHAR(32) NOT NULL DEFAULT '' COMMENT 'External camera ID for syncronization';