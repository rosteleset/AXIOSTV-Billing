CREATE TABLE IF NOT EXISTS `crm_tp_info_fields` (
  `id`          TINYINT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(60)          NOT NULL DEFAULT '',
  `sql_field`   VARCHAR(60)          NOT NULL DEFAULT '',
  `type`        TINYINT(2) UNSIGNED  NOT NULL DEFAULT 0,
  `priority`    TINYINT(1) UNSIGNED  NOT NULL DEFAULT 0,
  `comment`     VARCHAR(60)          NOT NULL DEFAULT '',
  `pattern`     VARCHAR(60)          NOT NULL DEFAULT '',
  `title`       VARCHAR(255)         NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY (`name`),
  UNIQUE KEY (`sql_field`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm Tariff plans info fields';

RENAME TABLE `payments_spool` TO `payments_pool`;

ALTER TABLE `payments_pool` DROP COLUMN `date`;
ALTER TABLE `payments_pool` DROP COLUMN `sum`;
ALTER TABLE `payments_pool` DROP COLUMN `dsc`;
ALTER TABLE `payments_pool` DROP COLUMN `uid`;
ALTER TABLE `payments_pool` DROP COLUMN `method`;
ALTER TABLE `payments_pool` DROP COLUMN `ext_id`;
ALTER TABLE `payments_pool` DROP COLUMN `bill_id`;
ALTER TABLE `payments_pool` DROP COLUMN `currency`;
ALTER TABLE `payments_pool` ADD COLUMN `payment_id` varchar(28) NOT NULL DEFAULT '';
ALTER TABLE `payments_pool` ADD COLUMN  `status` TINYINT(1) UNSIGNED  NOT NULL DEFAULT '0';
ALTER TABLE `payments_pool` DROP KEY `date`;
ALTER TABLE `payments_pool` DROP KEY `uid`;
ALTER TABLE `payments_pool` DROP KEY `ext_id`;
ALTER TABLE `payments_pool` ADD KEY `payment_id` (`payment_id`);
