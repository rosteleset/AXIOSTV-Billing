/* Clear info
DROP TABLE IF EXISTS `cablecat_color_schemes`;
# DROP TABLE IF EXISTS `cablecat_cable_types`;
DROP TABLE IF EXISTS `cablecat_cables`;
DROP TABLE IF EXISTS `cablecat_well_types`;
# DROP TABLE IF EXISTS `cablecat_connecter_types`;
DROP TABLE IF EXISTS `cablecat_wells`;
# DROP TABLE IF EXISTS `cablecat_splitter_types`;
DROP TABLE IF EXISTS `cablecat_splitters`;
DROP TABLE IF EXISTS `cablecat_connecters_links`;
DROP TABLE IF EXISTS `cablecat_links`;
DROP TABLE IF EXISTS `cablecat_commutations`;
DROP TABLE IF EXISTS `cablecat_commutation_cables`;
DROP TABLE IF EXISTS `cablecat_cross_types`;
DROP TABLE IF EXISTS `cablecat_crosses`;
DROP TABLE IF EXISTS `cablecat_commutation_equipment`;
*/

SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `cablecat_color_schemes` (
  `id`     SMALLINT(6) PRIMARY KEY AUTO_INCREMENT,
  `name`   VARCHAR(64) NOT NULL,
  `colors` TEXT
)
  CHARSET = 'utf8'
  COMMENT = 'Cable color schemes names';

CREATE TABLE IF NOT EXISTS `cablecat_cable_types` (
  `id`                      SMALLINT(6) PRIMARY KEY AUTO_INCREMENT,
  `name`                    VARCHAR(64) NOT NULL,
  `color_scheme_id`         SMALLINT(6) NOT NULL DEFAULT 1 REFERENCES `cablecat_color_schemes` (`id`),
  `modules_color_scheme_id` SMALLINT(6) NOT NULL DEFAULT 1 REFERENCES `cablecat_color_schemes` (`id`),
  `fibers_count`            SMALLINT(6) NOT NULL DEFAULT 1,
  `modules_count`           SMALLINT(6) NOT NULL DEFAULT 1,
  `outer_color`             VARCHAR(32) NOT NULL DEFAULT '#000000',
  `fibers_type_name`        VARCHAR(32) NOT NULL DEFAULT '',
  `attenuation`             DOUBLE      NOT NULL DEFAULT 0,
  `comments`                TEXT,
  `can_be_splitted`         TINYINT(1)  NOT NULL DEFAULT 1,
  `line_width`              SMALLINT(3) NOT NULL DEFAULT 1
)
  CHARSET = 'utf8'
  COMMENT = 'Cable types';

CREATE TABLE IF NOT EXISTS `cablecat_connecter_types` (
  `id`         SMALLINT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`       VARCHAR(32) NOT NULL,
  `cartridges` SMALLINT(3) NOT NULL DEFAULT 1
)
  CHARSET = 'utf8'
  COMMENT = 'Types of connecters (muffs)';

CREATE TABLE IF NOT EXISTS `cablecat_well_types` (
  `id`       SMALLINT(6)  UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name`     VARCHAR(32)  NOT NULL DEFAULT '',
  `icon`     VARCHAR(120) NOT NULL DEFAULT 'well_green',
  `comments` TEXT
)
  CHARSET = 'utf8'
  COMMENT = 'Types of wells';

REPLACE INTO `cablecat_well_types` (`id`, `name`) VALUES
  (1, '$lang{WELL}'),
  (2, '$lang{CONNECTER}'),
  (3, '$lang{BOX}'),
  (4, '$lang{RACK}'),
  (5, '$lang{SERVER_ROOM}');

