SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `bonus_log` (
  `date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `sum` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `dsc` VARCHAR(80) DEFAULT NULL,
  `ip` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `last_deposit` DOUBLE(15, 6) NOT NULL DEFAULT '0.000000',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `method` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `ext_id` VARCHAR(28) NOT NULL DEFAULT '',
  `bill_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `inner_describe` VARCHAR(80) NOT NULL DEFAULT '',
  `action_type` TINYINT(11) UNSIGNED NOT NULL DEFAULT '0',
  `expire` DATE NOT NULL DEFAULT '0000-00-00',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `date` (`date`),
  KEY `uid` (`uid`)
)
  CHARSET = 'utf8'
  COMMENT = 'Bonus log';

CREATE TABLE IF NOT EXISTS `bonus_service_discount` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL default '',
  `service_period` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `registration_days` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `discount` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `discount_days` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `total_payments_sum` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `bonus_sum` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `bonus_percent` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `ext_account` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `pay_method` VARCHAR(100) NOT NULL DEFAULT '0',
  `comments` TEXT NOT NULL,
  `tp_id` VARCHAR(200) NOT NULL DEFAULT '',
  `onetime_payment_sum` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Bonus service discount';

CREATE TABLE IF NOT EXISTS `bonus_turbo` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `service_period` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `registration_days` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `turbo_count` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT,
  PRIMARY KEY (`id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Bonus turbo';

CREATE TABLE IF NOT EXISTS `bonus_tps` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL,
  `state` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
)
  CHARSET = 'utf8'
  COMMENT = 'Bonus tarif plans';

CREATE TABLE IF NOT EXISTS `bonus_accoumulation` (
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `dv_tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `scores` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0
)
  CHARSET = 'utf8'
  COMMENT = 'Bonus accoumulation';


CREATE TABLE IF NOT EXISTS `bonus_rules` (
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `period` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `rules` VARCHAR(20) NOT NULL,
  `actions` VARCHAR(20) NOT NULL,
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `rule_value` INT(11) UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tp_id` (`tp_id`, `period`, `rules`, `rule_value`)
)
  CHARSET = 'utf8'
  COMMENT = 'Bonus rules';

CREATE TABLE IF NOT EXISTS `bonus_main` (
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `accept_rules` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `state` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`uid`),
  UNIQUE KEY `uid` (`uid`)
)
  CHARSET = 'utf8'
  COMMENT = 'Bonus users';


CREATE TABLE IF NOT EXISTS `bonus_rules_accomulation` (
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `dv_tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `cost` DOUBLE(15, 6) NOT NULL DEFAULT '0.000000',
  UNIQUE KEY `tp_id` (`tp_id`, `dv_tp_id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Bonus accomulation rules';


CREATE TABLE IF NOT EXISTS `bonus_rules_accomulation_scores` (
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `dv_tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `cost` DOUBLE(15, 6) NOT NULL DEFAULT '0.000000',
  `changed` DATE NOT NULL DEFAULT '0000-00-00',
  PRIMARY KEY `uid` (`uid`)
)
  CHARSET = 'utf8'
  COMMENT = 'Bonus accomulation scores';


CREATE TABLE IF NOT EXISTS `bonus_tp_using` (
  `id` SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
  `comments` TEXT,
  `tp_id_main` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id_bonus` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `period` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `tps` (`tp_id_main`, `tp_id_bonus`)
)
  CHARSET = 'utf8'
  COMMENT = 'Bonus tp using';

