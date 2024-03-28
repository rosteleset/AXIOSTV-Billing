CREATE TABLE IF NOT EXISTS `telegram_tmp` (
  `id`               INT(11) UNSIGNED     NOT NULL  AUTO_INCREMENT,
  `uid`              INT(11) UNSIGNED     NOT NULL  DEFAULT '0',
  `aid`              SMALLINT(4) UNSIGNED NOT NULL  DEFAULT '0',
  `button`           VARCHAR(50)          NOT NULL  DEFAULT '',
  `fn`               VARCHAR(50)          NOT NULL  DEFAULT '',
  `args`             TEXT                 CHARACTER SET utf8mb4,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Telegram temporary values';