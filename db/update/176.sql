ALTER TABLE `tarif_plans` ADD COLUMN `popular` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;


REPLACE INTO `fees_types` (`id`, `name`) VALUES (5, '$lang{CREDIT}');

CREATE TABLE IF NOT EXISTS `abon_categories` (
    `id`              SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`            VARCHAR(50) NOT NULL DEFAULT '',
    `dsc`             VARCHAR(80) NOT NULL DEFAULT '' COMMENT 'Description',
    `public_dsc`      VARCHAR(80) NOT NULL DEFAULT '' COMMENT 'Public description',
    `visible`         TINYINT(1)  NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`)
    )
    DEFAULT CHARSET = utf8
    COMMENT = 'Abon category';
ALTER TABLE `abon_tariffs` ADD COLUMN `category_id` SMALLINT(6) NOT NULL DEFAULT 0;
