SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `multidoms_nas_tps` (
  `nas_id` SMALLINT(6) UNSIGNED NOT NULL,
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL,
  `datetime` DATETIME NOT NULL,
  `bonus_cards` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`domain_id`, `tp_id`, `nas_id`)
)
  COMMENT = 'Multidoms Dillers NAS TPS. For postpaid cards fees';

CREATE TABLE IF NOT EXISTS `domains_admins` (
  `aid` smallint(5) unsigned NOT NULL DEFAULT '0',
  `domain_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  UNIQUE KEY `domain_id_aid` (`domain_id`,`aid`)
) 
  COMMENT='Domain admin list';

CREATE TABLE IF NOT EXISTS `domains_modules` (
  `id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `module` varchar(12) NOT NULL DEFAULT '',
  UNIQUE KEY `id_module` (`id`,`module`),
  KEY `id` (`id`)
) COMMENT='Domains module permissions';


DELIMITER //
CREATE TRIGGER `domain_add`
AFTER INSERT ON `domains`
FOR EACH ROW
  BEGIN


    INSERT INTO `tarif_plans` (`id`,
                               `name`,
                               `logins`,
                               `domain_id`,
                               `total_time_limit`,
                               `comments`) VALUES
      (1, '1 Hour', 1, `NEW`.`id`, 3600, ''),
      (12, '5 Hours', 1, `NEW`.`id`, 18000, ''),
      (13, '24 Hours', 1, `NEW`.`id`, 86400, '');

    INSERT INTO `nas_groups` (`name`, `domain_id`, `default`, `comments`)
    VALUES ('Default', `NEW`.`id`, 1, '');


  END;

//
DELIMITER ;
