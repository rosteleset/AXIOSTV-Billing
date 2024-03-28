CREATE TABLE IF NOT EXISTS `fees_last` (
    `uid` int(11) unsigned NOT NULL DEFAULT '0',
    `fees_id`   int(11) unsigned NOT NULL,
    `sum`  double(12,4) NOT NULL DEFAULT '0.0000',
    `date` DATETIME   NOT NULL,
    PRIMARY KEY `uid` (`uid`)
    )
    DEFAULT CHARSET = utf8
    COMMENT = 'Last fees';

ALTER TABLE `portal_articles` MODIFY COLUMN `gid` SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `portal_articles` MODIFY COLUMN `tags` SMALLINT(5) UNSIGNED NOT NULL DEFAULT 0;


ALTER TABLE `abon_tariffs` ADD COLUMN `user_description` TEXT NOT NULL DEFAULT '' COMMENT 'User portal describe';
ALTER TABLE `abon_tariffs` ADD COLUMN `service_recovery` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Service recovery mode';
ALTER TABLE `abon_tariffs` ADD COLUMN `service_img` VARCHAR(240) NOT NULL DEFAULT '';
ALTER TABLE `abon_tariffs` ADD COLUMN `module` VARCHAR(24) NOT NULL DEFAULT '' COMMENT 'Service plugin';
ALTER TABLE `abon_tariffs` ADD COLUMN `login` VARCHAR(72) NOT NULL DEFAULT '' COMMENT 'API Login';
ALTER TABLE `abon_tariffs` ADD COLUMN `password` BLOB COMMENT 'API Password';
ALTER TABLE `abon_tariffs` ADD COLUMN `url` VARCHAR(120) NOT NULL DEFAULT '' COMMENT 'API url';
ALTER TABLE `abon_tariffs` ADD COLUMN `debug` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'API DEBUG';
ALTER TABLE `abon_tariffs` ADD COLUMN `debug_file` VARCHAR(120) NOT NULL DEFAULT '' COMMENT 'API DEBUG file';

