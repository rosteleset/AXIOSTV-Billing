ALTER TABLE `cablecat_splitters` ADD COLUMN `commutation_rotation` SMALLINT NOT NULL DEFAULT 0;
CREATE TABLE IF NOT EXISTS `callcenter_cdr` (
  `calldate` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `clid` varchar(80) NOT NULL DEFAULT '',
  `src` varchar(80) NOT NULL DEFAULT '',
  `dst` varchar(80) NOT NULL DEFAULT '',
  `dcontext` varchar(80) NOT NULL DEFAULT '',
  `channel` varchar(80) NOT NULL DEFAULT '',
  `dstchannel` varchar(80) NOT NULL DEFAULT '',
  `lastapp` varchar(80) NOT NULL DEFAULT '',
  `lastdata` varchar(80) NOT NULL DEFAULT '',
  `duration` int(11) NOT NULL DEFAULT '0',
  `billsec` int(11) NOT NULL DEFAULT '0',
  `disposition` varchar(45) NOT NULL DEFAULT '',
  `amaflags` int(11) NOT NULL DEFAULT '0',
  `accountcode` varchar(20) NOT NULL DEFAULT '',
  `userfield` varchar(255) NOT NULL DEFAULT '',
  KEY `calldate` (`calldate`),
  KEY `dst` (`dst`),
  KEY `accountcode` (`accountcode`)
)
  COMMENT='Callcenter asterisk CDR';

CREATE TABLE IF NOT EXISTS `info_fields` (
  `id` TINYINT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(60) NOT NULL DEFAULT '',
  `sql_field` VARCHAR(60) NOT NULL DEFAULT '',
  `type` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
  `priority` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `abon_portal` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `user_chg` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `comment` VARCHAR(60) NOT NULL DEFAULT '',
  `module` VARCHAR(20) NOT NULL DEFAULT '',
  `company` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `pattern` VARCHAR(60) NOT NULL DEFAULT '',
  `title` VARCHAR(255) NOT NULL DEFAULT '',
  `placeholder` VARCHAR(60) NOT NULL DEFAULT '',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY (`name`, `domain_id`),
  UNIQUE KEY (`sql_field`)
)
  COMMENT = 'Info_fields';

ALTER TABLE `equipment_pon_onu` ADD COLUMN `line_profile` VARCHAR(50) NOT NULL DEFAULT 'ONU';
ALTER TABLE `equipment_pon_onu` ADD COLUMN `srv_profile` VARCHAR(50) NOT NULL DEFAULT 'ALL';
ALTER TABLE `equipment_pon_onu` ADD COLUMN `deleted` INT(1) UNSIGNED NOT NULL DEFAULT '0';

UPDATE equipment_models SET snmp_tpl='eltex_ltp.snmp' WHERE model_name LIKE "LTP-%" AND vendor_id=13;
UPDATE equipment_models SET snmp_tpl='huawei_pon.snmp' WHERE model_name LIKE "MA56%" AND vendor_id=22;

ALTER TABLE `equipment_mac_log` ADD COLUMN `port_name` VARCHAR(50) NOT NULL DEFAULT '';
ALTER TABLE `equipment_mac_log` CHANGE COLUMN port port VARCHAR(50) COLLATE utf8_general_ci DEFAULT '';
