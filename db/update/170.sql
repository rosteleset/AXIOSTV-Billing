ALTER TABLE `admins` ADD COLUMN `location_id` INT(11) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `admins` ADD COLUMN `address_flat` VARCHAR(10) NOT NULL DEFAULT '';

ALTER TABLE `crm_actions` ADD COLUMN `send_message` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `crm_actions` ADD COLUMN `subject` VARCHAR(150) NOT NULL DEFAULT '';
ALTER TABLE `crm_actions` ADD COLUMN `message` TEXT NOT NULL;

ALTER TABLE `referral_tp` ADD COLUMN `max_bonus_amount` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT 0.00;
ALTER TABLE `referral_tp` ADD COLUMN `static_accrual`  SMALLINT(1) NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `referral_users_bonus`
(
  `uid`        INT(11) UNSIGNED       NOT NULL REFERENCES `users` (`uid`) ON DELETE CASCADE,
  `referrer`   INT(11) UNSIGNED       NOT NULL REFERENCES `users` (`uid`) ON DELETE CASCADE,
  `sum`        DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `payment_id` INT(11) UNSIGNED       NOT NULL DEFAULT 0,
  `fee_id`     INT(11) UNSIGNED       NOT NULL DEFAULT 0,
  `date`       TIMESTAMP              NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY uid (`uid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Referral payments and fees bonus for user';

ALTER TABLE `cams_tp` ADD COLUMN `archive` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `abon_user_list` ADD COLUMN `personal_description` VARCHAR(240) NOT NULL DEFAULT '';

ALTER TABLE `groups` ADD COLUMN `disable_access` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;
