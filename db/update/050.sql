ALTER TABLE `paysys_connect` ADD COLUMN `priority` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;

INSERT INTO `admin_permits` (`aid`, `section`, `actions`, `module`) VALUES (2, 0, 13, '');

CREATE TABLE `iptv_device` (
  `id` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `uid` smallint(6) unsigned NOT NULL DEFAULT '0',
  `dev_id` varchar(50) NOT NULL DEFAULT '',
  `enable` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '0 - enable, 1 - disable',
  `date_activity` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ip_activity` varchar(15) NOT NULL DEFAULT '',
  `service_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'IPTV devices';


CREATE TABLE `iptv_extra_params` (
  `id` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `balance` double(14, 2) NOT NULL DEFAULT '0.00',
  `send_sms` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '1 - yes, 0 - no',
  `sms_text` TEXT,
  `ip_mac` varchar(15) NOT NULL DEFAULT '',
  `service_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `group_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `tp_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `max_device` smallint(6) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'IPTV extra_params';