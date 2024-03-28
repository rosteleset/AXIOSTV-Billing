SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `paysys_log`
(
    `id`             INT(11) UNSIGNED       NOT NULL AUTO_INCREMENT,
    `system_id`      TINYINT(4) UNSIGNED    NOT NULL DEFAULT '0',
    `datetime`       DATETIME               NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `sum`            DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `commission`     DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `uid`            INT(11) UNSIGNED       NOT NULL DEFAULT '0',
    `transaction_id` VARCHAR(24)            NOT NULL DEFAULT '',
    `info`           TEXT                   NOT NULL,
    `ip`             INT(11) UNSIGNED       NOT NULL DEFAULT '0',
    `code`           BLOB                   NOT NULL,
    `paysys_ip`      INT(11) UNSIGNED       NOT NULL DEFAULT '0',
    `domain_id`      SMALLINT(6) UNSIGNED   NOT NULL DEFAULT '0',
    `status`         TINYINT(2) UNSIGNED    NOT NULL DEFAULT '0',
    `user_info`      varchar(120)                    DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `id` (`id`),
    UNIQUE KEY `ps_transaction_id` (`domain_id`, `transaction_id`)
)
    CHARSET = 'utf8'
    COMMENT = 'Paysys log';

CREATE TABLE IF NOT EXISTS `paysys_main`
(
    `uid`                  INT(11) UNSIGNED     NOT NULL DEFAULT '0',
    `token`                TINYTEXT,
    `sum`                  DOUBLE(10, 2)        NOT NULL DEFAULT '0.00',
    `date`                 DATE                 NOT NULL,
    `paysys_id`            SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
    `external_last_date`   DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `attempts`             SMALLINT(2)          NOT NULL DEFAULT 0,
    `closed`               SMALLINT(1)          NOT NULL DEFAULT 0,
    `external_user_ip`     INT(11) UNSIGNED     NOT NULL DEFAULT 0,
    `recurrent_id`         SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `recurrent_cron`       VARCHAR(25)          NOT NULL DEFAULT '',
    `recurrent_module`     VARCHAR(25)          NOT NULL DEFAULT '',
    `order_id`             varchar(24)          NOT NULL DEFAULT '',
    `subscribe_date_start` DATE                 NOT NULL DEFAULT '0000-00-00',
    `domain_id`            SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    UNIQUE (`uid`, `paysys_id`)
)
    CHARSET = 'utf8'
    COMMENT = 'Paysys user account';

CREATE TABLE IF NOT EXISTS `paysys_terminals`
(
    `id`          INT(11) UNSIGNED     NOT NULL AUTO_INCREMENT,
    `type`        SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `status`      SMALLINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `location_id` INT(11) UNSIGNED     NOT NULL DEFAULT 0,
    `work_days`   SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,
    `start_work`  TIME                 NOT NULL DEFAULT '00:00:00',
    `end_work`    TIME                 NOT NULL DEFAULT '00:00:00',
    `comment`     TEXT,
    `description` TEXT,
    PRIMARY KEY `id` (`id`)
)
    CHARSET = 'utf8'
    COMMENT = 'Table for paysys terminals';

