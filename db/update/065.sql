ALTER TABLE cams_streams ADD COLUMN `coordx` double(20,14) NOT NULL DEFAULT '0.00000000000000';
ALTER TABLE cams_streams ADD COLUMN `coordy` double(20,14) NOT NULL DEFAULT '0.00000000000000';
ALTER TABLE cams_streams ADD COLUMN `transport` tinyint(1) unsigned NOT NULL DEFAULT '0';
ALTER TABLE cams_streams ADD COLUMN `sound` tinyint(1) unsigned NOT NULL DEFAULT '0';
ALTER TABLE cams_streams ADD COLUMN `limit_archive` tinyint(1) unsigned NOT NULL DEFAULT '0';
ALTER TABLE cams_streams ADD COLUMN `pre_image` tinyint(1) unsigned NOT NULL DEFAULT '0';
ALTER TABLE cams_streams ADD COLUMN `constantly_working` tinyint(1) unsigned NOT NULL DEFAULT '0';
ALTER TABLE cams_streams ADD COLUMN `archive` tinyint(1) unsigned NOT NULL DEFAULT '0';
ALTER TABLE cams_streams ADD COLUMN `only_video` tinyint(1) unsigned NOT NULL DEFAULT '0';
ALTER TABLE cams_streams ADD COLUMN `pre_image_url` varchar(128) NOT NULL DEFAULT '';
ALTER TABLE cams_streams ADD COLUMN `point_id` int(11) unsigned DEFAULT NULL;

ALTER TABLE cams_groups MODIFY `build_id` smallint(6) unsigned;
ALTER TABLE cams_groups MODIFY `street_id` smallint(6) unsigned;
ALTER TABLE cams_groups MODIFY `district_id` smallint(6) unsigned;
ALTER TABLE cams_groups MODIFY `location_id` smallint(6) unsigned;