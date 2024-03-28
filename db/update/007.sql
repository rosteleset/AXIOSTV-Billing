ALTER TABLE `maps_layers`
  CHANGE `clustering` `markers_in_cluster` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1;

ALTER TABLE `users_social_info`
  ADD COLUMN `friends_count` INT(5) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `users_social_info`
  ADD COLUMN `photo` TEXT;

ALTER TABLE `maps_points`
  MODIFY COLUMN `id` INT(11) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `cablecat_cables`
  MODIFY COLUMN `point_id` INT(11) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `cablecat_cables`
  ADD FOREIGN KEY (`point_id`) REFERENCES `maps_points` (`id`)
  ON DELETE SET NULL;

ALTER TABLE `cablecat_wells`
  MODIFY COLUMN `point_id` INT(11) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `cablecat_wells`
  ADD FOREIGN KEY (`point_id`) REFERENCES `maps_points` (`id`)
  ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS `nas_cmd` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `nas_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `type` VARCHAR(10) NOT NULL DEFAULT 0,
  `comments` TEXT,
  `cmd` TEXT,
  PRIMARY KEY (`id`)
)
  COMMENT = 'Nas console commands';

ALTER TABLE `iptv_main`
  CHANGE COLUMN `subscribe_id` `subscribe_id` VARCHAR(32) NOT NULL DEFAULT '';

ALTER TABLE `maps_polylines`
  ADD COLUMN `length` DOUBLE NOT NULL DEFAULT 0;
ALTER TABLE `cablecat_cables`
  ADD COLUMN `length` DOUBLE NOT NULL DEFAULT 0;
ALTER TABLE `cablecat_cables`
  ADD COLUMN `reserve` DOUBLE NOT NULL DEFAULT 0;

ALTER TABLE `info_documents`
  MODIFY COLUMN `real_name` TEXT;
ALTER TABLE `info_media`
  MODIFY COLUMN `real_name` TEXT;

ALTER TABLE `cablecat_cables`
  DROP COLUMN `comments`;
ALTER TABLE `cablecat_wells`
  DROP COLUMN `planned`;
ALTER TABLE `cablecat_wells`
  DROP COLUMN `created`;
ALTER TABLE `cablecat_wells`
  DROP COLUMN `installed`;
ALTER TABLE `cablecat_connecters`
  DROP COLUMN `planned`;
ALTER TABLE `cablecat_connecters`
  DROP COLUMN `created`;
ALTER TABLE `cablecat_connecters`
  DROP COLUMN `installed`;
ALTER TABLE `cablecat_splitters`
  DROP COLUMN `planned`;
ALTER TABLE `cablecat_splitters`
  DROP COLUMN `created`;
ALTER TABLE `cablecat_splitters`
  DROP COLUMN `installed`;
ALTER TABLE `cablecat_splitters`
  ADD COLUMN `point_id` INT(11) UNSIGNED REFERENCES `maps_points` (`id`)
  ON DELETE RESTRICT;
ALTER TABLE `cablecat_connecters`
  ADD COLUMN `point_id` INT(11) UNSIGNED REFERENCES `maps_points` (`id`)
  ON DELETE RESTRICT;