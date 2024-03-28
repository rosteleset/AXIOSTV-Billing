CREATE TABLE accident_log
(
    al_id         TINYINT UNSIGNED AUTO_INCREMENT
        PRIMARY KEY,
    al_desc       VARCHAR(100)                                     NOT NULL DEFAULT '',
    al_priority   TINYINT UNSIGNED     DEFAULT 0                   NOT NULL,
    al_date       DATETIME             DEFAULT CURRENT_TIMESTAMP() NOT NULL,
    al_aid        SMALLINT(6) UNSIGNED DEFAULT 1                   NOT NULL,
    al_end_time   DATETIME             DEFAULT CURRENT_TIMESTAMP() NOT NULL,
    al_realy_time DATETIME             DEFAULT CURRENT_TIMESTAMP() NULL,
    al_status     TINYINT(3)           DEFAULT 0                   NOT NULL,
    al_name       VARCHAR(255)                                     NOT NULL,
    CONSTRAINT accident_log
        FOREIGN KEY (al_aid) REFERENCES admins (aid)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Accident log';


CREATE TABLE accident_address
(
    id         TINYINT UNSIGNED AUTO_INCREMENT
        PRIMARY KEY,
    ac_id      INT(11) UNSIGNED NULL,
    type_id    INT(11)       NOT NULL,
    address_id VARCHAR (255)       NOT NULL,
    CONSTRAINT address
        FOREIGN KEY (ac_id) REFERENCES accident_log (al_id)
)

    DEFAULT CHARSET = utf8
    COMMENT = 'Accident address';