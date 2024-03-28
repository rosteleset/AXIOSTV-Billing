CREATE TABLE IF NOT EXISTS `cablecat_import_presets` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `preset_name` varchar(64) NOT NULL DEFAULT '',
  `default_preset_name` varchar(64) NOT NULL DEFAULT '',
  `object_name` varchar(64) NOT NULL DEFAULT '',
  `type_id` varchar(64) NOT NULL DEFAULT '',
  `default_type_id` SMALLINT(6) NOT NULL,
  `object` varchar(64) NOT NULL DEFAULT '',
  `object_add` TINYINT(1) NOT NULL DEFAULT 0,
  `coordx` varchar(64) NOT NULL DEFAULT '',
  `coordy` varchar(64) NOT NULL DEFAULT '',
  `load_url` varchar(128) NOT NULL DEFAULT '',
  `json_path` varchar(64) NOT NULL DEFAULT '',
  `filters` varchar(128) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Presets for wells import';
ALTER TABLE equipment_extra_ports ADD COLUMN port_combo_with SMALLINT NOT NULL DEFAULT 0 AFTER port_type;
ALTER TABLE equipment_extra_ports DROP COLUMN state;
