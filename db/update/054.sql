ALTER TABLE `nas` ADD COLUMN `floor` VARCHAR(10) DEFAULT '' NOT NULL;
ALTER TABLE `nas` ADD COLUMN `entrance` VARCHAR(10) DEFAULT '' NOT NULL;

CREATE TABLE cablecat_coil (
  id int(11) unsigned NOT NULL AUTO_INCREMENT,
  name varchar(32) NOT NULL DEFAULT '',
  point_id int(11) unsigned NOT NULL DEFAULT 0,
  cable_id int(11) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Cablecat coil';

ALTER TABLE `notepad` MODIFY `text` TEXT;