SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `employees_positions`
(
    `id`            SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    `position`      CHAR(40) UNIQUE                  NOT NULL DEFAULT '',
    `subordination` SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    `vacancy`       TINYINT(2) UNSIGNED              NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`)
)
    COMMENT = 'Employees positions';

INSERT INTO `employees_positions`
VALUES (1, "$lang{ADMIN}", 0, 0),
       (2, "$lang{ACCOUNTANT}", 0, 0),
       (3, "$lang{MANAGER}", 0, 0);

CREATE TABLE IF NOT EXISTS `employees_geolocation`
(
    `employee_id` SMALLINT UNSIGNED    NOT NULL DEFAULT 0,
    `district_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
    `street_id`   SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
    `build_id`    SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
    KEY `employee_id` (`employee_id`),
    KEY `district_id` (`district_id`),
    KEY `street_id` (`street_id`),
    KEY `build_id` (`build_id`)
)
    COMMENT = 'Employees geolocation';

CREATE TABLE IF NOT EXISTS `employees_profile`
(
    `id`            SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    `fio`           VARCHAR(188)                     NOT NULL DEFAULT '',
    `date_of_birth` DATE                             NOT NULL DEFAULT '0000-00-00',
    `email`         VARCHAR(188) UNIQUE              NOT NULL DEFAULT '',
    `phone`         VARCHAR(188) UNIQUE              NOT NULL DEFAULT '',
    `position_id`   SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    `rating`        SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
)
    COMMENT = 'Employees profile';

CREATE TABLE IF NOT EXISTS `employees_profile_question`
(
    `id`          SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    `position_id` SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    `question`    TEXT                             NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY `position_id` (`position_id`) REFERENCES `employees_positions` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE
)
    COMMENT = 'Employees profile question';

