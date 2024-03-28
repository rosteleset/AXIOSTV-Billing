ALTER TABLE `maps_polylines` ADD KEY `object_id` (`object_id`);
ALTER TABLE `maps_points` ADD KEY `location_id` (`location_id`);
ALTER TABLE `maps_polygons` ADD KEY `object_id` (`object_id`);
ALTER TABLE `maps_polygon_points` ADD KEY `polygon_id` (`polygon_id`);

ALTER TABLE `storage_sn` ADD KEY `storage_installation_id` (`storage_installation_id`);

ALTER TABLE `payments_type` ADD `default_payment` TINYINT(3) DEFAULT 0 NULL;