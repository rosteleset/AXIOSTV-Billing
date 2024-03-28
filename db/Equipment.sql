SET SQL_MODE='NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `equipment_vendors` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  `support` VARCHAR(50) NOT NULL DEFAULT '',
  `site` VARCHAR(150) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
)
  DEFAULT CHARSET = utf8 COMMENT = 'Netlist equipment vendor';

REPLACE INTO `equipment_vendors` (`id`, `name`, `support`, `site`) VALUES
  (1, 'Cisco', '', 'http://cisco.com'),
  (2, 'D-link', '', 'http://www.dlink.ru/'),
  (3, 'Zyxel', '', 'http://zyxel.ru'),
  (4, 'Juniper', '', 'http://juniper.com'),
  (5, 'Edge-Core', '', 'http://www.edge-core.ru'),
  (6, 'Mikrotik', '', 'http://www.mikrotik.com'),
  (7, 'Ericsson', '', 'http://www.ericsson.com/ua'),
  (8, '3com', '', 'http://3com.com'),
  (9, 'TP-Link', '', 'http://www.tplink.com'),
  (10, 'Dell', '', 'http://www.dell.com'),
  (11, 'BDCOM', '', 'http://www.bdcom.com'),
  (12, 'ZTE', '', 'http://zte.ru/'),
  (13, 'ELTEX', '', 'http://www.eltex.ru/'),
  (14, 'GWdelight', '', 'http://www.gwdelight.com'),
  (15, 'Ruckus', '', 'http://www.ruckuswireless.com/'),
  (16, 'Ubiquiti', '', 'https://www.ubnt.com/'),
  (17, 'Nortel', '', 'http://www.nortel.com/'),
  (18, 'H3C', '', 'http://www.h3c.com'),
  (19, 'Foundry Networks', '', 'http://www.brocade.com/en.html'),
  (20, 'Alcatel', '', 'https://www.alcatel-lucent.com/'),
  (21, 'Hewlett-Packard', '', 'http://www8.hp.com/ru/ru/home.html'),
  (22, 'Huawei', '', 'http://huawei.com/ru/'),
  (23, 'SMC', '', 'http://www.smc.com/'),
  (24, 'Gw Delight', '', 'http://www.gwdelight.com/'),
  (25, 'Raisecom', '', 'https://www.raisecom.com'),
  (26, 'SNR', '', ''),
  (27, 'Linksys', '', 'http://www.linksys.com/us/'),
  (28, 'Planet', '', 'http://www.planet.com.tw'),
  (29, 'V-SOLUTION', '', 'https://ru.ftthcpe.com'),
  (30, 'CDATA', '', 'http://ru.cdatatec.com/'),
  (31, 'Brocade', '', 'https://www.broadcom.com'),
  (32, 'Netgear', '', 'https://www.netgear.ru/business/products/switches/'),
  (33, 'GCOM', '', 'https://gcom.com.ua/'),
  (34, 'HSGQ', '', 'https://www.hsgq.com/'),
  (35, 'FoxGate', '', 'https://foxgate.ua/'),
  (36, 'DCN', '', 'https://dcneurope.eu/'),
  (37, 'Extreme', '', 'https://www.extremenetworks.com/'),
  (38, 'NextHop', '', ''),
  (39, 'SmartFiber', '', 'http://www.smartfiberbd.com/');


