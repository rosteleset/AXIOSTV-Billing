SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `abon_tariffs` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(160) NOT NULL DEFAULT '',
  `period` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `price` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `payment_type` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `period_alignment` TINYINT(1) NOT NULL DEFAULT '0',
  `ext_bill_account` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `nonfix_period` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `priority` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `account` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `fees_type` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `create_account` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `vat` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `notification1` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `notification2` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `notification_account` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `activate_notification` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `alert` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `alert_account` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `ext_cmd` VARCHAR(240) NOT NULL DEFAULT '',
  `discount` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `manual_activate` TINYINT(1) NOT NULL DEFAULT 0,
  `user_portal` TINYINT(1) NOT NULL DEFAULT 0,
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `service_link` VARCHAR(240) NOT NULL DEFAULT '' COMMENT 'Extra link for service',
  `description` VARCHAR(240) NOT NULL DEFAULT '',
  `user_description` TEXT NOT NULL DEFAULT '' COMMENT 'User portal describe',
  `service_recovery` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Service recovery mode',
  `service_img` VARCHAR(240) NOT NULL DEFAULT '',
  `plugin` VARCHAR(24) NOT NULL DEFAULT '' COMMENT 'Service plugin',
  `ext_service_id` VARCHAR(24) NOT NULL DEFAULT '' COMMENT 'External service ID',
  `login` VARCHAR(72) NOT NULL DEFAULT '' COMMENT 'API Login',
  `password` BLOB COMMENT 'API Password',
  `url` VARCHAR(120) NOT NULL DEFAULT '' COMMENT 'API url',
  `debug` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'API DEBUG',
  `debug_file` VARCHAR(120) NOT NULL DEFAULT '' COMMENT 'API DEBUG file',
  `category_id` SMALLINT(6) UNSIGNED NOT NULL default 0,
  `activate_price` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `promotional` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `promo_period` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Abon tariffs';

CREATE TABLE IF NOT EXISTS `abon_user_list` (
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `date` DATE NOT NULL DEFAULT '0000-00-00' COMMENT 'Last fee date',
  `comments` VARCHAR(240) NOT NULL DEFAULT '',
  `notification1` DATE NOT NULL DEFAULT '0000-00-00',
  `notification1_account_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `notification2` DATE NOT NULL DEFAULT '0000-00-00',
  `discount` DOUBLE(6, 2) NOT NULL DEFAULT '0.00',
  `create_docs` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `send_docs` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `service_count` SMALLINT(4) UNSIGNED NOT NULL DEFAULT 1,
  `manual_fee` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `fees_period` SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0,
  `personal_description` VARCHAR(240) NOT NULL DEFAULT '',
  KEY `uid` (`uid`, `tp_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Abon user list';

CREATE TABLE IF NOT EXISTS `abon_categories` (
  `id`              SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`            VARCHAR(50) NOT NULL DEFAULT '',
  `dsc`             VARCHAR(80) NOT NULL DEFAULT '' COMMENT 'Description',
  `public_dsc`      VARCHAR(80) NOT NULL DEFAULT '' COMMENT 'Public description',
  `visible`         TINYINT(1)  NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Abon category';