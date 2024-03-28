ALTER TABLE `discounts_discounts` ADD COLUMN `logo` BLOB NOT NULL DEFAULT '';
ALTER TABLE `discounts_discounts` ADD COLUMN `promocode` varchar(50) NOT NULL DEFAULT '';
ALTER TABLE `discounts_discounts` ADD COLUMN `url` varchar(50) NOT NULL DEFAULT '';
ALTER TABLE `discounts_discounts` ADD COLUMN `disc_stat` SMALLINT NOT NULL DEFAULT 0;
ALTER TABLE `discounts_discounts` RENAME COLUMN `comments` TO `description`;
DROP TABLE `discounts_user_discounts`;

CREATE TABLE `discounts_status` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `stat_title` varchar(30) NULL DEFAULT '',
  `color` varchar(7) NOT NULL DEFAULT '',
  `stat_desc` varchar(250) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Discounts status list'

INSERT INTO `discounts_status` (`stat_title`, `color`, `stat_desc`) VALUES
('Активна', '00ff0', 'Партнерская программа активна'),
('Приостановлена', 'ffff0', 'Партнерская программа временно приостановлена'),
('Остановлена', 'ff000', 'Партнерская программа полностью остановлена');



