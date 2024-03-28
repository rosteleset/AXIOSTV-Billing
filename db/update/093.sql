CREATE TABLE IF NOT EXISTS `accident_compensation` (
    `id`             SMALLINT(3) UNSIGNED AUTO_INCREMENT
        PRIMARY KEY,
    `procent`        FLOAT       UNSIGNED NOT NULL DEFAULT 0.0,
    `date`           DATE                 NOT NULL DEFAULT '0000-00-00',
    `service`        SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,
    `type_id`        SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,
    `address_id`     SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0
) 
    DEFAULT CHARSET = utf8
    COMMENT = 'Accident address';

ALTER TABLE `cablecat_crosses`  ADD COLUMN `color_scheme_id` INT(11) UNSIGNED NOT NULL DEFAULT '0';

ALTER TABLE `shedule` DROP KEY `uniq_action`;
ALTER TABLE `shedule` ADD UNIQUE KEY `uniq_action` (`h`, `d`, `m`, `y`, `type`, `uid`, `module`, `action`(255));

ALTER TABLE `cablecat_splitters`  ADD COLUMN `attenuation` VARCHAR(64) NOT NULL DEFAULT '';

ALTER TABLE `cablecat_cables` MODIFY `name` VARCHAR(128) NOT NULL;
ALTER TABLE `cablecat_wells` MODIFY `name` VARCHAR(64) NOT NULL;