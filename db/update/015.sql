ALTER TABLE `crm_leads` ADD COLUMN `source` int(1) NOT NULL DEFAULT 0;
ALTER TABLE `crm_leads` ADD COLUMN `date` DATE NOT NULL DEFAULT CURRENT_TIMESTAMP;
REPLACE INTO `events_group` (`id`, `name`, `modules`) VALUES (2, 'CLIENTS', 'Events,Msgs,SYSTEM');
INSERT INTO `config` (`param`, `value`, `domain_id`) VALUES ('_ORGANIZATION_LOCATION_ID', '', 0);

ALTER TABLE `msgs_dispatch` ADD COLUMN `category` int(11) unsigned NOT NULL DEFAULT '0';

CREATE TABLE IF NOT EXISTS `msgs_dispatch_category` (
  `id`   int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(30) NOT NULL,
  PRIMARY KEY (`id`)
)
  COMMENT='Messages dispatch category';

CREATE TABLE IF NOT EXISTS `msgs_quick_replys_types` (
  `id`   SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL DEFAULT '',
  PRIMARY KEY(`id`)
)
COMMENT = 'Quick replys types';

CREATE TABLE IF NOT EXISTS `msgs_quick_replys` (
 `id`      SMALLINT(6)  UNSIGNED NOT NULL AUTO_INCREMENT,
 `reply`   VARCHAR(250) NOT NULL DEFAULT '',
 `type_id` SMALLINT(6),
  PRIMARY KEY(`id`)
)
COMMENT = 'Quick replys';

CREATE TABLE IF NOT EXISTS `msgs_quick_replys_tags` (
 `quick_reply_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
 `msg_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
    KEY `msg_id` (`msg_id`)
)
COMMENT = 'Quick replys msgs tags';

ALTER TABLE `cablecat_wells` ADD COLUMN `connecter_type_id` SMALLINT(6) UNSIGNED REFERENCES `cablecat_connecter_types` (`id`)
  ON DELETE RESTRICT;

START TRANSACTION;
ALTER TABLE `cablecat_wells` ADD COLUMN `old_connecter_id` SMALLINT(6) UNSIGNED;

INSERT INTO `cablecat_wells` (`name`, `type_id`, `parent_id`, `connecter_type_id`, `point_id`, `old_connecter_id`)
  (SELECT `name`, 2, `well_id`, `type_id`, `point_id`, `id` FROM `cablecat_connecters`);

UPDATE `cablecat_commutations` SET connecter_id=(SELECT id FROM cablecat_wells WHERE `old_connecter_id`=`connecter_id`);
UPDATE `cablecat_commutation_cables` SET connecter_id=(SELECT id FROM cablecat_wells WHERE `old_connecter_id`=`connecter_id`);
UPDATE `cablecat_connecters_links` SET connecter_1=(SELECT id FROM cablecat_wells WHERE `old_connecter_id`=`connecter_1`);
UPDATE `cablecat_connecters_links` SET connecter_2=(SELECT id FROM cablecat_wells WHERE `old_connecter_id`=`connecter_2`);

ALTER TABLE `cablecat_wells` DROP COLUMN `old_connecter_id`;

DROP TABLE `cablecat_connecters`;

COMMIT;
