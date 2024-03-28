UPDATE `maps_layers` SET name = '$lang{PLOT}' WHERE id = 12;

CREATE TABLE `users_phone_pin` (
  `uid` int(11) unsigned NOT NULL,
  `pin_code` varchar(10) NOT NULL DEFAULT '',
  `time_code` datetime NOT NULL,
  `attempts` int(11) unsigned NOT NULL DEFAULT '0',
  UNIQUE KEY `uid` (`uid`)
)
	DEFAULT CHARSET = utf8
	COMMENT = 'User phone pin';