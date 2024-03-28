
# delete links for unexistent commutations
DELETE FROM cablecat_links WHERE commutation_id NOT IN (SELECT id from cablecat_commutations);

# CABLE

# delete links for unexistent elements
DELETE FROM cablecat_links WHERE element_1_type='CABLE' AND element_1_id
    NOT IN (SELECT id FROM cablecat_cables);
DELETE FROM cablecat_links WHERE element_2_type='CABLE' AND element_2_id
    NOT IN (SELECT id FROM cablecat_cables);

# delete links for existent element but not present on commutation
DELETE FROM cablecat_links WHERE element_1_type='CABLE' AND element_1_id
    NOT IN (SELECT id FROM cablecat_commutation_cables ccc WHERE ccc.commutation_id <> cablecat_links.commutation_id );

# SPLITTER
# delete splitters not present on commutation
# DELETE FROM cablecat_splitters WHERE commutation_id=0 OR commutation_id NOT IN (SELECT id FROM cablecat_commutations);

# delete links for unexistent elements
DELETE FROM cablecat_links WHERE
  (element_1_type='SPLITTER' AND element_1_id NOT IN (SELECT cablecat_splitters.id FROM cablecat_splitters))
      OR
      (element_2_type='SPLITTER' AND element_2_id NOT IN (SELECT cablecat_splitters.id FROM cablecat_splitters));

# delete links for elements not present on commutation
DELETE FROM cablecat_links WHERE (element_1_type='SPLITTER' OR element_2_type='SPLITTER') AND commutation_id
    NOT IN (SELECT cablecat_splitters.commutation_id FROM cablecat_splitters);