ALTER TABLE `storage_installation` ADD COLUMN `monthes` SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `storage_installation` ADD COLUMN `amount_per_month` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00';
ALTER TABLE `storage_incoming_articles` ADD COLUMN `in_installments_price` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00';
ALTER TABLE `docs_invoice_orders` ADD COLUMN `fees_type` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `abon_tariffs` ADD COLUMN `description` VARCHAR(240) NOT NULL DEFAULT '';
ALTER TABLE `filters` ADD COLUMN `params` VARCHAR(200) NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS `taxes` ( 
  `id`            SMALLINT(6) UNSIGNED  NOT NULL AUTO_INCREMENT,
  `ratecode`      VARCHAR(30)           NOT NULL DEFAULT '',
  `ratedescr`     VARCHAR(130)          NOT NULL DEFAULT '',
  `rateamount`    TINYINT(100) UNSIGNED NOT NULL DEFAULT '0',
  `current`       TINYINT(2) UNSIGNED   NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Tax Magazine';