CREATE TABLE IF NOT EXISTS `equipment_types` (
  `id` TINYINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8
  COMMENT = 'Netlist equipment type';

INSERT INTO `equipment_types` VALUES (1, 'Switch'),
  (2, 'WiFi'),
  (3, 'Router'),
  (4, 'PON'),
  (5, 'Server'),
  (6, 'DOCSIS'),
  (7, 'Set-top box'),
  (8, 'PON ONT'),
  (9, 'Cams');

CREATE TABLE IF NOT EXISTS `equipment_models` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `type_id` TINYINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `vendor_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `sys_oid` VARCHAR(50) NOT NULL DEFAULT '',
  `model_name` VARCHAR(50) NOT NULL DEFAULT '',
  `site` VARCHAR(150) NOT NULL DEFAULT '',
  `ports` TINYINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `manage_web` VARCHAR(50) NOT NULL DEFAULT '',
  `manage_ssh` VARCHAR(50) NOT NULL DEFAULT '',
  `snmp_tpl` VARCHAR(50) NOT NULL DEFAULT '',
  `comments` TEXT NOT NULL,
  `rows_count` INT(11) UNSIGNED NOT NULL DEFAULT '1',
  `block_size` INT(11) UNSIGNED DEFAULT '0',
  `test_firmware` VARCHAR(20) NOT NULL DEFAULT ''
  COMMENT 'Test equipment firmware',
  `port_numbering` TINYINT(1) UNSIGNED DEFAULT '0'
  COMMENT 'FALSE is ROWS, TRUE is COLUMNS',
  `first_position` TINYINT(1) UNSIGNED DEFAULT '0'
  COMMENT 'FALSE is UP, TRUE is DOWN',
  `extra_port1` SMALLINT(6) UNSIGNED DEFAULT '0',
  `extra_port2` SMALLINT(6) UNSIGNED DEFAULT '0',
  `extra_port3` SMALLINT(6) UNSIGNED DEFAULT '0',
  `extra_port4` SMALLINT(6) UNSIGNED DEFAULT '0',
  `ports_type` SMALLINT(5) UNSIGNED DEFAULT '1',
  `port_shift` smallint(4) NOT NULL DEFAULT '0',
  `auto_port_shift` TINYINT(1) NOT NULL DEFAULT '0',
  `fdb_uses_port_number_index` TINYINT(1) NOT NULL DEFAULT '0',
  `electric_power` INT(6) UNSIGNED NOT NULL DEFAULT '0',
  `epon_supported_onus` SMALLINT(4) UNSIGNED,
  `gpon_supported_onus` SMALLINT(4) UNSIGNED,
  `gepon_supported_onus` SMALLINT(4) UNSIGNED,
  `image_url` VARCHAR(500) DEFAULT '',
  `default_onu_reg_template_epon` VARCHAR(150),
  `default_onu_reg_template_gpon` VARCHAR(150),
  `width`   TINYINT(3) UNSIGNED  NOT NULL DEFAULT 0,
  `height`  TINYINT(3) UNSIGNED  NOT NULL DEFAULT 0,
  `cont_num_extra_ports` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Continuation of numbering for extra port from main row',
  PRIMARY KEY (`id`),
  KEY type_id (`type_id`),
  UNIQUE KEY `model` (`vendor_id`, `type_id`, `model_name`)
)
  AUTO_INCREMENT = 1000
  DEFAULT CHARSET = utf8
  COMMENT = 'Equipment models';


CREATE TABLE IF NOT EXISTS `equipment_infos` (
  `nas_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `model_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `system_id` VARCHAR(30) NOT NULL DEFAULT '',
  `ports` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `firmware` VARCHAR(20) NOT NULL DEFAULT '',
  `firmware2` VARCHAR(20) NOT NULL DEFAULT '',
  `status` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `start_up_date` DATE,
  `comments` TEXT,
  `serial` VARCHAR(100) NOT NULL DEFAULT '',
  `revision` VARCHAR(10) NOT NULL DEFAULT '',
  `snmp_version` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  `server_vlan` smallint(6) unsigned NOT NULL DEFAULT 0,
  `last_activity` DATETIME NOT NULL,
  `internet_vlan` smallint(6) unsigned NOT NULL DEFAULT '0',
  `tr_069_vlan` smallint(6) unsigned NOT NULL DEFAULT '0',
  `iptv_vlan` smallint(6) unsigned NOT NULL DEFAULT '0',
  `snmp_timeout` int(11)  unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`nas_id`),
  KEY model_id (model_id)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Equipment info';

CREATE TABLE IF NOT EXISTS `equipment_ports` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nas_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'PORT NAS',
  `port` INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'SWITCH PORT NUM',
  `status` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'ADMIN. PORT STATUS',
  `uplink` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'NAS ID',
  `comments` VARCHAR(250) NOT NULL DEFAULT '',
  `vlan` smallint(2) unsigned NOT NULL DEFAULT 0 COMMENT 'PORT VLAN',
  `datetime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nas_port` (`nas_id`, `port`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Equipment ports';

CREATE TABLE IF NOT EXISTS `pon_onus` (
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `mac` VARCHAR(16) NOT NULL DEFAULT '',
  `datetime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `status` TINYINT(1) NOT NULL DEFAULT 0
)
  DEFAULT CHARSET = utf8 COMMENT = 'PON onu list';


