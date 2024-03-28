SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `cards_bruteforce` (
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `pin` VARCHAR(20) NOT NULL DEFAULT '',
  `datetime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP
)
  DEFAULT CHARSET=utf8
  COMMENT = 'Cards bruteforce check';

CREATE TABLE IF NOT EXISTS `cards_dillers` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(45) NOT NULL DEFAULT '',
  `address` VARCHAR(100) NOT NULL DEFAULT '',
  `phone` BIGINT(20) UNSIGNED NOT NULL DEFAULT '0',
  `email` VARCHAR(35) NOT NULL DEFAULT '0',
  `comments` TEXT NOT NULL,
  `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `registration` DATE NOT NULL DEFAULT '0000-00-00',
  `percentage` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `uid` (`uid`)
)
  DEFAULT CHARSET=utf8
  COMMENT = 'Cards dillers';


CREATE TABLE IF NOT EXISTS `cards_users` (
  `number` INT(11) UNSIGNED ZEROFILL NOT NULL DEFAULT '00000000000',
  `login` VARCHAR(20) NOT NULL DEFAULT '',
  `status` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `datetime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `aid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `gid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `expire` DATE NOT NULL DEFAULT '0000-00-00',
  `diller_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `diller_date` DATE NOT NULL DEFAULT '0000-00-00',
  `diller_sold_date` DATE NOT NULL DEFAULT '0000-00-00',
  `sum` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `serial` VARCHAR(10) NOT NULL DEFAULT '',
  `pin` BLOB NOT NULL,
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `created` DATETIME NOT NULL,
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `commission` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  UNIQUE KEY `serial` (`number`, `serial`, `domain_id`),
  KEY `diller_id` (`diller_id`),
  KEY `login` (`login`),
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8
  COMMENT = 'Cards list';

CREATE TABLE IF NOT EXISTS `dillers_tps` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL DEFAULT '',
  `payment_type` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `percentage` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `operation_payment` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `activate_price` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `change_price` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `credit` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `min_use` DOUBLE(14, 3) UNSIGNED NOT NULL DEFAULT '0.000',
  `payment_expr` VARCHAR(240) NOT NULL DEFAULT '',
  `nas_tp` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `gid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT NOT NULL,
  `bonus_cards` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
)
  DEFAULT CHARSET=utf8
  COMMENT = 'Resellers Tarif Plans';


CREATE TABLE IF NOT EXISTS `dillers_permits` (
  `diller_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `actions` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `section` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  UNIQUE KEY `diller_id` (`diller_id`, `section`)
)
  DEFAULT CHARSET=utf8
  COMMENT = 'Dillers Permisions';


CREATE TABLE IF NOT EXISTS `cards_gids`
(
    `gid`    SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `serial` VARCHAR(10)          NOT NULL DEFAULT '',
    UNIQUE KEY `serial` (`gid`, `serial`)
)
  DEFAULT CHARSET=utf8
  COMMENT = 'Cards list';