ALTER TABLE `paysys_main` ADD COLUMN `recurrent_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `paysys_main` ADD COLUMN `recurrent_cron` VARCHAR(25) NOT NULL DEFAULT '';
ALTER TABLE `paysys_main` ADD COLUMN `recurrent_module` VARCHAR(25) NOT NULL DEFAULT '';
ALTER TABLE `config` MODIFY COLUMN `value` VARCHAR(400) NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS `referral_log` (
    `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `uid` INT(11) UNSIGNED NOT NULL REFERENCES `users` (`uid`)
    ON DELETE CASCADE,
    `referrer` INT(11) UNSIGNED NOT NULL REFERENCES `users` (`uid`)
    ON DELETE CASCADE,
    `date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
)
  COMMENT = 'Referral log table stores information about periodic referrals';
CREATE TABLE IF NOT EXISTS  `storage_inventory` (
  `incoming_article_id` INT(10) UNSIGNED DEFAULT '0',
  `date` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  UNIQUE KEY (`incoming_article_id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Storage inventory info';

ALTER TABLE `msgs_chapters` ADD COLUMN `color` VARCHAR(7) NOT NULL DEFAULT '';

ALTER TABLE msgs_unreg_requests ADD referral_uid INTEGER(11) NOT NULL DEFAULT '0';

CREATE TABLE IF NOT EXISTS `referral_tp` (
    `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR (60) NOT NULL DEFAULT '',
    `bonus_amount` DOUBLE(10, 2) UNSIGNED NOT NULL  DEFAULT '0.00',
    `payment_arrears` int(11) UNSIGNED NOT NULL  DEFAULT '0',
    `period` int(11) UNSIGNED NOT NULL  DEFAULT '0',
    `repl_percent` int(3) UNSIGNED NOT NULL  DEFAULT '0',
    `bonus_bill` int(1) UNSIGNED NOT NULL  DEFAULT '0'
)
  DEFAULT CHARSET=utf8 COMMENT = 'Referral tp table stores information about referral tarifs';