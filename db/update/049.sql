ALTER TABLE `bonus_service_discount` ADD COLUMN `name` VARCHAR(100) NOT NULL default '';
ALTER TABLE `cablecat_splitters`  ADD COLUMN `color_scheme_id` INT(11) UNSIGNED NOT NULL DEFAULT '1';

ALTER TABLE `reports_wizard` ADD COLUMN `send_mail` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0';

INSERT INTO `admin_type_permits` (`type`, `section`, `actions`, `module`) VALUES
  ('$lang{ALL} $lang{PERMISSION}', 0, 12, ''),
  ('$lang{ALL} $lang{PERMISSION}', 0, 13, ''),
  ('$lang{ALL} $lang{PERMISSION}', 0, 18, ''),
  ('$lang{ALL} $lang{PERMISSION}', 3, 6, ''),
  ('$lang{ALL} $lang{PERMISSION}', 3, 7, '');