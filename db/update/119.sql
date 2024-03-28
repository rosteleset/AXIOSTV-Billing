ALTER TABLE `cablecat_commutations` ADD COLUMN `name` VARCHAR(64) NOT NULL DEFAULT '';
UPDATE equipment_models SET image_url = 'https://ecolan.com.ua/components/com_jshopping/files/img_products/full_zte_c300_3.jpg' WHERE id = 306;
ALTER TABLE equipment_mac_log MODIFY port VARCHAR(16) NOT NULL DEFAULT '';

ALTER TABLE `maps_points` MODIFY `name` VARCHAR(64) NOT NULL DEFAULT '';