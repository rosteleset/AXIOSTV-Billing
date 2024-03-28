CREATE TABLE IF NOT EXISTS `info_change_comments`
(
    `id`          BIGINT UNSIGNED AUTO_INCREMENT
        PRIMARY KEY,
    `id_comments` BIGINT           NOT NULL DEFAULT 0,
    `date_change` DATE             NOT NULL DEFAULT NOW(),
    `aid`         INT(11) UNSIGNED NOT NULL DEFAULT 0,
    `uid`         INT(11) UNSIGNED NOT NULL DEFAULT 0,
    `text`        VARCHAR(300)     NOT NULL DEFAULT '',
    `old_comment` VARCHAR(300)     NOT NULL DEFAULT ''
)
    ENGINE = InnoDB
    DEFAULT CHARSET = utf8
    COMMENT = 'Info change comment';

CREATE TABLE IF NOT EXISTS `tags_responsible`
(
    `id`      SMALLINT(3) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `aid`     SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,
    `tags_id` SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,

    CONSTRAINT `tags_id_fk` FOREIGN KEY (`tags_id`) REFERENCES `tags` (`id`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Tags responsible';

ALTER TABLE `storage_installation` ADD KEY (`aid`);
ALTER TABLE `storage_installation` ADD KEY (`location_id`);
ALTER TABLE `storage_installation` ADD KEY (`nas_id`);
ALTER TABLE `storage_installation` ADD KEY (`uid`);
ALTER TABLE `storage_installation` ADD KEY (`mac`);
ALTER TABLE `storage_installation` ADD KEY (`installed_aid`);

ALTER TABLE `dhcphosts_hosts` ADD KEY (`mac`);

ALTER TABLE `internet_online` ADD KEY (`switch_mac`);

ALTER TABLE `tags_responsible` ADD KEY (`aid`);

ALTER TABLE `ippools` ADD KEY (`static`);
ALTER TABLE `ippools` ADD KEY (`ipv6_prefix`);

ALTER TABLE `users_contracts` ADD KEY (`uid`);