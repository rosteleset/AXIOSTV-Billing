ALTER TABLE `config_variables` ADD COLUMN `regex` VARCHAR(100) NOT NULL DEFAULT '';

ALTER TABLE `info_documents` ADD COLUMN `comment_id` SMALLINT(6) NOT NULL DEFAULT 0;
ALTER TABLE `info_comments` MODIFY COLUMN `text` TEXT;