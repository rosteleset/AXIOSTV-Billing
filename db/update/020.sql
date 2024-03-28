ALTER TABLE `notepad` CHANGE COLUMN `notified` `show_at` DATETIME NOT NULL;
ALTER TABLE `notepad_reminders` ADD CONSTRAINT UNIQUE `_unique_note_id` (`id`);

ALTER TABLE `notepad_reminders` ADD COLUMN `rule_id`   SMALLINT(3) NOT NULL DEFAULT '0';
ALTER TABLE `notepad_reminders` MODIFY COLUMN `week_day` TEXT;

ALTER TABLE `notepad` MODIFY COLUMN `create_date` DATETIME    DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE `notepad` ADD COLUMN `status_st` TINYINT(3) NOT NULL AFTER `aid`;

CREATE TABLE IF NOT EXISTS `notepad_checklist_rows` (
  `id`       INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `note_id` INT(11) UNSIGNED NOT NULL REFERENCES `notepad` (`id`)
    ON DELETE CASCADE,
  `name`     VARCHAR(255) NOT NULL DEFAULT '',
  `state`    TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `datetime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)
  COMMENT = 'Notepad checklists rows';

ALTER TABLE `districts` DROP INDEX `name`;
ALTER TABLE `districts` ADD UNIQUE KEY `name` (`city`, `name`, `domain_id`);

CREATE TABLE IF NOT EXISTS `hotspot_log` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `CID` VARCHAR(20) NOT NULL DEFAULT '',
  `phone` VARCHAR(20) NOT NULL DEFAULT '',
  `action` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT NOT NULL,

  PRIMARY KEY (`id`)
) 
  COMMENT = 'Hotspot log';