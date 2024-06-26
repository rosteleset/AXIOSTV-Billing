CREATE TABLE IF NOT EXISTS `crm_open_lines` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(60) NOT NULL DEFAULT '',
  `source` VARCHAR(60) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm open lines';

CREATE TABLE IF NOT EXISTS `crm_open_line_admins` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `open_line_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm open line admins';