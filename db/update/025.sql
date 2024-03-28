ALTER TABLE `events` MODIFY COLUMN `comments` TEXT;


CREATE TABLE IF NOT EXISTS `sysinfo_remote_servers` (
  `id` SMALLINT(6) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `nas_id` SMALLINT(6) NOT NULL DEFAULT 0,
  `name` VARCHAR(64) NOT NULL DEFAULT '',
  `management` SMALLINT(2) NOT NULL DEFAULT 0,
  `ip` VARBINARY(11) NOT NULL DEFAULT 0,
  `port` SMALLINT(6) NOT NULL DEFAULT 0,
  `nat` TINYINT(1) NOT NULL DEFAULT 0,
  `private_key` TEXT,
  `comments` TEXT
)
  COMMENT = 'List of remote servers to control';

CREATE TABLE IF NOT EXISTS `sysinfo_server_services` (
  `id` SMALLINT(6) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(64) NOT NULL DEFAULT '',
  `check_command` TEXT,
  `status` TINYINT(1) NOT NULL DEFAULT 0,
  `comments` TEXT
)
  COMMENT = 'List of services to control';

CREATE TABLE IF NOT EXISTS `sysinfo_remote_server_services` (
  `server_id` SMALLINT(6) NOT NULL,
  `service_id` SMALLINT(6) NOT NULL,
  UNIQUE (`server_id`, `service_id`)
)
  COMMENT = 'Bindings beetween server and services';

REPLACE INTO `sysinfo_remote_servers`(`id`, `name`, `management`, `ip`, `port`, `comments`) VALUES (
  1, 'localhost', 1, INET_ATON('127.0.0.1'), 19422, 'localhost'
);

REPLACE INTO `sysinfo_server_services`(`id`, `name`, `check_command`) VALUES
  (1, 'mysql', 'service mysql status'),
  (2, 'apache2', 'service apache2 status')
;

REPLACE INTO `sysinfo_remote_server_services` (`server_id`, `service_id`) VALUES
  (1, 1),
  (1, 2)
;

ALTER TABLE `sysinfo_server_services` ADD COLUMN `last_update` TIMESTAMP;



ALTER TABLE `docs_acts` ADD COLUMN `start_period` DATE NOT NULL DEFAULT '0000-00-00';
ALTER TABLE `docs_acts` ADD COLUMN `end_period` DATE NOT NULL DEFAULT '0000-00-00';

