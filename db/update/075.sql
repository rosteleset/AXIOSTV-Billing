ALTER TABLE `nas` ADD COLUMN zabbix_hostid INT(11) NOT NULL DEFAULT 0;
ALTER TABLE `notepad` ADD COLUMN `status_st` TINYINT(1)  UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `cams_streams` MODIFY COLUMN `group_id` int(11) unsigned NOT NULL DEFAULT '0';
ALTER TABLE `cams_streams` ADD COLUMN `folder_id` int(11) unsigned NOT NULL DEFAULT '0';

CREATE TABLE IF NOT EXISTS `cams_users_folders` (
  `id` INTEGER(10) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `folder_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `changed` DATETIME NOT NULL,
  UNIQUE KEY `id` (`id`, `folder_id`, `tp_id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Cams users folders';

CREATE TABLE IF NOT EXISTS `cams_folder` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(64) NOT NULL DEFAULT '',
  `comment` varchar(250) DEFAULT '',
  `parent_id` int(6) unsigned NOT NULL DEFAULT 0,
  `group_id` int(6) unsigned NOT NULL DEFAULT 0,
  `service_id` int(6) unsigned NOT NULL DEFAULT 0,
  `location_id` int(11) unsigned NOT NULL DEFAULT '0',
  `district_id` int(11) unsigned NOT NULL DEFAULT '0',
  `street_id` int(11) unsigned NOT NULL DEFAULT '0',
  `build_id` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `title` (`title`)
)
  DEFAULT CHARSET=utf8 COMMENT='Cams Folder';

ALTER TABLE `sharing_users` ADD COLUMN demo TINYINT(3) UNSIGNED NOT NULL DEFAULT '0';
