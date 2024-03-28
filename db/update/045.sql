ALTER TABLE `crm_salaries_payed` DROP PRIMARY KEY;
ALTER TABLE `crm_salaries_payed` ADD COLUMN `id` INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT;

ALTER TABLE `crm_leads` ADD COLUMN `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0';

ALTER TABLE equipment_pon_onu ADD COLUMN vlan smallint(6) unsigned NOT NULL DEFAULT '0';

ALTER TABLE price_services_list ADD COLUMN `type` int(10) unsigned DEFAULT NULL;