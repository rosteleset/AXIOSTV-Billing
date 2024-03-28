CREATE TABLE IF NOT EXISTS `crm_response_templates` (
  `id`                INT(11)       UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`              VARCHAR(60)            NOT NULL DEFAULT '',
  `text`              VARCHAR(255)           NOT NULL DEFAULT '',
  `datetime_change`   DATETIME               NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
)
DEFAULT CHARSET=utf8
COMMENT='Crm list of response templates';

ALTER TABLE `tasks_main` ADD COLUMN `step_id` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `tasks_main` ADD COLUMN `lead_id` INT UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `equipment_models` ADD COLUMN `width` tinyint(3) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `equipment_models` ADD COLUMN `height` tinyint(3) UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `voip_main` DROP PRIMARY KEY;
ALTER TABLE `voip_main` ADD COLUMN `id` INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY  NOT NULL;

CREATE TABLE IF NOT EXISTS `voip_phone_aliases`
(
    `id`        INT(11) UNSIGNED     NOT NULL AUTO_INCREMENT,
    `uid`       INT(11) UNSIGNED     NOT NULL DEFAULT '0',
    `disable`   TINYINT(1) UNSIGNED  NOT NULL DEFAULT '0',
    `number`    VARCHAR(16)          NOT NULL DEFAULT '',
    `changed`   DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `number` (`number`),
    KEY `uid` (`uid`)
)
    DEFAULT CHARSET = utf8 COMMENT = 'Voip phone aliasese';
