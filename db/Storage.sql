SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `storage_accountability`
(
    `id`                           INT(10) UNSIGNED     NOT NULL AUTO_INCREMENT,
    `aid`                          SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
    `added_by_aid`                 SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `storage_incoming_articles_id` INT(10) UNSIGNED     NOT NULL DEFAULT '0',
    `count`                        INT(10) UNSIGNED     NOT NULL DEFAULT '0',
    `date`                         DATETIME             NOT NULL,
    `comments`                     TEXT,
    KEY `id` (`id`),
    KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`)
)
    DEFAULT CHARSET = utf8;


CREATE TABLE IF NOT EXISTS `storage_articles`
(
    `id`                 INT(11) UNSIGNED     NOT NULL AUTO_INCREMENT,
    `name`               VARCHAR(255)         NOT NULL DEFAULT '',
    `article_type`       SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `measure`            VARCHAR(2)           NOT NULL DEFAULT '0',
    `comments`           TEXT,
    `add_date`           DATE                 NOT NULL,
    `domain_id`          SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `equipment_model_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`),
    KEY `article_type` (`article_type`)
)
    DEFAULT CHARSET = utf8;

CREATE TABLE IF NOT EXISTS `storage_article_types`
(
    `id`        INT(11) UNSIGNED     NOT NULL AUTO_INCREMENT,
    `name`      VARCHAR(255)                  DEFAULT NULL,
    `comments`  TEXT,
    `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`)
)
    DEFAULT CHARSET = utf8;

CREATE TABLE IF NOT EXISTS `storage_discard`
(
    `id`                           INT(10) UNSIGNED       NOT NULL AUTO_INCREMENT,
    `storage_incoming_articles_id` INT(10) UNSIGNED                DEFAULT '0',
    `count`                        INT(10) UNSIGNED       NOT NULL DEFAULT '0',
    `aid`                          INT(10) UNSIGNED                DEFAULT '0',
    `date`                         DATETIME                        DEFAULT CURRENT_TIMESTAMP,
    `comments`                     MEDIUMTEXT,
    `sum`                          DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    PRIMARY KEY (`id`),
    KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`)
)
    DEFAULT CHARSET = utf8 COMMENT = 'Storage discard items';

CREATE TABLE IF NOT EXISTS `storage_incoming`
(
    `id`             SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
    `invoice_number` VARCHAR(60)                   DEFAULT '',
    `date`           DATETIME             NOT NULL,
    `aid`            SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
    `ip`             INT(10) UNSIGNED     NOT NULL DEFAULT '0',
    `comments`       TEXT                 NOT NULL,
    `supplier_id`    SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
    `storage_id`     TINYINT(4) UNSIGNED  NOT NULL DEFAULT '0',
    `domain_id`      SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `payer_id`       INT(10) UNSIGNED     NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`),
    KEY `supplier_id` (`supplier_id`)
)
    DEFAULT CHARSET = utf8;


CREATE TABLE IF NOT EXISTS `storage_incoming_articles`
(
    `id`                    INT(11) UNSIGNED       NOT NULL AUTO_INCREMENT,
    `article_id`            SMALLINT(6) UNSIGNED            DEFAULT NULL,
    `count`                 INT(11) UNSIGNED       NOT NULL DEFAULT '0',
    `sum`                   DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `sn`                    INT(11) UNSIGNED       NOT NULL DEFAULT '0',
    `main_article_id`       SMALLINT(5) UNSIGNED   NOT NULL DEFAULT '0',
    `storage_incoming_id`   SMALLINT(5) UNSIGNED   NOT NULL DEFAULT '0',
    `sell_price`            DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `rent_price`            DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `in_installments_price` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `fees_method`           TINYINT(4) UNSIGNED    NOT NULL DEFAULT '0',
    `abon_distribution`     TINYINT(1)             NOT NULL DEFAULT '0',
    `public_sale`           TINYINT(1)             NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`),
    KEY `storage_incoming_id` (`storage_incoming_id`),
    KEY `article_id` (`article_id`),
    KEY `sn` (`sn`)
)
    DEFAULT CHARSET = utf8;


