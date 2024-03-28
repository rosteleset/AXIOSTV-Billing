SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `netblock_main` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `blocktype` varchar(20) NOT NULL DEFAULT '',
  `hash` char(32) NOT NULL DEFAULT '',
  `inctime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `dbtime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `name` varchar(30) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) COMMENT='Netblock blocklist main table';

CREATE TABLE IF NOT EXISTS `netblock_domain` (
  `id` int(10) unsigned NOT NULL DEFAULT 0,
  `name` varchar(255) NOT NULL DEFAULT '',
  `skip` tinyint(1) NOT NULL DEFAULT '0',
  KEY `id` (`id`),
  FOREIGN KEY (`id`) REFERENCES `netblock_main` (`id`) ON DELETE CASCADE
) COMMENT='Netblock domain table';

CREATE TABLE IF NOT EXISTS `netblock_domain_mask` (
  `id` int(10) unsigned NOT NULL DEFAULT 0,
  `mask` varchar(255) NOT NULL DEFAULT '',
  `skip` tinyint(1) NOT NULL DEFAULT '0',
  KEY `id` (`id`),
  FOREIGN KEY (`id`) REFERENCES `netblock_main` (`id`) ON DELETE CASCADE
) COMMENT='Netblock domain mask table';

CREATE TABLE IF NOT EXISTS `netblock_ip` (
  `id` int(10) unsigned NOT NULL,
  `ip` int(11) unsigned NOT NULL DEFAULT '0',
  `skip` tinyint(1) NOT NULL DEFAULT '0',
  KEY `id` (`id`),
  FOREIGN KEY (`id`) REFERENCES `netblock_main` (`id`) ON DELETE CASCADE
) COMMENT='Netblock ip table';

CREATE TABLE IF NOT EXISTS `netblock_url` (
  `id` int(10) unsigned NOT NULL,
  `url` varchar(255) NOT NULL,
  `skip` tinyint(1) NOT NULL DEFAULT '0',
  KEY `id` (`id`),
  FOREIGN KEY (`id`) REFERENCES `netblock_main` (`id`) ON DELETE CASCADE
) COMMENT='Netblock url table';

CREATE TABLE IF NOT EXISTS `netblock_ssl` (
  `id` int(10) unsigned NOT NULL DEFAULT 0,
  `ssl_name` varchar(255) NOT NULL DEFAULT '',
  `skip` tinyint(1) NOT NULL DEFAULT '0',
  KEY `id` (`id`),
  FOREIGN KEY (`id`) REFERENCES `netblock_main` (`id`) ON DELETE CASCADE
) COMMENT='Netblock ssl table';

CREATE TABLE IF NOT EXISTS `netblock_ports` (
  `id` int(10) unsigned NOT NULL DEFAULT 0,
  `ports` varchar(255) NOT NULL DEFAULT '',
  `skip` tinyint(1) NOT NULL DEFAULT '0',
  KEY `id` (`id`),
  FOREIGN KEY (`id`) REFERENCES `netblock_main` (`id`) ON DELETE CASCADE
) COMMENT='Netblock ports table';