ALTER TABLE `push_contacts` DROP INDEX `_type_id_endpoint`;
ALTER TABLE `push_contacts` DROP COLUMN `type`;
ALTER TABLE `push_contacts` DROP COLUMN `client_id`;
ALTER TABLE `push_contacts` DROP COLUMN `endpoint`;
ALTER TABLE `push_contacts` DROP COLUMN `key`;
ALTER TABLE `push_contacts` DROP COLUMN `auth`;

ALTER TABLE `push_contacts`
    ADD COLUMN `uid` INT(11) UNSIGNED    NOT NULL DEFAULT 0;
ALTER TABLE `push_contacts`
    ADD COLUMN `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `push_contacts`
    ADD COLUMN `type_id` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `push_contacts`
    ADD COLUMN `value` VARCHAR(210) NOT NULL DEFAULT '';

ALTER TABLE `push_contacts`
    ADD UNIQUE KEY `_type_id_value` (`value`);

ALTER TABLE `push_messages` DROP COLUMN `tag`;
ALTER TABLE `push_messages` DROP COLUMN `ttl`;
ALTER TABLE `push_messages` DROP COLUMN `contact_id`;

ALTER TABLE `push_messages`
    ADD COLUMN `status` SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `push_messages`
    ADD COLUMN `response` TEXT;
ALTER TABLE `push_messages`
    ADD COLUMN `request` TEXT;
ALTER TABLE `push_messages`
    ADD COLUMN `uid` INT(11) UNSIGNED    NOT NULL DEFAULT 0;
ALTER TABLE `push_messages`
    ADD COLUMN `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `push_messages`
    ADD COLUMN `type_id` TINYINT(2) UNSIGNED  NOT NULL DEFAULT 0;

ALTER TABLE `paysys_main`
    ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `paysys_groups_settings`
    ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `paysys_merchant_settings`
    ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `paysys_merchant_to_groups_settings`
    ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `crm_progressbar_step_comments`
    ADD COLUMN `priority` SMALLINT(6) UNSIGNED  NOT NULL DEFAULT 0;

ALTER TABLE `admins`
    ADD COLUMN `avatar_link` varchar(100) NOT NULL DEFAULT '';

ALTER TABLE `callcenter_calls_handler` ADD COLUMN `stop` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE `callcenter_calls_handler` ADD COLUMN `outgoing` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0';

CREATE TABLE IF NOT EXISTS `msgs_permits` (
  `aid`     SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `section` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `actions` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  UNIQUE KEY `aid_action` (`aid`, `section`, `actions`),
  KEY `aid` (`aid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Admin msgs permissions';

CREATE TABLE IF NOT EXISTS `msgs_type_permits` (
  `type`    VARCHAR(60)          NOT NULL DEFAULT '',
  `section` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `actions` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0'
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Msgs type permits';

REPLACE INTO `msgs_type_permits` (`type`, `section`, `actions`) VALUES
  ('$lang{ALL} $lang{PERMISSION}', 1, 0),
  ('$lang{ALL} $lang{PERMISSION}', 1, 1),
  ('$lang{ALL} $lang{PERMISSION}', 1, 2),
  ('$lang{ALL} $lang{PERMISSION}', 1, 3),
  ('$lang{ALL} $lang{PERMISSION}', 1, 4),
  ('$lang{ALL} $lang{PERMISSION}', 1, 5),
  ('$lang{ALL} $lang{PERMISSION}', 1, 6),
  ('$lang{ALL} $lang{PERMISSION}', 1, 7),
  ('$lang{ALL} $lang{PERMISSION}', 1, 8),
  ('$lang{ALL} $lang{PERMISSION}', 1, 9),
  ('$lang{ALL} $lang{PERMISSION}', 1, 10),
  ('$lang{ALL} $lang{PERMISSION}', 1, 11),
  ('$lang{ALL} $lang{PERMISSION}', 1, 12),
  ('$lang{ALL} $lang{PERMISSION}', 1, 13),
  ('$lang{ALL} $lang{PERMISSION}', 1, 14),
  ('$lang{ALL} $lang{PERMISSION}', 1, 15),
  ('$lang{ALL} $lang{PERMISSION}', 1, 16),
  ('$lang{ALL} $lang{PERMISSION}', 1, 17),
  ('$lang{ALL} $lang{PERMISSION}', 1, 18),
  ('$lang{ALL} $lang{PERMISSION}', 1, 19),
  ('$lang{ALL} $lang{PERMISSION}', 1, 20),
  ('$lang{ALL} $lang{PERMISSION}', 1, 22),
  ('$lang{ALL} $lang{PERMISSION}', 1, 23),
  ('$lang{ALL} $lang{PERMISSION}', 2, 0),
  ('$lang{ALL} $lang{PERMISSION}', 2, 1),
  ('$lang{ALL} $lang{PERMISSION}', 2, 2),
  ('$lang{ALL} $lang{PERMISSION}', 2, 3),
  ('$lang{ALL} $lang{PERMISSION}', 2, 4),
  ('$lang{ALL} $lang{PERMISSION}', 3, 0),
  ('$lang{ALL} $lang{PERMISSION}', 3, 1),
  ('$lang{ALL} $lang{PERMISSION}', 3, 2),
  ('$lang{ALL} $lang{PERMISSION}', 3, 3),
  ('$lang{ALL} $lang{PERMISSION}', 3, 4),
  ('$lang{ALL} $lang{PERMISSION}', 5, 0),
  ('$lang{ALL} $lang{PERMISSION}', 5, 1),
  ('$lang{ALL} $lang{PERMISSION}', 5, 5),
  ('$lang{ALL} $lang{PERMISSION}', 5, 6),
  ('$lang{ALL} $lang{PERMISSION}', 5, 9),
  ('$lang{ALL} $lang{PERMISSION}', 5, 10),
  ('$lang{ALL} $lang{PERMISSION}', 5, 13),
  ('$lang{ALL} $lang{PERMISSION}', 5, 14);