CREATE TABLE IF NOT EXISTS  `storage_invoices_payments` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `invoice_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT 0,
  `sum` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `actual_sum` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `date` DATETIME NOT NULL,
  `aid` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT,
  PRIMARY KEY (`id`),
  KEY `invoice_id` (`invoice_id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Storage payments for invoice';

ALTER TABLE `storage_inner_use` ADD COLUMN `responsible` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `ippools_ips` (
  `ip`        int(10) unsigned     NOT NULL DEFAULT '0',
  `status`    tinyint(3) unsigned  NOT NULL DEFAULT '0',
  `ippool_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  UNIQUE KEY `ip` (`ip`, `ippool_id`),
  KEY `ip_status` (`ip`, `status`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'IP Pools ips';

ALTER TABLE referral_log ADD tp_id int NOT NULL;

ALTER TABLE `extreceipts` ADD COLUMN `api` VARCHAR(20) NOT NULL DEFAULT '';
ALTER TABLE `extreceipts` MODIFY COLUMN `command_id` VARCHAR(60) NOT NULL DEFAULT '';
ALTER TABLE `extreceipts` MODIFY COLUMN `cancel_id` VARCHAR(60) NOT NULL DEFAULT '';