SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE `economizer_main` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `login104` varchar(45) DEFAULT ' ',
  `password104` blob,
  `login_electro` varchar(45) DEFAULT ' ',
  `password_electro` blob,
  `user_id` int(10) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

CREATE TABLE `economizer_metric104` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL DEFAULT '1111-11-11',
  `quantity` int(11) NOT NULL DEFAULT '0' COMMENT 'Taking indicators of counters from 104.ua',
  `number_of_counter` varchar(45) NOT NULL DEFAULT '0',
  `user_id` int(10) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=utf8;

CREATE TABLE `economizer_payment104` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date` date DEFAULT NULL,
  `payment` int(11) NOT NULL DEFAULT '0' COMMENT 'Taking indicators of counters from 104.ua',
  `user_id` int(10) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8;

CREATE TABLE `economizer_tariffs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `gas` double(6,2) unsigned NOT NULL DEFAULT '0.00',
  `light` double(6,2) unsigned NOT NULL DEFAULT '0.00',
  `date` date NOT NULL,
  PRIMARY KEY (`id`),
  KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Public utilities tariffs';

CREATE TABLE `economizer_user_info` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `date` date NOT NULL DEFAULT '0001-01-01',
  `light` int(10) unsigned NOT NULL DEFAULT '0',
  `gas` int(10) unsigned NOT NULL DEFAULT '0',
  `water` int(10) unsigned NOT NULL DEFAULT '0',
  `communal` double(6,2) unsigned NOT NULL DEFAULT '0.00',
  `comments` text NOT NULL,
  PRIMARY KEY (`uid`,`date`),
  KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COMMENT='Users data';

CREATE TABLE `economizer_electro_counter` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL DEFAULT '1111-11-11' COMMENT 'date of checking',
  `counter` int(11) NOT NULL DEFAULT '0' COMMENT 'indicator of counter',
  `counter_number` int(11) NOT NULL DEFAULT '0',
  `user_id` int(10) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `economizer_electro_money` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date` varchar(45) NOT NULL DEFAULT '11.1111' COMMENT 'date',
  `saldo` double NOT NULL DEFAULT '0' COMMENT 'saldo at the beginning of the mounth',
  `accrued` double NOT NULL DEFAULT '0' COMMENT 'accrued',
  `paid` double NOT NULL DEFAULT '0' COMMENT 'paid',
  `remainder` double NOT NULL DEFAULT '0' COMMENT 'remainder',
  `user_id` int(10) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