CREATE TABLE IF NOT EXISTS `cablecat_wells` (
  `id`                INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`              VARCHAR(64) NOT NULL,
  `parent_id`         INT(11) UNSIGNED,
  `point_id`          INT(11) UNSIGNED REFERENCES `maps_points` (`id`) ON DELETE SET NULL,
  `type_id`           SMALLINT(6) UNSIGNED DEFAULT 1 REFERENCES `cablecat_well_types` (`id`) ON DELETE RESTRICT,
  `connecter_type_id` SMALLINT(6) UNSIGNED REFERENCES `cablecat_connecter_types` (`id`) ON DELETE RESTRICT,
  `picture`           VARCHAR(250) NOT NULL  DEFAULT '',
  UNIQUE `_cablecat_well_name`(`name`)
  )
  CHARSET = 'utf8'
  COMMENT = 'cardes for custom network equipment';

CREATE TABLE IF NOT EXISTS `cablecat_cables` (
  `id`       INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name`     VARCHAR(128)     NOT NULL,
  `type_id`  SMALLINT(6)      NOT NULL REFERENCES `cablecat_cable_types` (`id`) ON DELETE RESTRICT,
  `well_1`   INT(11) UNSIGNED DEFAULT 0 REFERENCES `cablecat_wells` (`id`) ON DELETE RESTRICT,
  `well_2`   INT(11) UNSIGNED DEFAULT 0 REFERENCES `cablecat_wells` (`id`) ON DELETE RESTRICT,
  `point_id` INT(11) UNSIGNED REFERENCES `maps_points` (`id`) ON DELETE SET NULL,
  `length`   DOUBLE           NOT NULL DEFAULT 0,
  `reserve`  DOUBLE           NOT NULL DEFAULT 0,
  UNIQUE `_cablecat_cable_name`(`name`)
)
  CHARSET = 'utf8'
  COMMENT = 'Installed cables';

REPLACE INTO `cablecat_color_schemes` (`id`, `name`, `colors`)
VALUES (1, 'Старлинк, Инкаб, Интегра-Кабель',
        'fc0204,fcfe04,048204,0402fc,840204,040204,fc9a04,840284,fcfefc,848284,04fefc,fc9acc,fc0204+,fcfe04+,048204+,0402fc+,840204+,040204+,fc9a04+,840284+,fcfefc+,848284+,04fefc+,fc9acc+'),
  (2, 'Оптен-2', 'fc0204,fcfe04'),
  (3, 'Оптен-4', 'fc0204,fcfe04,048204,0402fc'),
  (4, 'Оптен-6', 'fc0204,fcfe04,048204,0402fc,840204,040204'),
  (5, 'Оптен-8', 'fc0204,fc9a04,fcfe04,048204,0402fc,840284,840204,040204'),
  (6, 'Оптен-10', 'fc0204,fc9a04,fcfe04,048204,0402fc,840284,840204,040204,fcfefc,848284'),
  (7, 'Оптен-12', 'fc0204,fc9a04,fcfe04,048204,0402fc,840284,840204,040204,fcfefc,848284,04fefc,fc9acc'),
  (8, 'Оптен-14', 'fc0204,fc9a04,fcfe04,048204,0402fc,840284,840204,040204,fcfefc,848284,04fefc,fc9acc,04fe04,9cce04'),
  (9, 'Оптен-16', 'fc0204,fc9a04,fcfe04,048204,0402fc,840284,840204,040204,fcfefc,848284,04fefc,fc9acc,04fe04,9cce04,fcfe9c,dbefdb'),
  (10, 'ОКС 01-4', '048204,fc0204,0402fc,fcfe04'),
  (11, 'ОКС 01-6', '04fefc,fcfe04,fc9a04,fc9acc,848284,dbefdb'),
  (12, 'ОКС 01-8', '048204,fc0204,0402fc,fcfe04,840204,fc9a04,848284,840284'),
  (13, 'ОКС 01-10', 'dbefdb,048204,fc0204,0402fc,04fefc,fcfe04,fc9a04,fc9acc,848284,840284'),
  (14, 'ОКС 01-12', 'dbefdb,048204,fc0204,0402fc,04fefc,fcfe04,840204,fc9a04,fc9acc,848284,840284,fde910'),
  (15, 'ОКС 01-16', 'dbefdb,048204,fc0204,0402fc,04fefc,fcfe04,fc9acc,840204,fc9a04,848284,840284,040204,9cce04,fde910,fcfe9c,fcfefc'),
  (16, 'СОКК', 'fcfefc,fc9a04,840204,048204,fc0204,0402fc,fcfe04,848284,040204,840284,fc9acc,04fefc,fde910,fcfe9c,9cce04,9c3232'),
  (17, 'Завод «Южкабель»', 'dbefdb,fc0204,0402fc,048204,fcfe04,840284,fc9a04,840204,04fefc,fc9acc,848284,040204'),
  (18, 'Электрокабель', 'dbefdb,048204,fc0204,0402fc,04fefc,fcfe04,840204,fc9a04,fc9acc,840284,848284,040204'),
  (19, ' IEC 60304', 'fcfefc,fc0204,040204,fcfe04,0402fc,048204,fc9a04,848284,840204,04fefc,840284,fc9acc,fcfefc+,fc0204+,040204+,fcfe04+,0402fc+,048204+,fc9a04+,848284+,840204+,04fefc+,840284+,fc9acc+'),
  (20, 'Belden (FinMark)', '0402fc,fc9a04,048204,840204,848284,fcfefc,fc0204,040204,fcfe04,840284,fc9acc,04fefc,0402fc+,fc9a04+,048204+,840204+,848284+,fcfefc+,fc0204+,040204+,fcfe04+,840284+,fc9acc+,04fefc+'),
  (21, 'nkt', 'fc0204,048204,fcfe04,0402fc,dbefdb,848284,840204,840284,04fefc,fcfefc,fc9acc,fc9a04,fc0204+,048204+,fcfe04+,0402fc+,dbefdb+,848284+,840204+,840284+,04fefc+,fcfefc+,fc9acc+,fc9a04+'),
  (22, 'R&M',
   'fc0204,048204,fcfe04,0402fc,fcfefc,848284,840204,840284,04fefc,040204,fc9acc,fc9a04,fc0204+,048204+,fcfe04+,0402fc+,fcfefc+,848284+,840204+,840284+,04fefc+,040204+,fc9acc+,fc9a04+'),
  (23, 'ГОСТ Р 53246-2008',
   '0402fc,fc9a04,048204,840204,848284,fcfefc,fc0204,040204,fcfe04,840284,fc9acc,04fefc,0402fc+,fc9a04+,048204+,840204+,848284+,fcfefc+,fc0204+,040204+,fcfe04+,840284+,fc9acc+,04fefc+');

