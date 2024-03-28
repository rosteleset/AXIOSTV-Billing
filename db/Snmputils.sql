SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `snmputils_binding` (
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `binding` VARCHAR(30) NOT NULL DEFAULT '',
  `comments` VARCHAR(100) NOT NULL DEFAULT '',
  `params` VARCHAR(20) NOT NULL DEFAULT '',
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  UNIQUE KEY `binding` (`binding`),
  UNIQUE KEY `id` (`id`),
  KEY `uid` (`uid`)
)
  COMMENT = 'Snmputils binding';
