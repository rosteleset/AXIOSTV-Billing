ALTER TABLE `api_log`
    ADD COLUMN `request_headers` TEXT;
ALTER TABLE `api_log`
    ADD COLUMN `error_msg` TEXT;
ALTER TABLE `paysys_requests`
    ADD COLUMN `request_type` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `paysys_requests`
    ADD COLUMN `sum` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00';
