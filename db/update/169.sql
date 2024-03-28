INSERT INTO admins_contacts (aid, value, type_id)
SELECT aid, phone, 2 FROM admins WHERE phone <> '';

INSERT INTO admins_contacts (aid, value, type_id)
SELECT aid, email, 9 FROM admins WHERE email <> '';

ALTER TABLE `cams_folder` ADD COLUMN `uid` INT(11) UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `accident_log` ADD COLUMN `sent_open` INT(10) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `accident_log` ADD COLUMN `sent_close` INT(10) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `accident_equipments` ADD COLUMN `sent_open` INT(10) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `accident_equipments` ADD COLUMN `sent_close` INT(10) UNSIGNED NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `users_registration_pin`
(
    `pin_code`    BLOB                 NOT NULL,
    `uid`         INT(11) UNSIGNED     NOT NULL,
    `create_date` DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `verify_date` DATETIME             NOT NULL,
    `destination` VARCHAR(250)         NOT NULL DEFAULT '',
    `attempts`    SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `send_count`  SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
    UNIQUE KEY `uid` (`uid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Users registration pin';


ALTER TABLE `equipment_infos` ADD COLUMN `snmp_timeout` smallint(6) UNSIGNED NOT NULL DEFAULT 0;