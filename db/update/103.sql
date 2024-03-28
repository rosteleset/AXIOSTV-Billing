CREATE TABLE `msgs_admin_plugins` (
  `id`           SMALLINT(6) UNSIGNED  NOT NULL DEFAULT 0,
  `plugin_name`  VARCHAR(30)           NOT NULL DEFAULT '',
  `module`       VARCHAR(15)           NOT NULL DEFAULT '',
  `priority`     TINYINT(2)  UNSIGNED  NOT NULL DEFAULT 0
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Set admin msgs plugin';

CREATE TABLE IF NOT EXISTS `admins_payments_types` (
  id               INT         UNSIGNED NOT NULL AUTO_INCREMENT,
  payments_type_id TINYINT(4)  UNSIGNED NOT NULL DEFAULT '0',
  aid              SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (id),
  KEY `payments_type_id` (`payments_type_id`),
  KEY `aid` (`aid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Allowed payments types for admins';
