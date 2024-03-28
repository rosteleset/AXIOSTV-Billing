CREATE TABLE IF NOT EXISTS `crm_competitors` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(64) NOT NULL DEFAULT '',
  `connection_type` VARCHAR(32) NOT NULL DEFAULT '',
  `site` VARCHAR(150) NOT NULL DEFAULT '',
  `descr` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Crm Competitors';

CREATE TABLE IF NOT EXISTS `crm_competitors_tps` (
  `id`            INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`          VARCHAR(64) NOT NULL DEFAULT '',
  `speed`         INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `month_fee`     DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `day_fee`       DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `competitor_id` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `competitor_id` (`competitor_id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Crm Competitors tps';

CREATE TABLE IF NOT EXISTS `crm_competitor_geolocation` (
  `competitor_id` SMALLINT(5) UNSIGNED DEFAULT '0' NOT NULL,
  `district_id`   SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL,
  `street_id`     SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL,
  `build_id`      SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL
)
  DEFAULT CHARSET=utf8 COMMENT = 'Geolocation of competitor';

CREATE TABLE IF NOT EXISTS `crm_competitor_tps_geolocation` (
  `tp_id`       SMALLINT(5) UNSIGNED DEFAULT '0' NOT NULL,
  `district_id` SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL,
  `street_id`   SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL,
  `build_id`    SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL
)
  DEFAULT CHARSET=utf8 COMMENT = 'Geolocation of competitor tps';


CREATE TABLE `payments_spool` (
  `date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `sum` double(10,2) NOT NULL DEFAULT '0.00',
  `dsc` varchar(80) DEFAULT NULL,
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `method` tinyint(4) unsigned NOT NULL DEFAULT '0',
  `ext_id` varchar(28) NOT NULL DEFAULT '',
  `bill_id` int(11) unsigned NOT NULL DEFAULT '0',
  `currency` smallint(5) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `date` (`date`),
  KEY `uid` (`uid`),
  KEY `ext_id` (`ext_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COMMENT='Payments log spool';
