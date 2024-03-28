CREATE TABLE IF NOT EXISTS `msgs_subjects` (
  `id`            SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`          VARCHAR(20)          NOT NULL DEFAULT '',
  `domain_id`     SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`, `domain_id`)
  )
  DEFAULT CHARSET = utf8
  COMMENT = 'Msgs subjects';