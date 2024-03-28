ALTER TABLE `equipment_models` ADD COLUMN `snmp_port_shift` tinyint(2) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `equipment_models` ADD COLUMN `test_firmvare` VARCHAR(20) NOT NULL DEFAULT '0';

DROP TABLE IF EXISTS `employees_profile_reply`;
CREATE TABLE IF NOT EXISTS `employees_profile_reply` (
  `question_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `profile_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `reply` text NOT NULL,
  KEY `question_id` (`question_id`),
  UNIQUE KEY(`question_id`, `profile_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Employees profile reply';

INSERT INTO `cablecat_links` (
  `commutation_id`, `geometry`, `attenuation`, `comments`, `direction`,
  `element_1_type`, `element_1_id`, `fiber_num_1`, `element_1_side`,
  `element_2_type`, `element_2_id`, `fiber_num_2`, `element_2_side`
)
  SELECT `commutation_id`, `geometry`, `attenuation`, `comments`, `direction`,
    'CABLE', cable_id_1, fiber_num_1, cable_side_1,
    'CABLE', cable_id_2, fiber_num_1, cable_side_2
  FROM cablecat_commutation_links;
DROP TABLE IF EXISTS `cablecat_commutation_links`;

ALTER TABLE `users_pi` ADD COLUMN `fio2` VARCHAR(40) NOT NULL DEFAULT '';
ALTER TABLE `users_pi` ADD COLUMN `fio3` VARCHAR(40) NOT NULL DEFAULT '';

ALTER TABLE `info_fields` ADD COLUMN `placeholder` VARCHAR(60) NOT NULL DEFAULT '';