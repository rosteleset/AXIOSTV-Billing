CREATE TABLE IF NOT EXISTS `storage_delivery_types`
(
  `id`        SMALLINT(6) UNSIGNED AUTO_INCREMENT,
  `name`      VARCHAR(30)          NOT NULL DEFAULT '',
  `comments`  VARCHAR(60)          NOT NULL DEFAULT '',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY `id` (`id`)
  )
  DEFAULT CHARSET = utf8 COMMENT = 'List of delivery types';

CREATE TABLE IF NOT EXISTS `storage_deliveries`
(
  `id`              INT(10) UNSIGNED AUTO_INCREMENT,
  `type_id`         SMALLINT(6) NOT NULL DEFAULT 0,
  `installation_id` SMALLINT(6) NOT NULL DEFAULT 0,
  `tracking_number` VARCHAR(100) NOT NULL DEFAULT '',
  `comments`        VARCHAR(255) NOT NULL DEFAULT '',
  `date`            DATETIME NOT NULL,
  PRIMARY KEY `id` (`id`),
  UNIQUE KEY `installation_id` (`installation_id`)
  )
  DEFAULT CHARSET = utf8 COMMENT = 'List of storage deliveries';

CREATE TABLE IF NOT EXISTS `employees_cashboxes_admins`
(
  `cashbox_id`  SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `aid`         SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `add_date`    DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY cashbox_id (aid,cashbox_id)
)
DEFAULT CHARSET=utf8
COMMENT='List of admins for cashboxes'