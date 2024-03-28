UPDATE equipment_models SET snmp_tpl = 'dlink.snmp' WHERE id = 123;
UPDATE equipment_models SET snmp_tpl = 'dlink.snmp' WHERE id = 149;
UPDATE equipment_models SET snmp_tpl = 'dlink_des_1210_28_me_b3.snmp' WHERE id = 205;

ALTER TABLE `cablecat_splitters` ADD COLUMN `name` VARCHAR(32) NOT NULL DEFAULT '';

ALTER TABLE `cablecat_splitters` MODIFY `commutation_x` DOUBLE(6, 2) NULL;
ALTER TABLE `cablecat_splitters` MODIFY `commutation_y` DOUBLE(6, 2) NULL;
ALTER TABLE `cablecat_commutation_equipment` MODIFY `commutation_x` DOUBLE(6, 2) NULL;
ALTER TABLE `cablecat_commutation_equipment` MODIFY `commutation_y` DOUBLE(6, 2) NULL;
ALTER TABLE `cablecat_commutation_crosses` MODIFY `commutation_x` DOUBLE(6, 2) NULL;
ALTER TABLE `cablecat_commutation_crosses` MODIFY `commutation_y` DOUBLE(6, 2) NULL;
ALTER TABLE `cablecat_commutations` ADD COLUMN `height` DOUBLE(6, 2) NULL;

ALTER TABLE `equipment_models` ADD COLUMN image_url VARCHAR(500) DEFAULT '';
UPDATE equipment_models SET image_url = 'https://www.edge-core.com/timthumb.php?src=_upload/images/1605181111021.png&h=357&w=490&zc=3' WHERE id = 158;
UPDATE equipment_models SET image_url = 'https://i.mt.lv/cdn/rb_images/1606_l.jpg' WHERE id = 161;
UPDATE equipment_models SET image_url = 'https://www.juniper.net/assets/img/products/image-library/mx-series/mx80/mx80-front-high.jpg' WHERE id = 162;
UPDATE equipment_models SET image_url = 'https://www.dlink.ru/up/prod_fotos/DGS-1100-06ME_A1_Front.jpg' WHERE id = 232;
UPDATE equipment_models SET image_url = 'https://eltex-co.ru/upload/iblock/32f/olt-ma4000_px_front.png' WHERE id = 262;

ALTER TABLE `extreceipts_api` ADD COLUMN `conf_name` VARCHAR(50) NOT NULL DEFAULT '' AFTER api_id;
