CREATE TABLE IF NOT EXISTS `employees_cashboxes_moving`
(
    `id`              SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    `amount`          DOUBLE(10, 2)                    NOT NULL DEFAULT 0.00,
    `moving_type_id`  SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    `cashbox_spending`SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    `id_spending`     SMALLINT(6) UNSIGNED             NOT NULL DEFAULT 0,
    `cashbox_coming`  SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    `id_coming`       SMALLINT(6) UNSIGNED             NOT NULL DEFAULT 0,
    `date`            DATE                             NOT NULL DEFAULT '0000-00-00',
    `aid`             SMALLINT(6) UNSIGNED             NOT NULL DEFAULT 0,
    `comments`        TEXT,
    PRIMARY KEY (`id`),
    KEY `aid` (`aid`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Moving';

CREATE TABLE IF NOT EXISTS `employees_moving_types`
(
    `id`       SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    `name`     CHAR(40)                 NOT NULL DEFAULT '',
    `spending_type` TINYINT(4) UNSIGNED NOT NULL DEFAULT 0,
    `coming_type` TINYINT(4) UNSIGNED   NOT NULL DEFAULT 0,
    `comments` TEXT,
    PRIMARY KEY (`id`)
)
   DEFAULT CHARSET = utf8
   COMMENT = 'Moving types';