CREATE TABLE IF NOT EXISTS `cablecat_commutations` (
  `id`           INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `connecter_id` INT(11) UNSIGNED,
  `created`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `height`       DOUBLE(6, 2) NULL,
  `name`         VARCHAR(64)  NOT NULL DEFAULT ''
)
  CHARSET = 'utf8';

CREATE TABLE IF NOT EXISTS `cablecat_splitter_types` (
  `id`         SMALLINT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`       VARCHAR(32) NOT NULL,
  `fibers_in`  SMALLINT(3) UNSIGNED,
  `fibers_out` SMALLINT(3) UNSIGNED
)
  CHARSET = 'utf8'
  COMMENT = 'Types of splitters';

REPLACE INTO `cablecat_splitter_types` (`id`, `name`, `fibers_in`, `fibers_out`) VALUES
  (1, '1x2', 1, 2),
  (2, '1x3', 1, 3),
  (3, '1x4', 1, 4),
  (4, '1x6', 1, 6),
  (5, '1x8', 1, 8),
  (6, '1x12', 1, 12),
  (7, '1x16', 1, 16),
  (8, '1x24', 1, 24),
  (9, '1x32', 1, 32),
  (10, '1x64', 1, 64),
  (11, '50/50', 1, 2),
  (12, '45/55', 1, 2),
  (13, '40/60', 1, 2),
  (14, '35/65', 1, 2),
  (15, '30/70', 1, 2),
  (16, '25/75', 1, 2),
  (17, '20/80', 1, 2),
  (18, '15/85', 1, 2),
  (19, '10/90', 1, 2),
  (20, '5/95', 1, 2);

CREATE TABLE IF NOT EXISTS `cablecat_splitters` (
  `id`                   INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`                 VARCHAR(32)      NOT NULL DEFAULT '',
  `type_id`              SMALLINT(6) UNSIGNED REFERENCES `cablecat_splitter_types` (`id`) ON DELETE RESTRICT,
  `well_id`              INT(11) UNSIGNED     REFERENCES `cablecat_wells` (`id`),
  `point_id`             INT(11) UNSIGNED     REFERENCES `maps_points` (`id`) ON DELETE RESTRICT,
  `commutation_id`       INT(11) UNSIGNED     REFERENCES `cablecat_commutations` (`id`) ON DELETE RESTRICT,
  `commutation_x`        DOUBLE(6, 2) NULL,
  `commutation_y`        DOUBLE(6, 2) NULL,
  `commutation_rotation` SMALLINT         NOT NULL DEFAULT 0,
  `color_scheme_id`      INT(11) UNSIGNED NOT NULL DEFAULT '1',
  `attenuation`          VARCHAR(64)      NOT NULL DEFAULT ''
)
  CHARSET = 'utf8'
  COMMENT = 'Dividers of fiber signals (PON)';

CREATE TABLE IF NOT EXISTS `cablecat_connecters_links` (
   `id`          INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   `connecter_1` INT(11) UNSIGNED,
   `connecter_2` INT(11) UNSIGNED,
   `created`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)
  CHARSET = 'utf8'
  COMMENT = 'Links among connectors';

