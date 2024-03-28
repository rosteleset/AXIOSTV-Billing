SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `crm_leads` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `fio` VARCHAR(120) NOT NULL DEFAULT '',
  `phone` VARCHAR(120) NOT NULL DEFAULT '',
  `company` VARCHAR(120) NOT NULL DEFAULT '',
  `email` VARCHAR(250) NOT NULL DEFAULT '',
  `country` VARCHAR(80) NOT NULL DEFAULT '',
  `city` VARCHAR(80) NOT NULL DEFAULT '',
  `address` VARCHAR(100) NOT NULL DEFAULT '',
  `source` INT(1) NOT NULL DEFAULT 0,
  `responsible` SMALLINT(4) NOT NULL DEFAULT 0,
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `current_step` INT NOT NULL DEFAULT 1,
  `priority` SMALLINT(1) NOT NULL DEFAULT 0,
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `tag_ids` VARCHAR(20) NOT NULL DEFAULT '',
  `build_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `address_flat` VARCHAR(10) NOT NULL DEFAULT '',
  `competitor_id` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `assessment` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT,
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `holdup_date` DATE NOT NULL DEFAULT '0000-00-00',
  PRIMARY KEY (`id`),
  KEY uid (`uid`),
  KEY competitor_id (`competitor_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm leads';

CREATE TABLE IF NOT EXISTS `crm_progressbar_steps` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `step_number` INT UNSIGNED NOT NULL DEFAULT 1,
  `name` CHAR(40) NOT NULL DEFAULT '',
  `color` VARCHAR(7) NOT NULL DEFAULT '',
  `description` TEXT NOT NULL,
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `deal_step` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm progressbar steps';

REPLACE INTO `crm_progressbar_steps` (`id`, `step_number`, `name`, `color`, `description`) VALUE
  ('1', '1', '$lang{NEW_LEAD}', '#5479e7', ''),
  ('2', '2', '$lang{CONTRACT_SIGNED}', '#25d2f1', ''),
  ('3', '3', '$lang{THE_WORKS}', '#ff8000', ''),
  ('4', '4', '$lang{CONVERSION}', '#f1233d', '');

