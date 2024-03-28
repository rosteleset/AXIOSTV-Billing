SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `api_log`
(
    `id`              INT(11) UNSIGNED     NOT NULL AUTO_INCREMENT,
    `aid`             SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `uid`             INT(11) UNSIGNED     NOT NULL DEFAULT '0',
    `sid`             VARCHAR(32)          NOT NULL DEFAULT '',
    `ip`              INT(11) UNSIGNED     NOT NULL DEFAULT '0',
    `date`            DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `request_url`     TEXT                 NOT NULL,
    `request_body`    TEXT                 NOT NULL,
    `request_headers` TEXT                 NOT NULL,
    `response_time`   DOUBLE(7, 5)         NOT NULL DEFAULT '0.00000',
    `response`        TEXT                 NOT NULL,
    `http_status`     SMALLINT(3) UNSIGNED NOT NULL DEFAULT '0',
    `http_method`     VARCHAR(10)          NOT NULL DEFAULT '',
    `error_msg`       TEXT                 NOT NULL DEFAULT '',
    PRIMARY KEY (`id`)
)
    CHARSET = utf8
    COMMENT = 'Api log';