CREATE TABLE IF NOT EXISTS `storage_installation`
(
    `id`                           INT(10) UNSIGNED       NOT NULL AUTO_INCREMENT,
    `storage_incoming_articles_id` INT(10) UNSIGNED                DEFAULT '0',
    `location_id`                  INT(10) UNSIGNED                DEFAULT '0',
    `count`                        INT(10) UNSIGNED       NOT NULL DEFAULT '0',
    `aid`                          SMALLINT(6) UNSIGNED   NOT NULL DEFAULT '0',
    `installed_aid`                SMALLINT(6) UNSIGNED   NOT NULL DEFAULT '0',
    `uid`                          INT(10) UNSIGNED       NOT NULL DEFAULT '0',
    `nas_id`                       SMALLINT(4) UNSIGNED   NOT NULL DEFAULT '0',
    `comments`                     TEXT,
    `sum`                          DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `mac`                          VARCHAR(40)            NOT NULL DEFAULT '',
    `type`                         SMALLINT(1)            NOT NULL DEFAULT 0,
    `grounds`                      VARCHAR(40)            NOT NULL DEFAULT '',
    `date`                         DATE                   NOT NULL,
    `monthes`                      SMALLINT(3) UNSIGNED   NOT NULL DEFAULT 0,
    `amount_per_month`             DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `actual_sell_price`            DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    PRIMARY KEY (`id`),
    KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`),
    KEY `aid` (`aid`),
    KEY `location_id` (`location_id`),
    KEY `nas_id` (`nas_id`),
    KEY `uid` (`uid`),
    KEY `mac` (`mac`),
    KEY `installed_aid` (`installed_aid`)
)
    DEFAULT CHARSET = utf8 COMMENT = 'Storage user installation';


CREATE TABLE IF NOT EXISTS `storage_log`
(
    `id`                      INT(11)              NOT NULL AUTO_INCREMENT,
    `date`                    DATETIME             NOT NULL,
    `aid`                     SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `storage_main_id`         INT(10) UNSIGNED     NOT NULL DEFAULT '0',
    `storage_id`              TINYINT(3) UNSIGNED  NOT NULL DEFAULT '0',
    `comments`                TEXT,
    `action`                  TINYINT(3) UNSIGNED  NOT NULL DEFAULT '0',
    `ip`                      INT(10) UNSIGNED     NOT NULL DEFAULT '0',
    `count`                   INT(10) UNSIGNED     NOT NULL DEFAULT '0',
    `uid`                     INT(10) UNSIGNED     NOT NULL DEFAULT '0',
    `storage_installation_id` INT(10) UNSIGNED     NOT NULL DEFAULT '0',
    `nas_id`                  INT(10) UNSIGNED     NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`)
)
    DEFAULT CHARSET = utf8 COMMENT = 'Storage operation log';

CREATE TABLE IF NOT EXISTS `storage_reserve`
(
    `id`                           INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
    `storage_incoming_articles_id` INT(10) UNSIGNED DEFAULT '0',
    `count`                        INT(10) UNSIGNED DEFAULT '0',
    `aid`                          INT(10) UNSIGNED DEFAULT '0',
    `date`                         DATETIME         DEFAULT NULL,
    `comments`                     TEXT,
    PRIMARY KEY (`id`),
    KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`)
)
    DEFAULT CHARSET = utf8;

CREATE TABLE IF NOT EXISTS `storage_suppliers`
(
    `id`         SMALLINT(6)          NOT NULL AUTO_INCREMENT,
    `name`       VARCHAR(40)          NOT NULL DEFAULT '',
    `date`       DATE                 NOT NULL,
    `okpo`       VARCHAR(12)          NOT NULL DEFAULT '',
    `inn`        VARCHAR(20)          NOT NULL DEFAULT '',
    `inn_svid`   VARCHAR(40)          NOT NULL DEFAULT '',
    `bank_name`  VARCHAR(200)         NOT NULL DEFAULT '',
    `mfo`        VARCHAR(8)           NOT NULL DEFAULT '',
    `account`    VARCHAR(30)          NOT NULL DEFAULT '',
    `phone`      VARCHAR(16)          NOT NULL DEFAULT '',
    `phone2`     VARCHAR(16)          NOT NULL DEFAULT '',
    `fax`        VARCHAR(16)          NOT NULL DEFAULT '',
    `url`        VARCHAR(100)         NOT NULL DEFAULT '',
    `email`      VARCHAR(250)         NOT NULL DEFAULT '',
    `telegram`   VARCHAR(30)          NOT NULL DEFAULT '',
    `accountant` VARCHAR(150)         NOT NULL DEFAULT '',
    `director`   VARCHAR(150)         NOT NULL DEFAULT '',
    `managment`  VARCHAR(150)         NOT NULL DEFAULT '',
    `domain_id`  SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `comment`    VARCHAR(250)         NOT NULL DEFAULT '',
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`)
)
    DEFAULT CHARSET = utf8;

