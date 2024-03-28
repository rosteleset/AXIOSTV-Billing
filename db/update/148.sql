CREATE TABLE IF NOT EXISTS `crm_leads_watchers` (
  `id`          INT(11)       UNSIGNED  NOT NULL  AUTO_INCREMENT,
  `aid`         SMALLINT(6)   UNSIGNED  NOT NULL  DEFAULT 0,
  `lead_id`     INT(10)       UNSIGNED  NOT NULL  DEFAULT 0,
  `add_time`    DATETIME                NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY (`aid`,`lead_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'watchers for leads';

CREATE TABLE IF NOT EXISTS `users_development` (
  `id`      INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `uid`     INT(11) UNSIGNED       NOT NULL DEFAULT 0,
  `sum`     DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `date`    DATE                   NOT NULL DEFAULT '0000-00-00',
  `disable` TINYINT(1) UNSIGNED    NOT NULL DEFAULT '0',
  INDEX `uid` (`uid`)
  )
  DEFAULT CHARSET = utf8
  COMMENT = 'Users development table';