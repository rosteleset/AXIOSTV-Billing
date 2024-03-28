SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `iptv_main` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Billing service ID',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `filter_id` VARCHAR(100) NOT NULL DEFAULT '',
  `cid` VARCHAR(35) NOT NULL DEFAULT '' COMMENT 'STB MAC od ID',
  `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0' COMMENT '0 - Active, 1 - Disable',
  `registration` DATE NOT NULL,
  `pin` BLOB NOT NULL,
  `vod` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `dvcrypt_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `expire` DATE NOT NULL DEFAULT '0000-00-00',
  `activate` DATE NOT NULL DEFAULT '0000-00-00',
  `subscribe_id` VARCHAR(32) NOT NULL DEFAULT '' COMMENT 'External service ID for syncronization',
  `email` VARCHAR(100) NOT NULL DEFAULT '' COMMENT 'Extra email for service',
  `service_id` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Service id for plugin connections',
  `iptv_login` VARCHAR(32) NOT NULL DEFAULT '',
  `iptv_password` VARCHAR(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `tp_id` (`tp_id`),
  KEY `uid` (`uid`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Iptv users settings';

CREATE TABLE IF NOT EXISTS `iptv_tps` (
  `id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `day_time_limit` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `week_time_limit` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `month_time_limit` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `max_session_duration` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `min_session_cost` DOUBLE(15, 5) UNSIGNED NOT NULL DEFAULT '0.00000',
  `rad_pairs` TEXT NOT NULL,
  `first_period` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `first_period_step` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `next_period` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `next_period_step` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `free_time` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `service_id` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Service id for plugin connections',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Iptv TPs';

CREATE TABLE IF NOT EXISTS `iptv_channels` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  `num` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `port` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT NOT NULL,
  `filter_id` VARCHAR(100) NOT NULL DEFAULT '',
  `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `stream` VARCHAR(150) NOT NULL DEFAULT '',
  `state` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `genre_id` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `num` (`num`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Iptv channels';

CREATE TABLE IF NOT EXISTS `iptv_ti_channels` (
  `interval_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `channel_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `month_price` DOUBLE(15, 2) NOT NULL DEFAULT '0.00',
  `day_price` DOUBLE(15, 2) NOT NULL DEFAULT '0.00',
  `mandatory` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  UNIQUE KEY `channel_id` (`channel_id`, `interval_id`),
  KEY interval_id (`interval_id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Iptv channels prices';

CREATE TABLE IF NOT EXISTS `iptv_users_channels` (
  `id` INTEGER(10) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INTEGER(10) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `channel_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `changed` DATETIME NOT NULL,
  UNIQUE KEY `id` (`id`, `channel_id`, `tp_id`),
  KEY `uid` (`uid`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Iptv users channels';


CREATE TABLE IF NOT EXISTS `iptv_calls` (
  `status` INT(3) NOT NULL DEFAULT '0',
  `started` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `nas_ip_address` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `nas_port_id` INT(6) UNSIGNED NOT NULL DEFAULT '0',
  `acct_session_id` VARCHAR(25) NOT NULL DEFAULT '',
  `acct_session_time` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `connect_term_reason` INT(4) UNSIGNED NOT NULL DEFAULT '0',
  `framed_ip_address` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `lupdated` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `sum` DOUBLE(14, 6) NOT NULL DEFAULT '0.000000',
  `CID` VARCHAR(18) NOT NULL DEFAULT '',
  `CONNECT_INFO` VARCHAR(35) NOT NULL DEFAULT '',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `nas_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `join_service` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `turbo_mode` VARCHAR(30) NOT NULL DEFAULT '',
  `guest` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `service_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  KEY `acct_session_id` (`acct_session_id`),
  KEY `uid` (`uid`),
  KEY `service_id` (`service_id`)
) DEFAULT CHARSET=utf8 COMMENT = 'Iptv online';


CREATE TABLE IF NOT EXISTS `iptv_subscribes` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `status` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `created` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `ext_id` VARCHAR(20) NOT NULL DEFAULT '',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `expire` DATE NOT NULL DEFAULT '0000-00-00',
  `password` BLOB NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ext_id` (`ext_id`),
  KEY `tp_id` (`tp_id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Iptv Subscribes';


CREATE TABLE IF NOT EXISTS `iptv_screens` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `num` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `filter_id` VARCHAR(60) NOT NULL DEFAULT '',
  `name` VARCHAR(60) NOT NULL DEFAULT '',
  `month_fee` DOUBLE(15, 5) UNSIGNED NOT NULL DEFAULT '0.00000',
  `day_fee` DOUBLE(15, 5) UNSIGNED NOT NULL DEFAULT '0.00000',
  PRIMARY KEY (`id`),
  UNIQUE KEY `tp_id` (`tp_id`, `num`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'IPTV Extra screens';


CREATE TABLE IF NOT EXISTS `iptv_users_screens` (
  `service_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `screen_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `cid` VARCHAR(60) NOT NULL DEFAULT '',
  `serial` VARCHAR(60) NOT NULL DEFAULT '',
  `hardware_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `comment` VARCHAR(250) DEFAULT '',
  UNIQUE KEY `service_id` (`service_id`, `screen_id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'IPTV Extra screens';


CREATE TABLE IF NOT EXISTS `iptv_services` (
  `id` TINYINT(2) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL DEFAULT '',
  `module` VARCHAR(24) NOT NULL DEFAULT '',
  `status` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `comment` VARCHAR(250) DEFAULT '',
  `login` VARCHAR(72) NOT NULL DEFAULT '',
  `password` BLOB,
  `url` VARCHAR(120) NOT NULL DEFAULT '',
  `user_portal` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `debug` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
  `debug_file` VARCHAR(120) NOT NULL DEFAULT '',
  `subscribe_count` TINYINT(2) UNSIGNED NOT NULL DEFAULT 1,
  `provider_portal_url` VARCHAR(200) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `status` (`status`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'IPTV Services';

CREATE TABLE IF NOT EXISTS `iptv_devices` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `dev_id` varchar(50) NOT NULL DEFAULT '',
  `enable` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '0 - enable, 1 - disable',
  `date_activity` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ip_activity` int(11) unsigned NOT NULL DEFAULT '0',
  `service_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `code` VARCHAR(10) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`),
  KEY `service_id` (`service_id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'IPTV devices';

CREATE TABLE IF NOT EXISTS `iptv_extra_params` (
  `id` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `balance` double(14, 2) NOT NULL DEFAULT '0.00',
  `send_sms` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '1 - yes, 0 - no',
  `sms_text` TEXT,
  `ip_mac` VARCHAR(120) NOT NULL DEFAULT '',
  `service_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `group_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `tp_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `max_device` smallint(6) unsigned NOT NULL DEFAULT '0',
  `pin` VARCHAR(10) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'IPTV extra_params';

