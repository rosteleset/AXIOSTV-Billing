ALTER TABLE `cablecat_coil` ADD COLUMN `length` INT NOT NULL DEFAULT 30;

ALTER TABLE `cablecat_wells` MODIFY `name` VARCHAR(60) NOT NULL;

REPLACE INTO `admin_permits` (`aid`, `section`, `actions`) SELECT aid, 0, 28 FROM `admins` WHERE aid > 3;
REPLACE INTO `admin_permits` (`aid`, `section`, `actions`) SELECT aid, 0, 29 FROM `admins` WHERE aid > 3;

ALTER TABLE `crm_works` ADD COLUMN `work_done` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0';

ALTER TABLE `tarif_plans` ADD COLUMN `status` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0';

ALTER TABLE `docs_invoice_orders` ADD COLUMN `type_fees_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';

CREATE TABLE `tp_geolocation`
(
  `tp_gid`       SMALLINT(5) UNSIGNED DEFAULT '0' NOT NULL,
  `district_id` SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL,
  `street_id`   SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL,
  `build_id`    SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL
)
  COMMENT 'Geolocation of the tariff plan'
  ENGINE = InnoDB;
