SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `discounts_discounts` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `name` CHAR(40) NOT NULL,
  `size` SMALLINT NOT NULL DEFAULT '0',
  `description` TEXT,
  `logo` BLOB NOT NULL DEFAULT '';
  `url` varchar(50) NOT NULL DEFAULT '';
  `disc_stat` SMALLINT NOT NULL DEFAULT 0;
  `promocode` varchar(50) NOT NULL DEFAULT '';
  PRIMARY KEY (`id`)
) COMMENT = 'Discounts table';

CREATE TABLE `discounts_status` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `stat_title` varchar(30) NOT NULL DEFAULT '',
  `color` varchar(7) NOT NULL DEFAULT '',
  `stat_desc` varchar(250) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Discounts status list'

INSERT INTO `discounts_status` (`stat_title`, `color`, `stat_desc`) VALUES
('Активна', '00ff0', 'Партнерская программа активна'),
('Приостановлена', 'ffff0', 'Партнерская программа временно приостановлена'),
('Остановлена', 'ff000', 'Партнерская программа полностью остановлена');