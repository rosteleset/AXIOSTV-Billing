CREATE TABLE IF NOT EXISTS `paysys_ipay_report` (
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

CREATE TABLE IF NOT EXISTS `paysys_easypay_report` (
  `id`             SMALLINT UNSIGNED      NOT NULL  AUTO_INCREMENT,
  `uid`            INT(11) UNSIGNED       NOT NULL  DEFAULT '0',
  `sum`            DOUBLE(10, 2) UNSIGNED NOT NULL  DEFAULT '0.00',
  `prov_bill`      int(11) UNSIGNED       NOT NULL  DEFAULT '0',
  `mfo`            int(8) UNSIGNED        NOT NULL  DEFAULT '0',
  `bank_name`      VARCHAR(30)            NOT NULL  DEFAULT '',
  `client_cmsn`    DOUBLE(5, 2) UNSIGNED  NOT NULL  DEFAULT '0.00',
  `commission`     DOUBLE(5, 2) UNSIGNED  NOT NULL  DEFAULT '0.00',
  `currency`       VARCHAR(5)             NOT NULL  DEFAULT '',
  `date`           DATETIME               NOT NULL  DEFAULT '0000-00-00 00:00:00',
  `description`    VARCHAR(200)           NOT NULL  DEFAULT '',
  `prov_name`      VARCHAR(30)            NOT NULL  DEFAULT '',
  `okpo`           int(8) UNSIGNED        NOT NULL  DEFAULT '0',
  `company_name`   VARCHAR(30)            NOT NULL  DEFAULT '',
  `terminal_id`    int(8) UNSIGNED        NOT NULL  DEFAULT '0',
  `transaction_id` VARCHAR(24)            NOT NULL  DEFAULT '',
  PRIMARY KEY `id` (`id`),
  UNIQUE `transaction_id` (`transaction_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Paysys easypay report';

CREATE TABLE IF NOT EXISTS `paysys_ibox_report` (
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