CREATE TABLE IF NOT EXISTS `cablecat_links` (
  `id`             INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `commutation_id` INT(6) UNSIGNED NOT NULL REFERENCES `cablecat_commutations` (`id`) ON DELETE CASCADE,
  `element_1_id`   INT(6) UNSIGNED NOT NULL,
  `element_1_type` VARCHAR(32)     NOT NULL,
  `element_1_side` TINYINT(1) UNSIGNED,
  `element_2_id`   INT(6) UNSIGNED NOT NULL,
  `element_2_type` VARCHAR(32)     NOT NULL,
  `element_2_side` TINYINT(1) UNSIGNED,
  `fiber_num_1`    INT(6) UNSIGNED NOT NULL,
  `fiber_num_2`    INT(6) UNSIGNED NOT NULL,
  `geometry`       TEXT,
  `attenuation`    DOUBLE          NOT NULL DEFAULT 0,
  `comments`       VARCHAR(40)     NOT NULL DEFAULT '',
  `direction`      TINYINT(1) UNSIGNED,
  INDEX `_links_element_1_key` (`element_1_type`, `element_1_id`),
  INDEX `_links_element_2_key` (`element_2_type`, `element_2_id`),
  INDEX `_links_commutation_key` (`commutation_id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Stores information about fiber links (end_points)';

CREATE TABLE IF NOT EXISTS `cablecat_commutation_cables` (
	`id`             INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `commutation_id` INT(11) UNSIGNED REFERENCES `cablecat_commutations` (`id`) ON DELETE CASCADE,
  `connecter_id`   INT(11) UNSIGNED,
  `cable_id`       INT(11) UNSIGNED REFERENCES `cablecat_cables` (`id`) ON DELETE CASCADE,
  `commutation_x`  DOUBLE(6,2) DEFAULT NULL,
  `commutation_y`  DOUBLE(6,2) DEFAULT NULL,
  `position`       VARCHAR(10) NOT NULL DEFAULT '',
  INDEX `_connecter_ik` (`connecter_id`),
  INDEX `_commutation_ik` (`commutation_id`)
)
  CHARSET = 'utf8';

CREATE TABLE IF NOT EXISTS `cablecat_cross_types` (
  `id`             SMALLINT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`           VARCHAR(64)          NOT NULL UNIQUE,
  `cross_type_id`  TINYINT(1)  UNSIGNED NOT NULL,
  `panel_type_id`  TINYINT(1)  UNSIGNED NOT NULL,
  `rack_height`    TINYINT(1)  UNSIGNED NOT NULL DEFAULT 1,
  `ports_count`    SMALLINT(6) UNSIGNED NOT NULL DEFAULT 8,
  `ports_type_id`  TINYINT(1)  UNSIGNED NOT NULL,
  `polish_type_id` TINYINT(1)  UNSIGNED NOT NULL,
  `fiber_type_id`  TINYINT(1)  UNSIGNED NOT NULL
)
  CHARSET = 'utf8';

CREATE TABLE IF NOT EXISTS `cablecat_crosses` (
  `id`              INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`            VARCHAR(32) NOT NULL DEFAULT '',
  `well_id`         INT(11) UNSIGNED REFERENCES `cablecat_wells` (`id`) ON DELETE RESTRICT,
  `color_scheme_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `type_id`         SMALLINT(6) UNSIGNED DEFAULT 1 REFERENCES `cablecat_cross_types` (`id`) ON DELETE RESTRICT
)
  CHARSET = 'utf8';

CREATE TABLE IF NOT EXISTS `cablecat_commutation_equipment` (
  `id`                   INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `nas_id`               INT(11) UNSIGNED UNIQUE NOT NULL,
  `commutation_id`       INT(11) UNSIGNED REFERENCES `cablecat_commutations` (`id`) ON DELETE CASCADE,
  `commutation_x`        DOUBLE(6, 2) NULL,
  `commutation_y`        DOUBLE(6, 2) NULL,
  `commutation_rotation` SMALLINT NOT NULL DEFAULT 0,
  INDEX `_nas_commutation` (`commutation_id`, `nas_id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Stores equipment existance on commutation';

CREATE TABLE IF NOT EXISTS `cablecat_commutation_onu` (
  `id`                   INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uid`                  INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `service_id`           INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `commutation_id`       INT(11) UNSIGNED REFERENCES `cablecat_commutations` (`id`) ON DELETE CASCADE,
  `commutation_x`        DOUBLE(6,2) DEFAULT NULL,
  `commutation_y`        DOUBLE(6,2) DEFAULT NULL,
  `commutation_rotation` SMALLINT(6) DEFAULT 0,
  INDEX `_commutation_ik` (`commutation_id`),
  INDEX `_uid_ik` (`uid`),
  INDEX `_service_ik` (`service_id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Stores onu existance on commutation';

CREATE TABLE IF NOT EXISTS `cablecat_commutation_crosses` (
  `commutation_id`       INT(11) UNSIGNED REFERENCES `cablecat_commutations` (`id`) ON DELETE CASCADE,
  `cross_id`             INT(11) UNSIGNED REFERENCES `cablecat_crosses` (`id`) ON DELETE CASCADE,
  `port_start`           SMALLINT(6) UNSIGNED NOT NULL,
  `port_finish`          SMALLINT(6) UNSIGNED NOT NULL,
  `commutation_x`        DOUBLE(6, 2)         NULL,
  `commutation_y`        DOUBLE(6, 2)         NULL,
  `commutation_rotation` SMALLINT             NOT NULL DEFAULT 0,
  INDEX `_cross_commutation` (`commutation_id`, `cross_id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Stores information about cross on commutation links and images';

CREATE TABLE IF NOT EXISTS `cablecat_cross_links` (
  `cross_id`   INT(11) UNSIGNED REFERENCES `cablecat_crosses` (`id`) ON DELETE CASCADE,
  `cross_port` INT(6) UNSIGNED      NOT NULL,
  `link_type`  SMALLINT(3) UNSIGNED NOT NULL,
  `link_value` VARCHAR(32)          NOT NULL DEFAULT '',
  UNIQUE `_cross_port` (`cross_id`, `cross_port`)
)
  CHARSET = 'utf8'
  COMMENT = 'Logical values for port connection';

CREATE TABLE IF NOT EXISTS `cablecat_coil` (
  `id`       INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`     VARCHAR(32)      NOT NULL DEFAULT '',
  `point_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `cable_id` INT(11) UNSIGNED NOT NULL DEFAULT '1',
  `length`   INT              NOT NULL DEFAULT 30,
  PRIMARY KEY (`id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Cablecat coils';

CREATE TABLE IF NOT EXISTS `cablecat_schemes` (
  `id`             INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `commutation_id` INT(11) UNSIGNED,
  `commutation_x`  DOUBLE NULL,
  `commutation_y`  DOUBLE NULL,
  `height`         SMALLINT(6) UNSIGNED NOT NULL,
  `width`          SMALLINT(6) UNSIGNED NOT NULL,
  KEY `commutation_id` (`commutation_id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Schemes for big commutation';

CREATE TABLE IF NOT EXISTS `cablecat_scheme_elements` (
  `id`             INT(11) UNSIGNED NOT NULL,
  `commutation_x`  DOUBLE NULL,
  `commutation_y`  DOUBLE NULL,
  `type`           VARCHAR(32) NOT NULL DEFAULT '',
  `commutation_id` INT(11) UNSIGNED,
  KEY `id` (`id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Scheme element for big commutation';

CREATE TABLE IF NOT EXISTS `cablecat_scheme_links` (
  `id`             INT(11) UNSIGNED NOT NULL,
  `geometry`       TEXT,
  `commutation_id` INT(11) UNSIGNED,
  KEY `id` (`id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Scheme links for big commutation';

CREATE TABLE IF NOT EXISTS `cablecat_import_presets` (
  `id`                  INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `preset_name`         VARCHAR(64)      NOT NULL DEFAULT '',
  `default_object_name` VARCHAR(64)      NOT NULL DEFAULT '',
  `object_name`         VARCHAR(64)      NOT NULL DEFAULT '',
  `type_id`             VARCHAR(64)      NOT NULL DEFAULT '',
  `default_type_id`     SMALLINT(6)      NOT NULL,
  `object`              VARCHAR(64)      NOT NULL DEFAULT '',
  `object_add`          TINYINT(1)       NOT NULL DEFAULT 0,
  `coordx`              VARCHAR(64)      NOT NULL DEFAULT '',
  `coordy`              VARCHAR(64)      NOT NULL DEFAULT '',
  `load_url`            VARCHAR(128)     NOT NULL DEFAULT '',
  `json_path`           VARCHAR(64)      NOT NULL DEFAULT '',
  `filters`             VARCHAR(128)     NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Presets for wells import';

CREATE TABLE IF NOT EXISTS `cablecat_storage_installation` (
  `id`              INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `object_id`       INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `type`            SMALLINT(6) UNSIGNED NOT NULL NOT NULL DEFAULT 0,
  `installation_id` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  `date`            DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `aid`             SMALLINT(6)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Storage installation to Cablecat objects';