SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE `ping_actions` (
  `loss_rate`smallint(6) UNSIGNED NOT NULL DEFAULT '0',
  `transmitted`smallint(6) UNSIGNED NOT NULL DEFAULT '0',
  `racaived` smallint(6) UNSIGNED NOT NULL DEFAULT '0',
  `datetime` datetime NOT NULL,
  `avg_time` double(10,4) NOT NULL DEFAULT '0.00',
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
)  DEFAULT CHARSET=utf8 COMMENT='Ping actions log';