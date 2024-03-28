ALTER TABLE accident_address MODIFY `id` INT(11) UNSIGNED NOT NULL auto_increment;
ALTER TABLE accident_address DROP FOREIGN KEY address;
ALTER TABLE accident_address MODIFY `ac_id` INT(11) UNSIGNED NOT NULL;
ALTER TABLE accident_address
ADD CONSTRAINT address
FOREIGN KEY (`ac_id`) REFERENCES `accident_log` (`id`) ON DELETE CASCADE;
ALTER TABLE accident_address MODIFY `address_id` VARCHAR(255) NOT NULL;

ALTER TABLE accident_log MODIFY `name` VARCHAR(255) NOT NULL DEFAULT '';