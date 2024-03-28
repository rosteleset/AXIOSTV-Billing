SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

ALTER TABLE `referral_tp` ADD COLUMN `inactive_days` SMALLINT(3) NOT NULL DEFAULT 0  COMMENT 'Quantity of users inactive days';
ALTER TABLE `referral_requests` ADD COLUMN `inner_comments` VARCHAR(200) NOT NULL DEFAULT '';
