CREATE TABLE IF NOT EXISTS `triplay_tps` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `name` CHAR(40) NOT NULL DEFAULT '',
  `internet_tp` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `iptv_tp` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `voip_tp` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `comment` TEXT NULL,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'For triplay tariff plans';

CREATE TABLE IF NOT EXISTS `triplay_users` (
  `uid` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `tp_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  UNIQUE (`uid`)
)
  DEFAULT CHARSET=utf8  COMMENT = 'Table for users in module Triplay';
