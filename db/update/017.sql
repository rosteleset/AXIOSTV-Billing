INSERT INTO `maps_coords` (`coordx`, `coordy`)
SELECT `coordx`, `coordy` 
FROM `builds`
WHERE `coordx` != 0;

INSERT INTO `maps_points` ( `location_id`, `type_id`, `coord_id`)
SELECT `builds.id`, 3, `maps_coords.id`
FROM `builds` LEFT JOIN `maps_coords` 
ON (`builds.coordx` = `maps_coords.coordx` 
AND `builds.coordy` = `maps_coords.coordy` 
AND `builds.coordx` !=0) ;
ALTER TABLE `cablecat_splitters` ADD COLUMN `commutation_id` INT(11) UNSIGNED REFERENCES `cablecat_commutations` (`id`)
ON DELETE RESTRICT;

ALTER TABLE `cablecat_splitters` DROP COLUMN `commutation_x`;
ALTER TABLE `cablecat_splitters` DROP COLUMN `commutation_y`;
ALTER TABLE `cablecat_splitters` ADD COLUMN `commutation_x` DOUBLE (5,2);
ALTER TABLE `cablecat_splitters` ADD COLUMN `commutation_y` DOUBLE (5,2);

