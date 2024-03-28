ALTER TABLE `portal_articles` ADD COLUMN `picture` VARCHAR(32) NOT NULL DEFAULT '';

ALTER TABLE portal_articles ADD COLUMN picture varchar(32) NOT NULL DEFAULT '';
ALTER TABLE companies ADD COLUMN `edrpou` varchar(100) DEFAULT '';
ALTER TABLE cablecat_wells ADD COLUMN `picture` VARCHAR(250) NOT NULL DEFAULT '';
