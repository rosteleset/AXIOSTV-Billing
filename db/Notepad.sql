SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `notepad` (
  `id`          INT(11)     UNSIGNED NOT NULL AUTO_INCREMENT,
  `show_at`     DATE NOT NULL DEFAULT '0000-00-00',
  `start_stat`  TIME NOT NULL DEFAULT '00:00:00',
  `end_stat`    TIME NOT NULL DEFAULT '00:00:00',
  `create_date` DATETIME    DEFAULT CURRENT_TIMESTAMP,
  `status`      INT(3)      UNSIGNED NOT NULL DEFAULT 0,
  `subject`     VARCHAR(60) NOT NULL DEFAULT '',
  `text`        TEXT,
  `aid`         SMALLINT(5) UNSIGNED NOT NULL DEFAULT 0,
  `status_st`   TINYINT(1)  UNSIGNED NOT NULL DEFAULT 0,
  UNIQUE `subject_text` (`subject`, `aid`, `status`),
  PRIMARY KEY (`id`),
  KEY `aid` (`aid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Notepad';


CREATE TABLE IF NOT EXISTS `notepad_reminders` (
  `id` INT(11) UNSIGNED NOT NULL REFERENCES `notepad` (`id`)
    ON DELETE CASCADE,
  `rule_id`   SMALLINT(3) NOT NULL DEFAULT '0',
  `minute`    SMALLINT(2) NOT NULL DEFAULT '0',
  `hour`      SMALLINT(2) NOT NULL DEFAULT '0',
  `week_day`  TEXT,
  `month_day` TEXT,
  `month`     SMALLINT(2) NOT NULL DEFAULT '0',
  `year`      SMALLINT(6) NOT NULL DEFAULT '0',
  `holidays`  TINYINT(1)  NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
 DEFAULT CHARSET = utf8  COMMENT = 'Periodic reminders';

CREATE TABLE IF NOT EXISTS `notepad_checklist_rows` (
  `id`       INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `note_id` INT(11) UNSIGNED NOT NULL REFERENCES `notepad` (`id`)
  ON DELETE CASCADE,
  `name`     VARCHAR(255) NOT NULL DEFAULT '',
  `state`    TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `datetime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY `note_id` (`note_id`)
)
 DEFAULT CHARSET = utf8 COMMENT = 'Notepad checklists rows';
