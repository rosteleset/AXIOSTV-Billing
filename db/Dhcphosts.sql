SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `dhcphosts_hosts`
(
    `id`           INT(11) UNSIGNED     NOT NULL AUTO_INCREMENT,
    `uid`          INT(11) UNSIGNED     NOT NULL DEFAULT '0',
    `ip`           INT(10) UNSIGNED     NOT NULL DEFAULT '0',
    `hostname`     VARCHAR(40)          NOT NULL DEFAULT '',
    `network`      SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
    `mac`          VARCHAR(17)          NOT NULL DEFAULT '00:00:00:00:00:00',
    `disable`      TINYINT(1) UNSIGNED  NOT NULL DEFAULT '0',
    `forced`       INT(1)               NOT NULL DEFAULT '0',
    `blocktime`    INT(3) UNSIGNED      NOT NULL DEFAULT '3',
    `expire`       DATE                 NOT NULL,
    `seen`         INT(1)               NOT NULL DEFAULT '0',
    `comments`     VARCHAR(250)         NOT NULL DEFAULT '',
    `ports`        VARCHAR(100)         NOT NULL DEFAULT '',
    `vid`          SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `server_vid`   SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `nas`          SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `option_82`    TINYINT(1) UNSIGNED  NOT NULL DEFAULT '0',
    `boot_file`    VARCHAR(150)         NOT NULL DEFAULT '',
    `next_server`  VARCHAR(40)          NOT NULL DEFAULT '',
    `ipn_activate` TINYINT(1)           NOT NULL DEFAULT '0',
    `changed`      DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `host` (`hostname`),
    KEY `uid` (`uid`),
    KEY `mac` (`mac`)
)
    COMMENT = 'Dhcphosts hosts';


CREATE TABLE IF NOT EXISTS `dhcphosts_routes`
(
    `id`      INT(3) UNSIGNED  NOT NULL AUTO_INCREMENT,
    `network` INT(3) UNSIGNED  NOT NULL DEFAULT '0',
    `src`     INT(10) UNSIGNED NOT NULL DEFAULT '0',
    `mask`    INT(10) UNSIGNED NOT NULL DEFAULT '4294967294',
    `router`  INT(10) UNSIGNED NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`)
)
    COMMENT = 'Dhcphosts routes';

CREATE TABLE IF NOT EXISTS `dhcphosts_networks`
(
    `id`                   SMALLINT(3) UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`                 VARCHAR(40)          NOT NULL DEFAULT '',
    `network`              INT(10) UNSIGNED     NOT NULL DEFAULT '0',
    `mask`                 INT(11) UNSIGNED     NOT NULL DEFAULT '4294967294',
    `block_network`        INT(10) UNSIGNED     NOT NULL DEFAULT '0',
    `block_mask`           INT(10) UNSIGNED     NOT NULL DEFAULT '0',
    `suffix`               VARCHAR(30)          NOT NULL DEFAULT '',
    `dns`                  VARCHAR(32)          NOT NULL DEFAULT '',
    `dns2`                 VARCHAR(32)          NOT NULL DEFAULT '',
    `ntp`                  VARCHAR(100)         NOT NULL DEFAULT '',
    `coordinator`          VARCHAR(50)          NOT NULL DEFAULT '',
    `phone`                VARCHAR(20)          NOT NULL DEFAULT '',
    `routers`              INT(11) UNSIGNED     NOT NULL DEFAULT '0',
    `ip_range_first`       INT(11) UNSIGNED     NOT NULL DEFAULT '0',
    `ip_range_last`        INT(11) UNSIGNED     NOT NULL DEFAULT '0',
    `static`               TINYINT(1) UNSIGNED  NOT NULL DEFAULT '0',
    `disable`              TINYINT(1) UNSIGNED  NOT NULL DEFAULT '0',
    `comments`             VARCHAR(250)         NOT NULL DEFAULT '',
    `deny_unknown_clients` TINYINT(1) UNSIGNED  NOT NULL DEFAULT 0,
    `authoritative`        TINYINT(1) UNSIGNED  NOT NULL DEFAULT 0,
    `net_parent`           SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
    `vlan`                 SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
    `guest_vlan`           SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
    `domain_id`            smallint(6) UNSIGNED NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`)
)
    COMMENT = 'Dhcphost networks';

CREATE TABLE IF NOT EXISTS `dhcphosts_leases`
(
    `start`       DATETIME             NOT NULL,
    `ends`        DATETIME             NOT NULL,
    `state`       TINYINT(2)           NOT NULL DEFAULT '0',
    `next_state`  TINYINT(2)           NOT NULL DEFAULT '0',
    `hardware`    VARCHAR(17)          NOT NULL DEFAULT '',
    `uid`         INT(11) UNSIGNED     NOT NULL DEFAULT '0',
    `circuit_id`  VARCHAR(25)          NOT NULL DEFAULT '',
    `remote_id`   VARCHAR(25)          NOT NULL DEFAULT '',
    `hostname`    VARCHAR(30)          NOT NULL DEFAULT '',
    `nas_id`      SMALLINT(6)          NOT NULL DEFAULT '0',
    `ip`          INT(11) UNSIGNED     NOT NULL DEFAULT '0',
    `port`        VARCHAR(11)          NOT NULL DEFAULT '',
    `vlan`        SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `server_vlan` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `switch_mac`  VARCHAR(17)          NOT NULL DEFAULT '',
    `flag`        TINYINT(2)           NOT NULL DEFAULT '0',
    `dhcp_id`     TINYINT(2)           NOT NULL DEFAULT '0',
    KEY `ip` (`ip`),
    KEY `ends` (`ends`),
    KEY `nas_id` (`nas_id`)
) COMMENT ='Dhcphosts leaseds';

CREATE TABLE IF NOT EXISTS `dhcphosts_log`
(
    `id`           INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `datetime`     DATETIME             NOT NULL,
    `hostname`     VARCHAR(20)          NOT NULL DEFAULT '',
    `message_type` TINYINT(2) UNSIGNED  NOT NULL DEFAULT '0',
    `message`      VARCHAR(90)          NOT NULL DEFAULT '',
    PRIMARY KEY (`id`),
    UNIQUE KEY `id` (`id`),
    INDEX `datetime` (`datetime`),
    INDEX `hostname` (`hostname`)
)
    COMMENT = 'Dhcphosts log';
