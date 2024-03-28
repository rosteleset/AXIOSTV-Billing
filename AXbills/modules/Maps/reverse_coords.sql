ALTER TABLE maps_coords ADD COLUMN tempx DOUBLE;
UPDATE maps_coords SET tempx=coordx;
UPDATE maps_coords SET coordx=coordy WHERE coordx < 0;
UPDATE maps_coords SET coordy=tempx WHERE coordy > 0;
ALTER TABLE maps_coords DROP COLUMN tempx;

ALTER TABLE maps_polyline_points ADD COLUMN tempx DOUBLE;
UPDATE maps_polyline_points SET tempx=coordx;
UPDATE maps_polyline_points SET coordx=coordy WHERE coordx < 0;
UPDATE maps_polyline_points SET coordy=tempx WHERE coordy > 0;
ALTER TABLE maps_polyline_points DROP COLUMN tempx;

ALTER TABLE maps_polygon_points ADD COLUMN tempx DOUBLE;
UPDATE maps_polygon_points SET tempx=coordx;
UPDATE maps_polygon_points SET coordx=coordy WHERE coordx < 0;
UPDATE maps_polygon_points SET coordy=tempx WHERE coordy > 0;
ALTER TABLE maps_polygon_points DROP COLUMN tempx;

# ALTER TABLE builds ADD COLUMN tempx DOUBLE;
# UPDATE builds SET tempx=coordx;
# UPDATE builds SET coordx=coordy WHERE coordx > 0;
# UPDATE builds SET coordy=tempx WHERE coordy < 0;
# ALTER TABLE builds DROP COLUMN tempx;

# Clear unlinked polylines
# DELETE FROM maps_points WHERE type_id=7 AND id NOT IN (SELECT point_id FROM cablecat_cables);
# DELETE FROM maps_polylines WHERE layer_id=10 AND object_id NOT IN (SELECT id FROM maps_points);
# DELETE FROM maps_polyline_points WHERE polyline_id NOT IN (SELECT id FROM maps_polylines);
