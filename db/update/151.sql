CREATE TABLE IF NOT EXISTS `paysys_requests` (
  `id`             INT(11) UNSIGNED     NOT NULL AUTO_INCREMENT,
  `system_id`      TINYINT(4) UNSIGNED  NOT NULL DEFAULT '0',
  `datetime`       DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `uid`            INT(11) UNSIGNED     NOT NULL DEFAULT '0',
  `request`        TEXT                 NOT NULL,
  `response`       TEXT                 NOT NULL,
  `transaction_id` INT(11) UNSIGNED,
  `http_method`    VARCHAR(10)          NOT NULL DEFAULT '',
  `paysys_ip`      INT(11) UNSIGNED     NOT NULL DEFAULT '0',
  `error`          VARCHAR(64)          NOT NULL DEFAULT '',
  `status`         SMALLINT(2) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Paysys access log';

ALTER TABLE `streets` ADD KEY `district_id` (`district_id`);