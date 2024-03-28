CREATE TABLE IF NOT EXISTS `ureports_user_send_types` (
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `type` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `destination` VARCHAR(60) NOT NULL DEFAULT '',
  KEY (`uid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Ureports user send types';

INSERT INTO `ureports_user_send_types` SELECT `uid`, `type`, `destination` FROM `ureports_main`;

