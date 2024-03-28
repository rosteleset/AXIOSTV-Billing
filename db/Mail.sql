SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `mail_access` (
  `pattern` VARCHAR(30) NOT NULL DEFAULT '',
  `action` VARCHAR(255) NOT NULL DEFAULT '',
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `comments` VARCHAR(255) NOT NULL DEFAULT '',
  `change_date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `status` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`pattern`),
  UNIQUE KEY `id` (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Mail access';

CREATE TABLE IF NOT EXISTS `mail_aliases` (
  `address` VARCHAR(255) NOT NULL DEFAULT '',
  `goto` TEXT NOT NULL,
  `domain` VARCHAR(255) NOT NULL DEFAULT '',
  `create_date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `change_date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `status` TINYINT(2) UNSIGNED NOT NULL DEFAULT '1',
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `comments` VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`address`),
  UNIQUE KEY `id` (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Mail aliases';

CREATE TABLE IF NOT EXISTS `mail_boxes` (
  `username` VARCHAR(255) NOT NULL DEFAULT '',
  `password` BLOB NOT NULL,
  `descr` VARCHAR(255) NOT NULL DEFAULT '',
  `maildir` VARCHAR(255) NOT NULL DEFAULT '',
  `create_date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `change_date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `mails_limit` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `status` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `bill_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `antivirus` TINYINT(1) UNSIGNED NOT NULL DEFAULT '1',
  `antispam` TINYINT(1) UNSIGNED NOT NULL DEFAULT '1',
  `expire` DATE NOT NULL DEFAULT '0000-00-00',
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `box_size` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`username`, `domain_id`),
  UNIQUE KEY `id` (`id`),
  KEY `username_antivirus` (`username`, `antivirus`),
  KEY `username_antispam` (`username`, `antispam`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Mail user boxes';

CREATE TABLE IF NOT EXISTS `mail_domains` (
  `domain` VARCHAR(255) NOT NULL DEFAULT '',
  `create_date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `change_date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `status` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `backup_mx` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `transport` VARCHAR(128) NOT NULL DEFAULT '',
  `comments` VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`domain`),
  UNIQUE KEY `id` (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Mail Spamassassin Preferences';

CREATE TABLE IF NOT EXISTS `mail_spamassassin` (
  `prefid` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(128) NOT NULL DEFAULT '',
  `preference` VARCHAR(64) NOT NULL DEFAULT '',
  `value` VARCHAR(128) DEFAULT NULL,
  `comments` VARCHAR(128) NOT NULL DEFAULT '',
  `create_date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `change_date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY `prefid` (`prefid`),
  KEY `preference` (`preference`),
  KEY `username` (`username`),
  KEY `username_preference_value` (`username`, `preference`, `value`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Mail Spamassassin Preferences';

INSERT INTO `mail_spamassassin` (`username`, `preference`, `value`, `create_date`)
VALUES ('$GLOBAL', 'skip_rbl_checks', '1', now()),
       ('$GLOBAL', 'rbl_timeout', '30', now()),
       ('$GLOBAL', 'dns_available', 'no', now()),
       ('$GLOBAL', 'bayes_auto_learn_threshold_nonspam', '0.1', now()),
       ('$GLOBAL', 'bayes_auto_learn_threshold_spam', '12', now()),
       ('$GLOBAL', 'use_auto_whitelist', '1', now()),
       ('$GLOBAL', 'auto_whitelist_factor', '0.5', now()),
       ('$GLOBAL', 'required_score', '5.0', now()),
       ('$GLOBAL', 'rewrite_header Subject', '*** SPAM: _HITS_ ***', now()),
       ('$GLOBAL', 'report_safe', '1', now()),
       ('$GLOBAL', 'score USER_IN_WHITELIST', '-50', now()),
       ('$GLOBAL', 'score USER_IN_BLACKLIST', '50', now()),
       ('$GLOBAL', 'bayes_auto_learn', '1', now()),
       ('$GLOBAL', 'ok_locales', 'all', now()),
       ('$GLOBAL', 'use_bayes', '1', now()),
       ('$GLOBAL', 'use_razor2', '1', now()),
       ('$GLOBAL', 'use_dcc', '1', now()),
       ('$GLOBAL', 'use_pyzor', '1', now());

CREATE TABLE IF NOT EXISTS `mail_awl` (
  `username` VARCHAR(100) NOT NULL DEFAULT '',
  `email` VARCHAR(200) NOT NULL DEFAULT '',
  `ip` VARCHAR(10) NOT NULL DEFAULT '',
  `count` INT(11) DEFAULT '0',
  `totscore` FLOAT DEFAULT '0',
  PRIMARY KEY (`username`, `email`, `ip`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Mail Auto whitelist';