CREATE TABLE IF NOT EXISTS `paysys_terminals_types`
(
    `id`      INT(3) UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`    VARCHAR(40)     NOT NULL DEFAULT '',
    `comment` TEXT,
    PRIMARY KEY `id` (`id`)
)
    CHARSET = 'utf8'
    COMMENT = 'Table for paysys terminals types';

CREATE TABLE IF NOT EXISTS `paysys_tyme_report`
(
    `id`       INT(10) UNSIGNED       NOT NULL AUTO_INCREMENT,
    `txn_id`   BIGINT(20) UNSIGNED    NOT NULL DEFAULT '0',
    `date`     DATETIME               NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `user`     VARCHAR(20)            NOT NULL DEFAULT '',
    `sum`      DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `terminal` INT(10) UNSIGNED       NOT NULL DEFAULT '0',
    PRIMARY KEY `id` (`id`),
    UNIQUE KEY `txn_id` (`txn_id`)
)
    CHARSET = 'utf8'
    COMMENT = 'Table for Tyme report';

CREATE TABLE IF NOT EXISTS `paysys_ipay_report`
(
    `id`             SMALLINT UNSIGNED      NOT NULL AUTO_INCREMENT,
    `sum`            DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `date`           DATETIME               NOT NULL DEFAULT '0000-00-00 00:00:00',
    `transaction_id` VARCHAR(24)            NOT NULL DEFAULT '',
    `user_key`       VARCHAR(16)            NOT NULL DEFAULT '',
    PRIMARY KEY `id` (`id`),
    UNIQUE `transaction_id` (`transaction_id`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Paysys ipay report';

CREATE TABLE IF NOT EXISTS `paysys_easypay_report`
(
    `id`             SMALLINT UNSIGNED      NOT NULL AUTO_INCREMENT,
    `uid`            INT(11) UNSIGNED       NOT NULL DEFAULT '0',
    `sum`            DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `prov_bill`      int(11) UNSIGNED       NOT NULL DEFAULT '0',
    `mfo`            int(8) UNSIGNED        NOT NULL DEFAULT '0',
    `bank_name`      VARCHAR(30)            NOT NULL DEFAULT '',
    `client_cmsn`    DOUBLE(5, 2) UNSIGNED  NOT NULL DEFAULT '0.00',
    `commission`     DOUBLE(5, 2) UNSIGNED  NOT NULL DEFAULT '0.00',
    `currency`       VARCHAR(5)             NOT NULL DEFAULT '',
    `date`           DATETIME               NOT NULL DEFAULT '0000-00-00 00:00:00',
    `description`    VARCHAR(200)           NOT NULL DEFAULT '',
    `prov_name`      VARCHAR(30)            NOT NULL DEFAULT '',
    `okpo`           int(8) UNSIGNED        NOT NULL DEFAULT '0',
    `company_name`   VARCHAR(30)            NOT NULL DEFAULT '',
    `terminal_id`    int(8) UNSIGNED        NOT NULL DEFAULT '0',
    `transaction_id` VARCHAR(24)            NOT NULL DEFAULT '',
    PRIMARY KEY `id` (`id`),
    UNIQUE `transaction_id` (`transaction_id`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Paysys easypay report';

CREATE TABLE IF NOT EXISTS `paysys_groups_settings`
(
    `id`        INT(10) UNSIGNED     NOT NULL AUTO_INCREMENT,
    `gid`       SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
    `paysys_id` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
    `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    PRIMARY KEY `id` (`id`),
    KEY `paysys_id` (`paysys_id`)
)
    CHARSET = 'utf8'
    COMMENT = 'Settings for each group';

CREATE TABLE IF NOT EXISTS `paysys_connect`
(
    `id`             TINYINT(4) UNSIGNED  NOT NULL AUTO_INCREMENT,
    `paysys_id`      TINYINT UNSIGNED     NOT NULL DEFAULT 0,
    `subsystem_id`   TINYINT UNSIGNED     NOT NULL DEFAULT 0,
    `name`           VARCHAR(40)          NOT NULL DEFAULT '',
    `module`         VARCHAR(40)          NOT NULL DEFAULT '',
    `status`         TINYINT UNSIGNED     NOT NULL DEFAULT 0,
    `paysys_ip`      TEXT                 NOT NULL,
    `payment_method` INT(11) UNSIGNED     NOT NULL DEFAULT '0',
    `priority`       TINYINT(1) UNSIGNED  NOT NULL DEFAULT 0,
    PRIMARY KEY `id` (`id`)
)
    CHARSET = 'utf8'
    COMMENT = 'Paysys connected systems';