CREATE TABLE IF NOT EXISTS `equipment_box_types` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `marking` VARCHAR(30) NOT NULL DEFAULT '',
  `vendor` VARCHAR(40) NOT NULL DEFAULT '',
  `units` SMALLINT(6) NOT NULL DEFAULT '0',
  `width` SMALLINT(6) NOT NULL DEFAULT '0',
  `hieght` SMALLINT(6) NOT NULL DEFAULT '0',
  `length` SMALLINT(6) NOT NULL DEFAULT '0',
  `diameter` SMALLINT(6) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Equipment box types';

CREATE TABLE IF NOT EXISTS `equipment_boxes` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `type_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `serial` VARCHAR(30) NOT NULL DEFAULT '',
  `datetime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Equipment boxes';

CREATE TABLE IF NOT EXISTS `equipment_vlans` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `number` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `name` VARCHAR(30) NOT NULL DEFAULT '',
  `comments` TEXT NULL,
  UNIQUE (`name`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Equipment vlans';

CREATE TABLE IF NOT EXISTS `equipment_extra_ports` (
  `model_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `port_number` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `port_type` SMALLINT UNSIGNED NOT NULL DEFAULT '0',
  `port_combo_with` SMALLINT NOT NULL DEFAULT '0',
  `row` SMALLINT UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY `model_port` (`model_id`, `port_number`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Table for extra ports for equipment models';

CREATE TABLE IF NOT EXISTS `equipment_traps` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `traptime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `ip` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `port` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `eventname` VARCHAR(50) NOT NULL DEFAULT '',
  `trapoid` VARCHAR(100) NOT NULL DEFAULT '',
  `severity` VARCHAR(20) NOT NULL DEFAULT '',
  `varbinds` TEXT,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Equipment traps';

CREATE TABLE IF NOT EXISTS `equipment_backup` (

  `id` INT(11) UNSIGNED PRIMARY KEY,
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  `nas_id` SMALLINT(6) UNSIGNED REFERENCES `equipment_infos` (`nas_id`),
  `md5` VARCHAR(32) NOT NULL DEFAULT '',
  `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (`name`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Equipment backup description';

CREATE TABLE IF NOT EXISTS `equipment_graphs` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `nas_id` SMALLINT(6) UNSIGNED REFERENCES `equipment_infos` (`nas_id`),
  `port` VARCHAR(10) NOT NULL DEFAULT '',
  `param` VARCHAR(32) NOT NULL DEFAULT '',
  `comments` VARCHAR(80) NOT NULL DEFAULT '',
  `min_value` VARCHAR(10) NOT NULL DEFAULT '',
  `max_value` VARCHAR(10) NOT NULL DEFAULT '',
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `measure_type` VARCHAR(10) NOT NULL DEFAULT '',
  KEY (`nas_id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Equipment graph stats';

CREATE TABLE IF NOT EXISTS `equipment_graph_log` (
  `id` INT UNSIGNED NOT NULL DEFAULT 0 PRIMARY KEY,
  `value` VARCHAR(10) NOT NULL DEFAULT '',
  `datetime` DATETIME NOT NULL DEFAULT '0000-00-00'
)
  DEFAULT CHARSET=utf8 COMMENT = 'Equipment graph stats log';

CREATE TABLE IF NOT EXISTS `equipment_mac_log` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `mac` VARCHAR(17) NOT NULL DEFAULT '',
  `ip` INT UNSIGNED NOT NULL DEFAULT 0,
  `port` VARCHAR(20) NOT NULL DEFAULT '',
  `vlan` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `nas_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `datetime` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  `rem_time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `port_name` VARCHAR(50) NOT NULL DEFAULT '',
  UNIQUE KEY `mac_2` (`mac`, `port`, `vlan`, `nas_id`),
  KEY `mac` (`mac`),
  KEY `nas_id` (`nas_id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Equipment MAC log';

CREATE TABLE IF NOT EXISTS `equipment_pon_onu` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `port_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `onu_snmp_id` VARCHAR(30) NOT NULL DEFAULT '',
  `onu_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `onu_mac_serial` VARCHAR(20) NOT NULL DEFAULT '',
  `onu_desc` VARCHAR(50) NOT NULL DEFAULT '',
  `onu_billing_desc` VARCHAR(50) NOT NULL DEFAULT '',
  `olt_rx_power` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `onu_rx_power` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `onu_tx_power` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `onu_status` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `onu_in_byte` BIGINT(14) UNSIGNED NOT NULL DEFAULT '0',
  `onu_out_byte` BIGINT(14) UNSIGNED NOT NULL DEFAULT '0',
  `onu_dhcp_port` VARCHAR(20) NOT NULL DEFAULT '' COMMENT 'Internet main ports',
  `onu_graph` VARCHAR(50) NOT NULL DEFAULT 'SIGNAL,TEMPERATURE,SPEED',
  `datetime` DATETIME NOT NULL DEFAULT '0000-00-00',
  `line_profile` VARCHAR(50) NOT NULL DEFAULT 'ONU',
  `srv_profile` VARCHAR(50) NOT NULL DEFAULT 'ALL',
  `deleted` INT(1) UNSIGNED NOT NULL DEFAULT '0',
  `vlan` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY onu_dhcp_port (`onu_dhcp_port`),
  KEY onu_status (`onu_status`),
  KEY port_id (`port_id`),
  KEY onu_mac_serial (`onu_mac_serial`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Equipment ONU';

CREATE TABLE IF NOT EXISTS `equipment_pon_ports` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `snmp_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `nas_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `pon_type` VARCHAR(10) NOT NULL DEFAULT '',
  `branch` VARCHAR(20) NOT NULL DEFAULT '',
  `branch_desc` VARCHAR(30) NOT NULL DEFAULT '',
  `vlan_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY nas_id (`nas_id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Equipment PON ports';

CREATE TABLE IF NOT EXISTS `equipment_trap_types` (
  `id` smallint(2) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL DEFAULT '',
  `object_id` varchar(100) NOT NULL DEFAULT '',
  `type` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `event` tinyint(1) NOT NULL DEFAULT '0',
  `color` varchar(7) NOT NULL DEFAULT '',
  `skip` tinyint(1) NOT NULL DEFAULT '0',
  `varbind` varchar(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
)
  DEFAULT CHARSET = utf8 COMMENT = 'Equipment trap types';

CREATE TABLE IF NOT EXISTS `equipment_snmp_params` (
  `id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(32) NOT NULL DEFAULT '',
  `type` varchar(12) NOT NULL DEFAULT '',
  `acccess` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
)
  DEFAULT CHARSET = utf8 COMMENT = 'Equipment snmp params list';

CREATE TABLE IF NOT EXISTS `equipment_ping_log` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `date` DATETIME NOT NULL,
  `nas_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `status` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `duration` DOUBLE(12, 4) NOT NULL DEFAULT '0.0000'
)
  DEFAULT CHARSET=utf8 COMMENT = 'Equipment ping';

CREATE TABLE IF NOT EXISTS `equipment_tr_069_settings` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `onu_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `updatetime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `changetime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `settings` TEXT,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8 COMMENT = 'Equipment TR-069 Settings';

CREATE TABLE IF NOT EXISTS `equipment_calculator`(
    `type` VARCHAR(20) NOT NULL DEFAULT '',
    `name` VARCHAR(20) NOT NULL DEFAULT '',
    `value` VARCHAR(255) NOT NULL DEFAULT ''
)
  DEFAULT CHARSET=utf8 COMMENT = 'Equipment calculator';

INSERT INTO equipment_calculator (type, name, value) VALUES
('olt', 'SFP B+', '1.5'),
('olt', 'SFP', '0'),
('olt', 'SFP C+', '3'),
('olt', 'SFP C++', '5'),
('divider', '1/4', '7.4'),
('divider', '1/8', '10.7'),
('splitter', '40/60', '4.01;2.34'),
('splitter', '10/90', '10.2;0.6'),
('splitter', '85/15', '0.76;8.16'),
('splitter', '70/30', '1.56;5.39'),
('splitter', '95/5', '0.32;13.7'),
('splitter', '75/25', '1.42;6.29'),
('splitter', '5/95', '13.7;0.32'),
('splitter', '45/55', '2.71;3.73'),
('splitter', '80/20', '1.6;7.11'),
('splitter', '15/85', '8.16;0.76'),
('splitter', '60/40', '2.34;4.01'),
('splitter', '30/70', '5.39;1.56'),
('splitter', '65/35', '1.93;4.56'),
('splitter', '90/10', '0.6;10.2'),
('splitter', '50/50', '3.17;3.19'),
('splitter', '25/75', '6.29;1.42'),
('splitter', '35/65', '4.56;1.93'),
('splitter', '20/80', '7.11;1.6'),
('splitter', '55/45', '3.73;2.71'),
('connector', 'SIGNAL_LOSS', '0');
