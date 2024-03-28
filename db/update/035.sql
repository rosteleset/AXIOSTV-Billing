ALTER TABLE equipment_models ADD COLUMN `height_units` SMALLINT(3) UNSIGNED NOT NULL DEFAULT 1;
ALTER TABLE equipment_models ADD COLUMN `width_units` SMALLINT(3) UNSIGNED NOT NULL DEFAULT 1;
ALTER TABLE equipment_models ADD COLUMN `rows` SMALLINT(3) UNSIGNED NOT NULL DEFAULT 1;

CREATE TABLE IF NOT EXISTS equipment_models_custom(
  `nas_id` SMALLINT(6) UNSIGNED NOT NULL,
  `model_id` SMALLINT(6) UNSIGNED NOT NULL,
  `geometry_json` TEXT
);

ALTER TABLE `equipment_models` ADD COLUMN `geometry_json` TEXT;
CREATE TABLE IF NOT EXISTS equipment_plates (
  `id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 1,
  `height_units` SMALLINT(3) UNSIGNED NOT NULL DEFAULT 1,
  `width_units` SMALLINT(3) UNSIGNED NOT NULL DEFAULT 1,
  `ports` SMALLINT(3) UNSIGNED NOT NULL DEFAULT 1,
  `port_type` SMALLINT(3) UNSIGNED NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS equipment_model_plates (
  `model_id` SMALLINT(6) UNSIGNED NOT NULL,
  `plate_id` SMALLINT(6) UNSIGNED NOT NULL
);

ALTER TABLE `users_pi` ADD COLUMN `floor` SMALLINT(3) UNSIGNED NOT NULL;
ALTER TABLE `users_pi` ADD COLUMN `entrance` SMALLINT(3) UNSIGNED NOT NULL;
ALTER TABLE `users_pi` ADD COLUMN `birth_date` DATE NOT NULL DEFAULT '0000-00-00';
ALTER TABLE `users_pi` ADD COLUMN `reg_address` TEXT;


ALTER TABLE `internet_online` ADD COLUMN `delegated_ipv6_prefix` VARBINARY(16) NOT NULL DEFAULT '';
ALTER TABLE `internet_main` ADD COLUMN `ipv6_mask` tinyint(1) unsigned NOT NULL DEFAULT 0;
ALTER TABLE `internet_main` ADD COLUMN `ipv6_prefix_mask` tinyint(1) unsigned NOT NULL DEFAULT 0;


ALTER TABLE `bonus_service_discount` ADD COLUMN `comments` TEXT NOT NULL;
ALTER TABLE `bonus_service_discount` ADD COLUMN `tp_id` VARCHAR(200) NOT NULL DEFAULT '';