CREATE TABLE IF NOT EXISTS `paysys_ibox_report`
(
    `id`             SMALLINT UNSIGNED      NOT NULL AUTO_INCREMENT,
    `sum`            DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `date`           DATETIME               NOT NULL DEFAULT '0000-00-00 00:00:00',
    `transaction_id` VARCHAR(24)            NOT NULL DEFAULT '',
    `user_key`       VARCHAR(16)            NOT NULL DEFAULT '',
    PRIMARY KEY `id` (`id`),
    UNIQUE `transaction_id` (`transaction_id`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Paysys ibox report';

CREATE TABLE IF NOT EXISTS `paysys_merchant_settings`
(
    `id`            TINYINT(4) UNSIGNED  NOT NULL AUTO_INCREMENT,
    `merchant_name` VARCHAR(40)          NOT NULL DEFAULT '',
    `system_id`     TINYINT UNSIGNED     NOT NULL DEFAULT 0,
    `domain_id`     SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    PRIMARY KEY `id` (`id`),
    FOREIGN KEY (`system_id`) REFERENCES `paysys_connect` (`id`) ON DELETE CASCADE
)
    CHARSET = 'utf8'
    COMMENT = 'Paysys merchant settings';

CREATE TABLE IF NOT EXISTS `paysys_merchant_params`
(
    `id`          INT UNSIGNED         NOT NULL AUTO_INCREMENT,
    `param`       VARCHAR(50)          NOT NULL DEFAULT '',
    `value`       VARCHAR(400)         NOT NULL DEFAULT '',
    `merchant_id` TINYINT UNSIGNED     NOT NULL DEFAULT 0,
    PRIMARY KEY `id` (`id`),
    FOREIGN KEY (`merchant_id`) REFERENCES `paysys_merchant_settings` (`id`) ON DELETE CASCADE
)
    CHARSET = 'utf8'
    COMMENT = 'Paysys merchant params';

CREATE TABLE IF NOT EXISTS `paysys_merchant_to_groups_settings`
(
    `id`        INT(10) UNSIGNED     NOT NULL AUTO_INCREMENT,
    `gid`       SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
    `paysys_id` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
    `merch_id`  TINYINT UNSIGNED     NOT NULL DEFAULT 0,
    `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    PRIMARY KEY `id` (`id`),
    FOREIGN KEY (`merch_id`) REFERENCES `paysys_merchant_settings` (`id`) ON DELETE CASCADE
)
    CHARSET = 'utf8'
    COMMENT = 'Settings for each group';

CREATE TABLE IF NOT EXISTS `paysys_global_money_report`
(
    `id`             SMALLINT UNSIGNED      NOT NULL AUTO_INCREMENT,
    `uid`            INT(11) UNSIGNED       NOT NULL DEFAULT '0',
    `sum`            DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `date`           DATETIME               NOT NULL DEFAULT '0000-00-00 00:00:00',
    `transaction_id` VARCHAR(24)            NOT NULL DEFAULT '',
    `description`    VARCHAR(200)           NOT NULL DEFAULT '',
    PRIMARY KEY `id` (`id`),
    UNIQUE KEY `transaction_id` (`transaction_id`)
)
    CHARSET = 'utf8'
    COMMENT = 'Paysys global_money report';

CREATE TABLE IF NOT EXISTS `paysys_city24_report`
(
    `id`             SMALLINT UNSIGNED      NOT NULL AUTO_INCREMENT,
    `sum`            DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `date`           DATETIME               NOT NULL DEFAULT '0000-00-00 00:00:00',
    `transaction_id` VARCHAR(24)            NOT NULL DEFAULT '',
    `user_key`       VARCHAR(16)            NOT NULL DEFAULT '',
    PRIMARY KEY `id` (`id`),
    UNIQUE `transaction_id` (`transaction_id`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Paysys city24 report';

CREATE TABLE IF NOT EXISTS `paysys_requests`
(
    `id`             INT(11) UNSIGNED       NOT NULL AUTO_INCREMENT,
    `system_id`      TINYINT(4) UNSIGNED    NOT NULL DEFAULT '0',
    `datetime`       DATETIME               NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `uid`            INT(11) UNSIGNED       NOT NULL DEFAULT '0',
    `request`        TEXT                   NOT NULL,
    `response`       TEXT                   NOT NULL,
    `transaction_id` INT(11) UNSIGNED,
    `http_method`    VARCHAR(10)            NOT NULL DEFAULT '',
    `paysys_ip`      INT(11) UNSIGNED       NOT NULL DEFAULT '0',
    `error`          VARCHAR(64)            NOT NULL DEFAULT '',
    `status`         SMALLINT(2) UNSIGNED   NOT NULL DEFAULT '0',
    `request_type`   TINYINT(2) UNSIGNED    NOT NULL DEFAULT '0',
    `sum`            DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    PRIMARY KEY (`id`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Paysys access log';
