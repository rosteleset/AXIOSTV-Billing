ALTER TABLE `extfin_paids_types` ADD COLUMN `month_alignment` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `extfin_paids_types` ADD COLUMN `sum` DOUBLE(14, 6) NOT NULL DEFAULT '0.000000' AFTER `name`;

ALTER TABLE `extfin_paids_periodic` ADD COLUMN `expire` DATE NOT NULL DEFAULT '0000-00-00' AFTER `date`;

ALTER TABLE `extfin_paids_periodic` ADD COLUMN `activate` DATE NOT NULL DEFAULT '0000-00-00' AFTER `date`;

ALTER TABLE `errors_log` ADD COLUMN `request_count` INT(11) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `cards_users` ADD COLUMN `gid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';

CREATE TABLE IF NOT EXISTS `internet_filters`
(
    `id`          SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
    `filter`      VARCHAR(100)         NOT NULL DEFAULT '',
    `params`      VARCHAR(200)         NOT NULL DEFAULT '',
    `descr`       VARCHAR(200)         NOT NULL DEFAULT '',
    `user_portal` TINYINT(1)           NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `filter` (`filter`)
) DEFAULT CHARSET = utf8
    COMMENT = 'Internet filters list';
ALTER TABLE `referral_tp` ADD COLUMN `spend_percent` SMALLINT(3) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `referral_tp` ADD COLUMN `is_default` SMALLINT(1) DEFAULT 0 NOT NULL;
ALTER TABLE `referral_log` ADD COLUMN `log_type` SMALLINT(1) UNSIGNED NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS callcenter_ivr_menu_chapters
(
    id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name    VARCHAR(20)  NOT NULL  DEFAULT '',
    numbers VARCHAR(200) NULL NULL DEFAULT '',
    UNIQUE KEY (id)
)
    DEFAULT CHARSET = utf8
    comment 'IVR menus chapters';

ALTER TABLE `callcenter_ivr_menu` ADD COLUMN `chapter_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0';

ALTER TABLE msgs_address DROP FOREIGN KEY `msgs_id`;