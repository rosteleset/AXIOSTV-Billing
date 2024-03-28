ALTER TABLE `msgs_unreg_requests` ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `msgs_dispatch` ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';


CREATE TABLE IF NOT EXISTS `msgs_storage` (
  `id`                           INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `msgs_id`                      INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `installation_id` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  `date`                         DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `aid`                          SMALLINT(6)      NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) DEFAULT CHARSET = utf8 COMMENT = 'Storage items to msgs tickets';