ALTER TABLE `equipment_pon_onu` ADD COLUMN `datetime` DATETIME NOT NULL DEFAULT '0000-00-00';

CREATE TABLE `domains_admins` (
  aid smallint unsigned not null default 0,
  domain_id smallint unsigned not null default 0,
  UNIQUE KEY domain_id_aid (`domain_id`,`aid`)
)
COMMENT 'Domain admin list';
