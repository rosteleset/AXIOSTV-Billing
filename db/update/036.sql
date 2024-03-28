ALTER TABLE  `ippools`  ADD COLUMN `ipv6_mask` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE  `ippools`  ADD COLUMN `ipv6_template` VARBINARY(100) NOT NULL DEFAULT '';
ALTER TABLE  `ippools`  ADD COLUMN `ipv6_pd_mask` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE  `ippools`  ADD COLUMN `ipv6_pd_template` VARBINARY(100) NOT NULL DEFAULT '';
ALTER TABLE  `ippools`  ADD COLUMN `ipv6_pd` VARBINARY(16) NOT NULL DEFAULT '';
ALTER TABLE  `internet_online` ADD KEY nas_id (`nas_id`);
ALTER TABLE  `equipment_mac_log` ADD COLUMN `rem_time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00';

INSERT INTO  `config` (`param`, `value`, `domain_id`) VALUES ('UPDATE_SQL', '036.sql', 0);

ALTER TABLE  `equipment_infos` ADD COLUMN `internet_vlan` smallint(6) unsigned NOT NULL DEFAULT '0';
ALTER TABLE  `equipment_infos` ADD COLUMN `tr_069_vlan` smallint(6) unsigned NOT NULL DEFAULT '0';
ALTER TABLE  `equipment_infos` ADD COLUMN `iptv_vlan` smallint(6) unsigned NOT NULL DEFAULT '0';
