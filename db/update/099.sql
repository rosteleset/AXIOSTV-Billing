ALTER TABLE `paysys_main` ADD COLUMN `subscribe_date_start` DATE NOT NULL DEFAULT '0000-00-00';

ALTER TABLE `groups` ADD COLUMN `disable_payments` TINYINT(1) UNSIGNED  NOT NULL DEFAULT 0;

ALTER TABLE `notepad` ADD COLUMN `start_stat` TIME NOT NULL DEFAULT '00:00:00';
ALTER TABLE `notepad` ADD COLUMN `end_stat` TIME NOT NULL DEFAULT '00:00:00';
ALTER TABLE `notepad` MODIFY `show_at` DATE NOT NULL;
ALTER TABLE `payments_type` ADD COLUMN `fees_type` TINYINT(4) UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `equipment_pon_onu` ADD KEY onu_mac_serial (`onu_mac_serial`);
ALTER TABLE `equipment_pon_ports` ADD KEY nas_id (`nas_id`);
ALTER TABLE `internet_main` ADD KEY `cpe_mac` (`cpe_mac`);

CREATE TABLE IF NOT EXISTS `paysys_city24_report` (
  `id`             SMALLINT UNSIGNED      NOT NULL AUTO_INCREMENT,
  `sum`            DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `date`           DATETIME               NOT NULL DEFAULT '0000-00-00 00:00:00',
  `transaction_id` VARCHAR(24)            NOT NULL DEFAULT '',
  `user_key`       VARCHAR(16)            NOT NULL DEFAULT '',
  PRIMARY KEY `id` (`id`),
  UNIQUE `transaction_id` (`transaction_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Paysys city24 report';