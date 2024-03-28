ALTER TABLE `cams_streams`
  ADD COLUMN `orientation` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `iptv_main`
  ADD COLUMN `service_id` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0;

SET SESSION sql_mode = 'NO_AUTO_VALUE_ON_ZERO';
REPLACE INTO `msgs_status` (`id`, `name`, `readiness`, `task_closed`, `color`) VALUE
  ('0', '$lang{OPEN}', 0, '0', '#0000FF'),
  ('1', '$lang{CLOSED_UNSUCCESSFUL}', 100, '1', '#ff0638'),
  ('2', '$lang{CLOSED_SUCCESSFUL}', 100, '1', '#009D00'),
  ('3', '$lang{IN_WORK}', 10, '0', '#707070'),
  ('4', '$lang{NEW_MESSAGE}', 0, '0', '#FF8000'),
  ('5', '$lang{HOLD_UP}', 0, 0, '0'),
  ('6', '$lang{ANSWER_WAIT}', 50, '0', ''),
  ('9', '$lang{NOTIFICATION_MSG}', 0, '0', ''),
  ('10', '$lang{NOTIFICATION_MSG}  $lang{READED}', 100, '0', ''),
  ('11', '$lang{POTENTIAL_CLIENT}', 0, '0', '');

CREATE TABLE IF NOT EXISTS `users_social_info` (
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `social_network_id` INT(1) NOT NULL DEFAULT 0,
  `name` VARCHAR(120) NOT NULL DEFAULT '',
  `email` VARCHAR(250) NOT NULL DEFAULT '',
  `birthday` DATE NOT NULL,
  `gender` VARCHAR(15) NOT NULL DEFAULT '',
  `likes` TEXT,
  UNIQUE KEY `uid_sin` (`uid`, `social_network_id`)
)
  COMMENT = 'Info form social networks.';

ALTER TABLE `crm_reference_works`
  ADD COLUMN `units` CHAR(40) NOT NULL DEFAULT '';

ALTER TABLE `crm_reference_works`
  ADD COLUMN `disabled` TINYINT(1) NOT NULL DEFAULT 0;

ALTER TABLE `paysys_main`
  ADD COLUMN `external_user_ip` INT(11) UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `maps_circles`
  ADD COLUMN `object_id` INT(11) REFERENCES `maps_points` (`id`)
  ON DELETE CASCADE;
ALTER TABLE `maps_polygons`
  ADD COLUMN `object_id` INT(11) REFERENCES `maps_points` (`id`)
  ON DELETE CASCADE;
ALTER TABLE `maps_polylines`
  ADD COLUMN `object_id` INT(11) REFERENCES `maps_points` (`id`)
  ON DELETE CASCADE;
ALTER TABLE `maps_text`
  ADD COLUMN `object_id` INT(11) REFERENCES `maps_points` (`id`)
  ON DELETE CASCADE;

ALTER TABLE `cablecat_cables`
  ADD COLUMN `point_id` INT(11) UNSIGNED REFERENCES `maps_points` (`id`) ON DELETE CASCADE;

ALTER TABLE `maps_points`
  ADD COLUMN `external` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;
