SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `dv_calls` (
  `status` INT(3) NOT NULL DEFAULT '0',
  `user_name` VARCHAR(32) NOT NULL DEFAULT '',
  `started` DATETIME NOT NULL,
  `nas_ip_address` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `nas_port_id` INT(6) UNSIGNED NOT NULL DEFAULT '0',
  `acct_session_id` VARCHAR(32) NOT NULL DEFAULT '',
  `acct_session_time` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `acct_input_octets` BIGINT(14) UNSIGNED NOT NULL DEFAULT '0',
  `acct_output_octets` BIGINT(14) UNSIGNED NOT NULL DEFAULT '0',
  `ex_input_octets` BIGINT(14) UNSIGNED NOT NULL DEFAULT '0',
  `ex_output_octets` BIGINT(14) UNSIGNED NOT NULL DEFAULT '0',
  `connect_term_reason` INT(4) UNSIGNED NOT NULL DEFAULT '0',
  `framed_ip_address` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `framed_ipv6_prefix` VARBINARY(16) NOT NULL DEFAULT '',
  `framed_interface_id` VARBINARY(16) NOT NULL DEFAULT '',
  `lupdated` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `sum` DOUBLE(14, 6) NOT NULL DEFAULT '0.000000',
  `CID` VARCHAR(20) NOT NULL DEFAULT '',
  `CONNECT_INFO` VARCHAR(35) NOT NULL DEFAULT '',
  `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `nas_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `acct_input_gigawords` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `acct_output_gigawords` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `ex_input_octets_gigawords` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `ex_output_octets_gigawords` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `join_service` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `turbo_mode` VARCHAR(30) NOT NULL DEFAULT '',
  `guest` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  KEY `user_name` (`user_name`),
  KEY `acct_session_id` (`acct_session_id`),
  KEY `framed_ip_address` (`framed_ip_address`),
  KEY `uid` (`uid`)
);


CREATE TABLE IF NOT EXISTS `dv_log_intervals` (
  `interval_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `sent` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `recv` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `duration` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `traffic_type` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `sum` DOUBLE(14, 6) UNSIGNED NOT NULL DEFAULT '0.000000',
  `acct_session_id` VARCHAR(32) NOT NULL DEFAULT '',
  `added` TIMESTAMP NOT NULL,
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  KEY `acct_session_id` (`acct_session_id`),
  KEY `session_interval` (`acct_session_id`, `interval_id`),
  KEY `uid` (`uid`)
)
  COMMENT = 'DV interval summary stats';

CREATE TABLE IF NOT EXISTS `dv_main` (
  `uid` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `logins` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `registration` DATE DEFAULT '0000-00-00',
  `ip` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `filter_id` VARCHAR(150) NOT NULL DEFAULT '',
  `speed` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `netmask` INT(10) UNSIGNED NOT NULL DEFAULT '4294967295',
  `cid` VARCHAR(35) NOT NULL DEFAULT '',
  `password` BLOB NOT NULL,
  `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `callback` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `port` VARCHAR(40) NOT NULL DEFAULT '',
  `join_service` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `turbo_mode` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `free_turbo_mode` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `expire` DATE NOT NULL DEFAULT '0000-00-00',
  `dv_login` VARCHAR(24) NOT NULL DEFAULT '',
  `detail_stats` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `personal_tp` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `traf_detail` smallint(1) unsigned NOT NULL default '0',
  PRIMARY KEY (`uid`),
  KEY `tp_id` (`tp_id`),
  KEY `CID` (`cid`)
)
  COMMENT = 'Dv accounts';

CREATE TABLE IF NOT EXISTS `dv_log` (
  `start` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `duration` INT(11) NOT NULL DEFAULT '0',
  `sent` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `recv` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `sum` DOUBLE(14, 6) NOT NULL DEFAULT '0.000000',
  `port_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `nas_id` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `ip` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `sent2` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `recv2` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `acct_session_id` VARCHAR(32) NOT NULL DEFAULT '',
  `CID` VARCHAR(18) NOT NULL DEFAULT '',
  `bill_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `terminate_cause` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `framed_ipv6_prefix` VARBINARY(16) NOT NULL DEFAULT '',
  `acct_input_gigawords` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `acct_output_gigawords` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `ex_input_octets_gigawords` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `ex_output_octets_gigawords` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  KEY `uid` (`uid`, `start`)
)
  COMMENT = 'Internet sessions logs';