CREATE TABLE IF NOT EXISTS `storage_sn`
(
    `id`                           INT(11) UNSIGNED        NOT NULL AUTO_INCREMENT,
    `storage_incoming_articles_id` SMALLINT(6)             NOT NULL DEFAULT 0,
    `storage_installation_id`      SMALLINT(6)             NOT NULL DEFAULT 0,
    `serial`                       TEXT CHARACTER SET utf8 NOT NULL,
    `sn_comments`                  TEXT,
    `qrcode_hash`                  CHAR(32)                NOT NULL DEFAULT '',
    PRIMARY KEY (`id`),
    KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`),
    KEY `storage_installation_id` (`storage_installation_id`)
)
    DEFAULT CHARSET = utf8 COMMENT = 'Storage serial numbers';

CREATE TABLE IF NOT EXISTS `storage_storages`
(
    `id`        SMALLINT(6) UNSIGNED AUTO_INCREMENT,
    `name`      VARCHAR(30)          NOT NULL DEFAULT '',
    `comments`  VARCHAR(60)          NOT NULL DEFAULT '',
    `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    PRIMARY KEY `storage_id` (`id`)
)
    DEFAULT CHARSET = utf8 COMMENT = 'List of storages';

INSERT INTO `storage_storages` (`id`, `name`, `comments`)
VALUES (1, '$lang{MAIN}', '');


CREATE TABLE IF NOT EXISTS `storage_inner_use`
(
    `id`                           INT(10) UNSIGNED       NOT NULL AUTO_INCREMENT,
    `storage_incoming_articles_id` INT(10) UNSIGNED                DEFAULT '0',
    `count`                        INT(10) UNSIGNED                DEFAULT '0',
    `aid`                          INT(10) UNSIGNED                DEFAULT '0',
    `date`                         DATETIME                        DEFAULT NULL,
    `sum`                          DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `responsible`                  SMALLINT(6) UNSIGNED   NOT NULL DEFAULT 0,
    `comments`                     TEXT,
    PRIMARY KEY (`id`),
    KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`)
)
    DEFAULT CHARSET = utf8 COMMENT = 'Inner use';

CREATE TABLE IF NOT EXISTS `storage_property`
(
    `id`        INT(10) UNSIGNED     NOT NULL AUTO_INCREMENT,
    `name`      VARCHAR(30)          NOT NULL DEFAULT '',
    `comments`  VARCHAR(60)          NOT NULL DEFAULT '',
    `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`)
)
    DEFAULT CHARSET = utf8 COMMENT = 'Storage property table';

CREATE TABLE IF NOT EXISTS `storage_articles_property`
(
    `id`                           INT UNSIGNED         NOT NULL AUTO_INCREMENT,
    `storage_incoming_articles_id` INT(10) UNSIGNED              DEFAULT '0',
    `property_id`                  INT(10) UNSIGNED     NOT NULL DEFAULT 0,
    `value`                        TEXT,
    `domain_id`                    SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`)
)
    DEFAULT CHARSET = utf8 COMMENT = 'Storage items property table';

SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';
CREATE TABLE IF NOT EXISTS `storage_measure`
(
    `id`       INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`     VARCHAR(30)      NOT NULL DEFAULT '',
    `comments` VARCHAR(60)      NOT NULL DEFAULT '',
    PRIMARY KEY (`id`)
)
    DEFAULT CHARSET = utf8 COMMENT = 'Storage measuring';

REPLACE INTO `storage_measure` (`id`, `name`)
VALUES (0, '$lang{UNIT}');
REPLACE INTO `storage_measure` (`id`, `name`)
VALUES (1, '$lang{METERS}');
REPLACE INTO `storage_measure` (`id`, `name`)
VALUES (2, '$lang{SM}');
REPLACE INTO `storage_measure` (`id`, `name`)
VALUES (3, '$lang{MM}');
REPLACE INTO `storage_measure` (`id`, `name`)
VALUES (4, '$lang{LITERS}');
REPLACE INTO `storage_measure` (`id`, `name`)
VALUES (5, '$lang{BOXES}');

CREATE TABLE IF NOT EXISTS `storage_admins`
(
    `id`        INT(10) UNSIGNED     NOT NULL AUTO_INCREMENT,
    `aid`       SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `percent`   SMALLINT(3) UNSIGNED NOT NULL DEFAULT '0',
    `comments`  TEXT,
    `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`),
    UNIQUE KEY `aid` (`aid`)
)
    DEFAULT CHARSET = utf8 COMMENT = 'Storage admins settings';

CREATE TABLE IF NOT EXISTS `storage_inventory`
(
    `incoming_article_id` INT(10) UNSIGNED              DEFAULT '0',
    `date`                DATETIME                      DEFAULT CURRENT_TIMESTAMP,
    `aid`                 SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `domain_id`           SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    UNIQUE KEY (`incoming_article_id`)
)
    DEFAULT CHARSET = utf8 COMMENT = 'Storage inventory info';

CREATE TABLE IF NOT EXISTS `storage_invoices_payments`
(
    `id`         INT UNSIGNED           NOT NULL AUTO_INCREMENT,
    `invoice_id` SMALLINT(5) UNSIGNED   NOT NULL DEFAULT 0,
    `sum`        DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `actual_sum` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `date`       DATETIME               NOT NULL,
    `aid`        SMALLINT(5) UNSIGNED   NOT NULL DEFAULT '0',
    `comments`   TEXT,
    PRIMARY KEY (`id`),
    KEY `invoice_id` (`invoice_id`)
)
    DEFAULT CHARSET = utf8 COMMENT = 'Storage payments for invoice';

CREATE TABLE IF NOT EXISTS `storage_payers`
(
  `id`        INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`      VARCHAR(30)      NOT NULL DEFAULT '',
  `comments`  VARCHAR(60)      NOT NULL DEFAULT '',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8 COMMENT = 'Storage payers';

CREATE TABLE IF NOT EXISTS `storage_delivery_types`
(
  `id`        SMALLINT(6) UNSIGNED AUTO_INCREMENT,
  `name`      VARCHAR(30)          NOT NULL DEFAULT '',
  `comments`  VARCHAR(60)          NOT NULL DEFAULT '',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY `id` (`id`)
)
  DEFAULT CHARSET = utf8 COMMENT = 'List of delivery types';

CREATE TABLE IF NOT EXISTS `storage_deliveries`
(
  `id`              INT(10) UNSIGNED AUTO_INCREMENT,
  `type_id`         SMALLINT(6) NOT NULL DEFAULT 0,
  `installation_id` SMALLINT(6) NOT NULL DEFAULT 0,
  `tracking_number` VARCHAR(100) NOT NULL DEFAULT '',
  `comments`        VARCHAR(255) NOT NULL DEFAULT '',
  `date`            DATETIME NOT NULL,
  PRIMARY KEY `id` (`id`),
  UNIQUE KEY `installation_id` (`installation_id`)
)
  DEFAULT CHARSET = utf8 COMMENT = 'List of storage deliveries';