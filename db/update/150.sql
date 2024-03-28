ALTER TABLE `storage_articles` ADD COLUMN `equipment_model_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `storage_incoming_articles` ADD COLUMN `public_sale` TINYINT(1) NOT NULL DEFAULT '0';

ALTER TABLE `groups` ADD COLUMN `documents_access` TINYINT(1) UNSIGNED  NOT NULL DEFAULT 0;
UPDATE `groups` SET `documents_access` = 1;