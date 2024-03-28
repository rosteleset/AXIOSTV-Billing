ALTER TABLE `storage_incoming_articles` ADD COLUMN `fees_method` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0';

ALTER TABLE `storage_incoming_articles` ADD COLUMN `abon_distribution` TINYINT(1) NOT NULL DEFAULT '0';

ALTER TABLE `cablecat_cables` ADD FOREIGN KEY `type_id` (`type_id`) REFERENCES `cablecat_cable_types` (`id`);

CREATE TABLE IF NOT EXISTS `paysys_global_money_report` (
  `id`             SMALLINT UNSIGNED      NOT NULL  AUTO_INCREMENT,
  `uid`            INT(11) UNSIGNED       NOT NULL  DEFAULT '0',
  `sum`            DOUBLE(10, 2) UNSIGNED NOT NULL  DEFAULT '0.00',
  `date`           DATETIME               NOT NULL  DEFAULT '0000-00-00 00:00:00',
  `transaction_id` VARCHAR(24) NOT NULL DEFAULT '',
  `description`    VARCHAR(200)           NOT NULL  DEFAULT '',
  PRIMARY KEY `id` (`id`),
  UNIQUE `transaction_id` (`transaction_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Paysys global_money report';