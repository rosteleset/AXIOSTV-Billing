ALTER TABLE sharing_users ADD FOREIGN KEY (file_id) REFERENCES sharing_files(id);

ALTER TABLE `msgs_messages` ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `msgs_chapters` ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';

ALTER TABLE `msgs_chapters` DROP INDEX `name`;
ALTER TABLE `msgs_chapters` ADD UNIQUE KEY `name` (`name`, `domain_id`);
ALTER TABLE poll_polls ADD COLUMN expiration_date DATE NOT NULL DEFAULT '0000-00-00';
ALTER TABLE `poll_polls` ADD COLUMN `domain_id` SMALLINT(6) NOT NULL DEFAULT 0;