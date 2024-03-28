UPDATE equipment_models SET snmp_tpl = 'gcom.snmp' WHERE vendor_id = 33 AND snmp_tpl = '';

ALTER TABLE `paysys_main` ADD `order_id` varchar(24) NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS `tp_groups_users_groups` (
  `id`          SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `tp_gid`      SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `gid`         SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `tp_gid` (`tp_gid`),
  KEY `gid` (`gid`)
  )
  DEFAULT CHARSET = utf8
  COMMENT = 'Users groups for Tarif Plans Groups';