CREATE TABLE IF NOT EXISTS `crm_leads_sources` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` CHAR(40) NOT NULL DEFAULT '',
  `comments` TEXT NOT NULL,
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm leads source';

REPLACE INTO `crm_leads_sources` (`id`, `name`, `comments`) VALUE
  ('1', '$lang{PHONE}', ''),
  ('2', 'E-mail', ''),
  ('3', '$lang{SOCIAL_NETWORKS}', ''),
  ('4', '$lang{REFERRALS}', '');

CREATE TABLE IF NOT EXISTS `crm_progressbar_step_comments` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `step_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `lead_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `deal_id` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  `message` TEXT NOT NULL,
  `date` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `action_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `status` SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `planned_date` DATE NOT NULL DEFAULT '0000-00-00',
  `plan_time` TIME NOT NULL DEFAULT '00:00:00',
  `plan_interval` SMALLINT(6) UNSIGNED NOT NULL  DEFAULT '0',
  `priority` SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
  `pin` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE (`lead_id`, `deal_id`, `date`),
  KEY aid (`aid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Comments for each step in progressbar';

CREATE TABLE IF NOT EXISTS `crm_actions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` char(60) NOT NULL DEFAULT '',
  `action` TEXT NOT NULL,
  `send_message` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `subject` VARCHAR(150) NOT NULL DEFAULT '',
  `message` TEXT NOT NULL,
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Entity ACTION';

CREATE TABLE IF NOT EXISTS `crm_competitors` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(64) NOT NULL DEFAULT '',
  `connection_type` VARCHAR(32) NOT NULL DEFAULT '',
  `site` VARCHAR(150) NOT NULL DEFAULT '',
  `color` VARCHAR(7) NOT NULL DEFAULT '',
  `descr` TEXT NOT NULL,
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Crm Competitors';

CREATE TABLE IF NOT EXISTS `crm_competitors_tps` (
  `id`            INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`          VARCHAR(64) NOT NULL DEFAULT '',
  `speed`         INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `month_fee`     DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `day_fee`       DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `competitor_id` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `competitor_id` (`competitor_id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Crm Competitors tps';

CREATE TABLE IF NOT EXISTS `crm_competitor_geolocation` (
  `competitor_id` SMALLINT(5) UNSIGNED DEFAULT '0' NOT NULL,
  `district_id`   SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL,
  `street_id`     SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL,
  `build_id`      SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL
)
  DEFAULT CHARSET=utf8 COMMENT = 'Geolocation of competitor';

CREATE TABLE IF NOT EXISTS `crm_competitor_tps_geolocation` (
  `tp_id`       SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL,
  `district_id` SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL,
  `street_id`   SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL,
  `build_id`    SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL
)
  DEFAULT CHARSET=utf8 COMMENT = 'Geolocation of competitor tps';

CREATE TABLE IF NOT EXISTS `crm_admin_actions` (
  `actions`     VARCHAR(100)         NOT NULL DEFAULT '',
  `datetime`    DATETIME             NOT NULL,
  `ip`          INT(11) UNSIGNED     NOT NULL DEFAULT '0',
  `lid`         INT(11) UNSIGNED     NOT NULL DEFAULT '0',
  `aid`         SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `id`          INT(11) UNSIGNED     NOT NULL AUTO_INCREMENT,
  `action_type` TINYINT(2)           NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `lid` (`lid`),
  KEY `aid` (`aid`),
  KEY `action_type` (`action_type`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Crm leads changes log';

CREATE TABLE IF NOT EXISTS `crm_info_fields` (
  `id`           TINYINT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`         VARCHAR(60)          NOT NULL DEFAULT '',
  `sql_field`    VARCHAR(60)          NOT NULL DEFAULT '',
  `type`         TINYINT(2) UNSIGNED  NOT NULL DEFAULT 0,
  `priority`     TINYINT(1) UNSIGNED  NOT NULL DEFAULT 0,
  `comment`      VARCHAR(60)          NOT NULL DEFAULT '',
  `pattern`      VARCHAR(60)          NOT NULL DEFAULT '',
  `title`        VARCHAR(255)         NOT NULL DEFAULT '',
  `registration` TINYINT(1) UNSIGNED  NOT NULL DEFAULT 0,
  `domain_id`    SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY (`name`),
  UNIQUE KEY (`sql_field`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm Info fields';

CREATE TABLE IF NOT EXISTS `crm_tp_info_fields` (
  `id`          TINYINT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(60)          NOT NULL DEFAULT '',
  `sql_field`   VARCHAR(60)          NOT NULL DEFAULT '',
  `type`        TINYINT(2) UNSIGNED  NOT NULL DEFAULT 0,
  `priority`    TINYINT(1) UNSIGNED  NOT NULL DEFAULT 0,
  `comment`     VARCHAR(60)          NOT NULL DEFAULT '',
  `pattern`     VARCHAR(60)          NOT NULL DEFAULT '',
  `title`       VARCHAR(255)         NOT NULL DEFAULT '',
  `domain_id`   SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY (`name`),
  UNIQUE KEY (`sql_field`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm Tariff plans info fields';

CREATE TABLE IF NOT EXISTS `crm_leads_watchers` (
  `id`          INT(11)       UNSIGNED  NOT NULL  AUTO_INCREMENT,
  `aid`         SMALLINT(6)   UNSIGNED  NOT NULL  DEFAULT 0,
  `lead_id`     INT(10)       UNSIGNED  NOT NULL  DEFAULT 0,
  `add_time`    DATETIME                NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY (`aid`,`lead_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'watchers for leads';

CREATE TABLE IF NOT EXISTS `crm_response_templates` (
  `id`                INT(11)       UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`              VARCHAR(60)            NOT NULL DEFAULT '',
  `text`              VARCHAR(255)           NOT NULL DEFAULT '',
  `datetime_change`   DATETIME               NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
)
  DEFAULT CHARSET=utf8
  COMMENT = 'Crm list of response templates';

CREATE TABLE IF NOT EXISTS `crm_dialogues` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `lead_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `date` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `source` VARCHAR(60) NOT NULL DEFAULT '',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `state` TINYINT(2) UNSIGNED DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE (`lead_id`, `date`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm dialogues';

CREATE TABLE IF NOT EXISTS `crm_dialogue_messages` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `dialogue_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `date` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `message` TEXT NOT NULL,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `inner_msg` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm dialogue messages';

CREATE TABLE IF NOT EXISTS `crm_open_lines` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(60) NOT NULL DEFAULT '',
  `source` VARCHAR(60) NOT NULL DEFAULT '',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm open lines';

CREATE TABLE IF NOT EXISTS `crm_open_line_admins` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `open_line_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm open line admins';

CREATE TABLE IF NOT EXISTS `crm_section_fields` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `fields` TEXT NOT NULL,
  `section_id` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `admin_panel` (`aid`, `section_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Leads fields to show';

CREATE TABLE IF NOT EXISTS `crm_sections` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `title` VARCHAR(60) NOT NULL DEFAULT '',
  `deal_section` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Info sections';

CREATE TABLE IF NOT EXISTS `crm_deals` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `uid` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `name` VARCHAR(60) NOT NULL DEFAULT '',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `current_step` INT NOT NULL DEFAULT 1,
  `date` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `close_date` DATE NOT NULL DEFAULT '0000-00-00',
  `begin_date` DATE NOT NULL DEFAULT '0000-00-00',
  `comments` TEXT,
  PRIMARY KEY (`id`),
  KEY `aid` (`aid`),
  KEY `uid` (`uid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm deals';

REPLACE INTO `crm_sections` (`aid`, `title`) VALUES (1, '$lang{INFO}');
REPLACE INTO `crm_sections` (`aid`, `title`) VALUES (1, '$lang{EXTRA}');
REPLACE INTO `crm_sections` (`aid`, `title`, `deal_section`) VALUES (1, '$lang{INFO}', 1);
REPLACE INTO `crm_sections` (`aid`, `title`, `deal_section`) VALUES (1, '$lang{CRM_PRODUCTS}', 1);

REPLACE INTO `crm_section_fields` (`aid`, `fields`, `section_id`) VALUES (1, 'FIO,PHONE,EMAIL,ADDRESS', 1);
REPLACE INTO `crm_section_fields` (`aid`, `fields`, `section_id`) VALUES (1, 'COMMENTS,RESPONSIBLE,PRIORITY', 2);
REPLACE INTO `crm_section_fields` (`aid`, `fields`, `section_id`) VALUES (1, 'NAME,BEGIN_DATE,CLOSE_DATE', 3);
REPLACE INTO `crm_section_fields` (`aid`, `fields`, `section_id`) VALUES (1, 'PRODUCTS', 4);

CREATE TABLE IF NOT EXISTS `crm_deal_products` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `deal_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `name` VARCHAR(60) NOT NULL DEFAULT '',
  `count` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `sum` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `fees_type` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `deal_id` (`deal_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm deal products';

CREATE TABLE IF NOT EXISTS `crm_workflows`
(
  `id`      INT(11) UNSIGNED    NOT NULL AUTO_INCREMENT,
  `name`    VARCHAR(50)         NOT NULL DEFAULT '',
  `descr`   TEXT                NOT NULL,
  `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `used_times` INT(11)    UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm workflows';

CREATE TABLE IF NOT EXISTS `crm_workflow_triggers`
(
  `id`    INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `workflow_id`   INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `type`  VARCHAR(50) NOT NULL DEFAULT '',
  `old_value`  VARCHAR(50) NOT NULL DEFAULT '',
  `new_value`  VARCHAR(50) NOT NULL DEFAULT '',
  `contains`   VARCHAR(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm workflow triggers';

CREATE TABLE IF NOT EXISTS `crm_workflow_actions`
(
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `workflow_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `type` VARCHAR(50) NOT NULL DEFAULT '',
  `value` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm workflow actions';