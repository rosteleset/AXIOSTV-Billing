CREATE TABLE IF NOT EXISTS `extreceipts` (
  `payments_id`  INT(11)      UNSIGNED NOT NULL DEFAULT '0',
  `command_id`   VARCHAR(60)           NOT NULL DEFAULT '',
  `receipt_date` VARCHAR(30)           NOT NULL DEFAULT '',
  `fdn`          INT(11)      UNSIGNED NOT NULL DEFAULT '0',
  `fda`          INT(11)      UNSIGNED NOT NULL DEFAULT '0',
  `cancel_id`    VARCHAR(60)           NOT NULL DEFAULT '',
  `status`       TINYINT(1)   UNSIGNED NOT NULL DEFAULT '0',
  `kkt_id`       INT(11)      UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`payments_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'External receipts';

CREATE TABLE IF NOT EXISTS `extreceipts_kkt` (
  `kkt_id`       INT(11)      UNSIGNED NOT NULL AUTO_INCREMENT,
  `api_id`       INT(11)      UNSIGNED NOT NULL DEFAULT '0',
  `shift_uuid`   VARCHAR(36)           NOT NULL DEFAULT '',
  `check_header` VARCHAR(60)           NOT NULL DEFAULT '',
  `check_desc`   VARCHAR(60)           NOT NULL DEFAULT '',
  `check_footer` VARCHAR(60)           NOT NULL DEFAULT '',
  `kkt_group`    VARCHAR(30)           NOT NULL DEFAULT '',
  `kkt_key`      VARCHAR(30)           NOT NULL DEFAULT '',
  `methods`      VARCHAR(30)           NOT NULL DEFAULT '',
  `groups`       VARCHAR(30)           NOT NULL DEFAULT '',
  `admins`       VARCHAR(30)           NOT NULL DEFAULT '',
  `aid`          VARCHAR(60)           NOT NULL DEFAULT '',
  PRIMARY KEY (`kkt_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'kkt';

CREATE TABLE IF NOT EXISTS `extreceipts_api` (
  `api_id`       INT(11)     UNSIGNED NOT NULL AUTO_INCREMENT,
  `conf_name`    VARCHAR(50)          NOT NULL DEFAULT '',
  `api_name`     VARCHAR(20)          NOT NULL DEFAULT '',
  `login`        VARCHAR(60)          NOT NULL DEFAULT '',
  `password`     BLOB                 NOT NULL,
  `url`          VARCHAR(200)         NOT NULL DEFAULT '',
  `goods_name`   VARCHAR(200)         NOT NULL DEFAULT '',
  `author`       VARCHAR(30)          NOT NULL DEFAULT '',
  `aid`          SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `callback`     VARCHAR(200)         NOT NULL DEFAULT '',
  `email`        VARCHAR(30)          NOT NULL DEFAULT '',
  `inn`          VARCHAR(30)          NOT NULL DEFAULT '',
  `address`      VARCHAR(200)         NOT NULL DEFAULT '',
  PRIMARY KEY (`api_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Extreceipts apis';
