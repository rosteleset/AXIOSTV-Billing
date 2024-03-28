ALTER TABLE `service_status` ADD COLUMN `get_fees` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;

REPLACE INTO `service_status` (`id`, `name`, `color`, `type`, `get_fees`) VALUES (0, '$lang{ENABLE}', '4CAF50', 0, 0);
REPLACE INTO `service_status` (`id`, `name`, `color`, `type`, `get_fees`) VALUES (1, '$lang{DISABLE}', 'F44336', 0, 0);
REPLACE INTO `service_status` (`id`, `name`, `color`, `type`, `get_fees`) VALUES (2, '$lang{NOT_ACTIVE}', 'FF9800', 0, 0);
REPLACE INTO `service_status` (`id`, `name`, `color`, `type`, `get_fees`) VALUES (3, '$lang{HOLD_UP}', '2196F3', 0, 0);
REPLACE INTO `service_status` (`id`, `name`, `color`, `type`, `get_fees`)
VALUES (4, '$lang{DISABLE} $lang{NON_PAYMENT}', '607D8B', 0, 0);
REPLACE INTO `service_status` (`id`, `name`, `color`, `type`, `get_fees`) VALUES (5, '$lang{ERR_SMALL_DEPOSIT}', '009688', 0, 0);
REPLACE INTO `service_status` (`id`, `name`, `color`, `type`, `get_fees`) VALUES (6, '$lang{VIRUS_ALERT}', '9C27B0', 0, 0);
REPLACE INTO `service_status` (`id`, `name`, `color`, `type`, `get_fees`) VALUES (7, '$lang{REPAIR}', '9E9E9E', 0, 0);

ALTER TABLE `dhcphosts_leases` ADD COLUMN  `server_vlan` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';

ALTER TABLE `crm_leads` ADD COLUMN `current_step` int NOT NULL DEFAULT 0;


