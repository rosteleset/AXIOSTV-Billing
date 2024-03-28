ALTER TABLE cablecat_links ADD COLUMN `cross_id` INT(11) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE cablecat_links ADD COLUMN `cross_port` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `msgs_status` ADD COLUMN `icon` VARCHAR(30) NOT NULL DEFAULT '';

SET SESSION sql_mode = 'NO_AUTO_VALUE_ON_ZERO';
REPLACE INTO `msgs_status` (`id`, `name`, `readiness`, `task_closed`, `color`, `icon`) VALUES
  ('0', '$lang{OPEN}',                             '0',   '0', '#0000FF', 'fa fa-envelope-open text-aqua'),
  ('1', '$lang{CLOSED_UNSUCCESSFUL}',              '100', '1', '#ff0638', 'fa fa-warning text-red'),
  ('2', '$lang{CLOSED_SUCCESSFUL}',                '100', '1', '#009D00', 'fa fa-check text-green'),
  ('3', '$lang{IN_WORK}',                          '10',  '0', '#707070', 'fa fa-wrench'),
  ('4', '$lang{NEW_MESSAGE}',                      '0',   '0', '#FF8000', 'fa fa-reply text-blue'),
  ('5', '$lang{HOLD_UP}',                          '0',   '0', '0',       'far fa-clock'),
  ('6', '$lang{ANSWER_WAIT}',                      '50',  '0', '',        'far fa-envelope-open'),
  ('9', '$lang{NOTIFICATION_MSG}',                 '0',   '0', '',        'fa fa-flag text-red'),
  ('10', '$lang{NOTIFICATION_MSG}  $lang{READED}', '100', '0', '',        'far fa-flag text-red'),
  ('11', '$lang{POTENTIAL_CLIENT}',                '0',   '0', '',        'fa fa-user-plus text-green');

ALTER TABLE `msgs_proggress_bar` ADD COLUMN `user_notice` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `msgs_proggress_bar` ADD COLUMN `responsible_notice` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `msgs_proggress_bar` ADD COLUMN `follower_notice` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `msgs_chapters` ADD COLUMN `responsible` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;

CREATE TABLE `domains_modules` (
  `id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `module` varchar(12) NOT NULL DEFAULT '',
  UNIQUE KEY `id_module` (`id`,`module`),
  KEY `id` (`id`)
) COMMENT='Domains module permissions'
