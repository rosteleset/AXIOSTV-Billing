ALTER TABLE `ippools` ADD COLUMN `guest` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `ippools` ADD COLUMN `domain_id` smallint(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `dhcphosts_networks` ADD COLUMN `domain_id` smallint(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `iptv_services` ADD COLUMN `subscribe_count` TINYINT(2) UNSIGNED NOT NULL DEFAULT 1;


ALTER TABLE `cablecat_links` ADD COLUMN `uid` INT(11) UNSIGNED REFERENCES `users` (`uid`);
ALTER TABLE `cablecat_links` DROP COLUMN `linked_to`;
ALTER TABLE `cablecat_links` DROP COLUMN `connecter_id`;
ALTER TABLE `cablecat_links` ADD COLUMN `splitter_port` SMALLINT(6) UNSIGNED;
ALTER TABLE `cablecat_links` ADD COLUMN `splitter_direction` TINYINT(1) UNSIGNED;


CREATE TABLE IF NOT EXISTS `cablecat_well_types`(
  `id` SMALLINT(6) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(32) NOT NULL DEFAULT '',
  `icon` VARCHAR(120) NOT NULL DEFAULT 'well_green',
  `comments` TEXT
);
REPLACE INTO `cablecat_well_types`(`id`, `name`) VALUES (1, '$lang{WELL}');
ALTER TABLE `cablecat_wells` ADD COLUMN `type_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 1;

ALTER TABLE `cablecat_wells` ADD CONSTRAINT `_well_type_id` FOREIGN KEY `cablecat_wells`(`type_id`) REFERENCES `cablecat_well_types`(`id`)
ON DELETE RESTRICT;



