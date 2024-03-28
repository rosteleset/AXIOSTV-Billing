CREATE TABLE IF NOT EXISTS `msgs_workflows`
(
  `id`      INT(11) UNSIGNED    NOT NULL AUTO_INCREMENT,
  `name`    VARCHAR(50)         NOT NULL DEFAULT '',
  `descr`   TEXT                NOT NULL,
  `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `used_times` INT(11)    UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
  )
  DEFAULT CHARSET = utf8
  COMMENT = 'Msgs workflows';

CREATE TABLE IF NOT EXISTS `msgs_workflow_triggers`
(
  `id`    INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `workflow_id`   INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `type`  VARCHAR(50)      NOT NULL DEFAULT '',
  `old_value`  VARCHAR(50) NOT NULL DEFAULT '',
  `new_value`  VARCHAR(50) NOT NULL DEFAULT '',
  `contains`   VARCHAR(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
  )
  DEFAULT CHARSET = utf8
  COMMENT = 'Msgs workflow triggers';

CREATE TABLE IF NOT EXISTS `msgs_workflow_actions`
(
  `id`    INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `workflow_id`   INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `type`  VARCHAR(50)      NOT NULL DEFAULT '',
  `value`  VARCHAR(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
  )
  DEFAULT CHARSET = utf8
  COMMENT = 'Msgs workflow actions';

