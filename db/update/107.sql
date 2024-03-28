ALTER TABLE `iptv_users_screens` ADD COLUMN `comment` VARCHAR(250) DEFAULT '';

ALTER TABLE `msgs_messages` ADD COLUMN `plan_interval` SMALLINT(6) DEFAULT 0;
ALTER TABLE `msgs_messages` ADD COLUMN `plan_position` SMALLINT(6) DEFAULT 0;