CREATE TABLE IF NOT EXISTS `employees_profile_reply`
(
    `question_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `profile_id`  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `reply`       TEXT              NOT NULL,
    FOREIGN KEY `question_id` (`question_id`) REFERENCES `employees_profile_question` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE
)
    COMMENT = 'Employees profile reply';

CREATE TABLE IF NOT EXISTS `employees_rfid_log`
(
    `id`       INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `datetime` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `rfid`     VARCHAR(15) NOT NULL DEFAULT '',
    `aid`      SMALLINT(6) NOT NULL DEFAULT 0,
    KEY `aid` (`aid`)
)
    COMMENT = 'All registered RFID entries';

CREATE INDEX `_ik_datetime`
    ON `employees_rfid_log` (`datetime`);
CREATE INDEX `_ik_rfid`
    ON `employees_rfid_log` (`rfid`);


CREATE TABLE IF NOT EXISTS `employees_daily_notes`
(
    `id`       INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `day`      DATE                 NOT NULL DEFAULT '0000-00-00',
    `aid`      SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
    `comments` TEXT                 NOT NULL,
    KEY `aid` (`aid`)
)
    COMMENT = 'Admins daily notes';

CREATE TABLE IF NOT EXISTS `employees_vacations`
(
    `id`         INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `aid`        SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
    `start_date` DATE                 NOT NULL DEFAULT '0000-00-00',
    `end_date`   DATE                 NOT NULL DEFAULT '0000-00-00',
    KEY `aid` (`aid`)
)
    COMMENT = 'Employees vacations';

CREATE TABLE IF NOT EXISTS `employees_duty`
(
    `id`         INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `aid`        SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
    `start_date` DATE                 NOT NULL DEFAULT '0000-00-00',
    `duration`   INT                  NOT NULL DEFAULT 0,
    KEY `aid` (`aid`)
)
    COMMENT = 'Employees duty';

CREATE TABLE IF NOT EXISTS `employees_department`
(
    `id`        SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`      char(60)          NOT NULL DEFAULT '',
    `comments`  TEXT,
    `positions` varchar(25)       NOT NULL DEFAULT '',
    PRIMARY KEY (`id`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Employees departments';

CREATE TABLE IF NOT EXISTS `employees_ext_params`
(
    `id`          SMALLINT UNSIGNED      NOT NULL AUTO_INCREMENT,
    `aid`         SMALLINT(6) UNSIGNED   NOT NULL DEFAULT '0',
    `phone`       VARCHAR(16)            NOT NULL DEFAULT '' UNIQUE,
    `sum`         DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `day_num`     SMALLINT(6) UNSIGNED   NOT NULL DEFAULT '0',
    `status`      SMALLINT(1) UNSIGNED   NOT NULL DEFAULT '0',
    `mob_comment` VARCHAR(255)           NOT NULL DEFAULT '',
    PRIMARY KEY `id` (`id`),
    KEY `aid` (`aid`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Employees extra parameters';

CREATE TABLE IF NOT EXISTS `employees_mobile_reports`
(
    `id`             SMALLINT UNSIGNED      NOT NULL AUTO_INCREMENT,
    `aid`            SMALLINT(6) UNSIGNED   NOT NULL DEFAULT '0',
    `phone`          VARCHAR(16)            NOT NULL DEFAULT '',
    `sum`            DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `date`           datetime               NOT NULL DEFAULT '0000-00-00 00:00:00',
    `transaction_id` VARCHAR(24)            NOT NULL DEFAULT '',
    `status`         SMALLINT(1) UNSIGNED   NOT NULL DEFAULT '0',
    PRIMARY KEY `id` (`id`),
    KEY `aid` (`aid`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Employees mobile reports';

CREATE TABLE IF NOT EXISTS `employees_cashboxes`
(
    `id`       SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    `name`     CHAR(40)                         NOT NULL,
    `aid`      INT(11) UNSIGNED                 NOT NULL DEFAULT 0,
    `comments` TEXT,
    PRIMARY KEY (`id`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Employees cashboxes';

CREATE TABLE IF NOT EXISTS `employees_spending`
(
    `id`               SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    `amount`           DOUBLE(10, 2)                    NOT NULL DEFAULT 0.00,
    `spending_type_id` SMALLINT                         NOT NULL DEFAULT 0,
    `cashbox_id`       SMALLINT                         NOT NULL DEFAULT 0,
    `date`             DATE                             NOT NULL DEFAULT '0000-00-00',
    `aid`              SMALLINT(6) UNSIGNED             NOT NULL DEFAULT 0,
    `admin_spending`   INT(11) UNSIGNED                 NOT NULL DEFAULT 0,
    `comments`         TEXT,
    PRIMARY KEY (`id`),
    KEY `aid` (`aid`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Employees spending';

CREATE TABLE IF NOT EXISTS `employees_spending_types`
(
    `id`       SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    `name`     CHAR(40)                         NOT NULL,
    `comments` TEXT,
    PRIMARY KEY (`id`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Spending types';

CREATE TABLE IF NOT EXISTS `employees_coming`
(
    `id`             SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    `amount`         DOUBLE(10, 2)                    NOT NULL DEFAULT 0.00,
    `coming_type_id` SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    `cashbox_id`     SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    `date`           DATE                             NOT NULL DEFAULT '0000-00-00',
    `aid`            SMALLINT(6) UNSIGNED             NOT NULL DEFAULT 0,
    `uid`            INT(11) UNSIGNED                 NOT NULL DEFAULT 0,
    `comments`       TEXT,
    PRIMARY KEY (`id`),
    KEY `aid` (`aid`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Coming';

CREATE TABLE IF NOT EXISTS `employees_coming_types`
(
    `id`             SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    `name`           CHAR(40)                         NOT NULL,
    `default_coming` TINYINT(3) UNSIGNED              NOT NULL DEFAULT 0,
    `comments`       TEXT,
    PRIMARY KEY (`id`)
) COMMENT = 'Coming types';

CREATE TABLE IF NOT EXISTS `employees_bet`
(
    `aid`          SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
    `type`         SMALLINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `bet`          DOUBLE(10, 2)        NOT NULL DEFAULT 0.00,
    `bet_per_hour` DOUBLE(10, 2)        NOT NULL DEFAULT 0.00,
    `bet_overtime` DOUBLE(10, 2)        NOT NULL DEFAULT 0.00,
    PRIMARY KEY (`aid`)
)
    COMMENT = 'Employees bet';

CREATE TABLE IF NOT EXISTS `employees_salaries_payed`
(
    `id`          INT UNSIGNED         NOT NULL AUTO_INCREMENT,
    `aid`         SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
    `year`        SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0,
    `month`       SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `date`        DATE                 NOT NULL DEFAULT '0000-00-00',
    `bet`         DOUBLE(10, 2)        NOT NULL DEFAULT 0.00,
    `spending_id` SMALLINT UNSIGNED    NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`),
    KEY `aid` (`aid`)
)
    COMMENT = 'Employees salaries payed';

CREATE TABLE IF NOT EXISTS `employees_reference_works`
(
    `id`       INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `name`     CHAR(60)      NOT NULL DEFAULT '',
    `time`     INT UNSIGNED  NOT NULL DEFAULT 0,
    `units`    CHAR(40)      NOT NULL DEFAULT '',
    `sum`      DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
    `disabled` TINYINT(1)    NOT NULL DEFAULT 0,
    `comments` TEXT,
    PRIMARY KEY (`id`)
)
    COMMENT = 'Reference works';

CREATE TABLE IF NOT EXISTS `employees_works`
(
    `id`          INT UNSIGNED AUTO_INCREMENT NOT NULL PRIMARY KEY,
    `date`        DATETIME                    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `employee_id` SMALLINT(6) UNSIGNED        NOT NULL DEFAULT '0',
    `work_id`     SMALLINT(6) UNSIGNED        NOT NULL DEFAULT '0',
    `ratio`       DOUBLE(6, 2) UNSIGNED       NOT NULL DEFAULT '0.00',
    `sum`         DOUBLE(6, 2) UNSIGNED       NOT NULL DEFAULT '0.00',
    `extra_sum`   DOUBLE(6, 2) UNSIGNED       NOT NULL DEFAULT '0.00',
    `comments`    TEXT                        NOT NULL,
    `paid`        TINYINT(1) UNSIGNED         NOT NULL DEFAULT '0',
    `ext_id`      INT(11) UNSIGNED            NOT NULL DEFAULT '0',
    `aid`         SMALLINT(6) UNSIGNED        NOT NULL DEFAULT '0',
    `work_done`   TINYINT(1) UNSIGNED         NOT NULL DEFAULT '0',
    `fees_id`     INT(11) UNSIGNED            NOT NULL DEFAULT '0',
    KEY `ext_id` (`ext_id`),
    KEY `aid` (`aid`)
)
    COMMENT = 'Employes works';

CREATE TABLE IF NOT EXISTS `employees_bonus_types`
(
    `id`       SMALLINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    `name`     char(60)              NOT NULL DEFAULT '',
    `amount`   DOUBLE(6, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `comments` TEXT,
    PRIMARY KEY (`id`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Bonust types for salaries';

CREATE TABLE IF NOT EXISTS `employees_salary_bonus`
(
    `id`            SMALLINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    `aid`           SMALLINT(6) UNSIGNED  NOT NULL DEFAULT 0,
    `year`          SMALLINT(4) UNSIGNED  NOT NULL DEFAULT 0,
    `month`         SMALLINT(2) UNSIGNED  NOT NULL DEFAULT 0,
    `amount`        DOUBLE(6, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `bonus_type_id` SMALLINT UNSIGNED     NOT NULL DEFAULT '0',
    `date`          DATE                  NOT NULL DEFAULT '0000-00-00',
    PRIMARY KEY (`id`),
    KEY `aid` (`aid`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Bonust to salaries';

CREATE TABLE IF NOT EXISTS `employees_working_time_norms`
(
    `year`  SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0,
    `month` SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `hours` SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,
    `days`  SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,
    UNIQUE KEY `year_month` (`year`, `month`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Entity working time norms';

CREATE TABLE IF NOT EXISTS `employees_cashboxes_moving`
(
    `id`              SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    `amount`          DOUBLE(10, 2)                    NOT NULL DEFAULT 0.00,
    `moving_type_id`  SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    `cashbox_spending`SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    `id_spending`     SMALLINT(6) UNSIGNED             NOT NULL DEFAULT 0,
    `cashbox_coming`  SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    `id_coming`       SMALLINT(6) UNSIGNED             NOT NULL DEFAULT 0,
    `date`            DATE                             NOT NULL DEFAULT '0000-00-00',
    `aid`             SMALLINT(6) UNSIGNED             NOT NULL DEFAULT 0,
    `comments`        TEXT,
    PRIMARY KEY (`id`),
    KEY `aid` (`aid`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Moving';

CREATE TABLE IF NOT EXISTS `employees_moving_types`
(
    `id`       SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    `name`     CHAR(40)                 NOT NULL DEFAULT '',
    `spending_type` TINYINT(4) UNSIGNED NOT NULL DEFAULT 0,
    `coming_type` TINYINT(4) UNSIGNED   NOT NULL DEFAULT 0,
    `comments` TEXT,
    PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Moving types';

CREATE TABLE IF NOT EXISTS `employees_cashboxes_admins`
(
  `cashbox_id`  SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `aid`         SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `add_date`    DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY cashbox_id (aid,cashbox_id)
)
DEFAULT CHARSET=utf8
COMMENT='List of admins for cashboxes';