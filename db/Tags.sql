SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `tags` (
    `id`       SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
    `priority` TINYINT(4) UNSIGNED  NOT NULL DEFAULT '0',
    `name`     VARCHAR(20)          NOT NULL DEFAULT '',
    `comments` TEXT,
    `color`    VARCHAR(7) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`)
)
    COMMENT = 'Tags';


CREATE TABLE IF NOT EXISTS `tags_users` (
    `uid`    INT(10) UNSIGNED     NOT NULL DEFAULT '0',
    `tag_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
    `date`   DATE                 NOT NULL DEFAULT '0000-00-00',
    UNIQUE KEY `uid_tag_id` (`uid`, `tag_id`)
)
    COMMENT = 'Users Tags';

CREATE TABLE IF NOT EXISTS `tags_responsible` (
    `id`      SMALLINT(3) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `aid`     SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,
    `tags_id` SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,

    CONSTRAINT `tags_id_fk` FOREIGN KEY (`tags_id`) REFERENCES `tags` (`id`),
    KEY `aid` (`aid`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Tags responsible';