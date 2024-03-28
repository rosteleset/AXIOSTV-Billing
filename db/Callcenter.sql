SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `callcenter_calls_handler` (
  `user_phone` VARCHAR(20) NOT NULL DEFAULT '',
  `operator_phone` VARCHAR(20) NOT NULL DEFAULT '',
  `status` INT(2) NOT NULL DEFAULT 0,
  `id` VARCHAR(20) NOT NULL DEFAULT '',
  `date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `stop` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `outgoing` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) DEFAULT CHARSET = utf8
  COMMENT = 'Callcenter calls handler';

CREATE TABLE IF NOT EXISTS `callcenter_ivr_log` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `datetime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `phone` VARCHAR(16) NOT NULL DEFAULT '',
  `comment` VARCHAR(50) NOT NULL DEFAULT '',
  `ip` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `status` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT UNSIGNED NOT NULL DEFAULT 0,
  `lead_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `duration` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `unique_id` VARCHAR(20) NOT NULL DEFAULT '',
  `outgoing` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `call_record` VARCHAR(256) NOT NULL DEFAULT '',
  KEY `uid`(`uid`)
) DEFAULT CHARSET = utf8
  COMMENT = 'Voip ivr log';


CREATE TABLE IF NOT EXISTS `callcenter_ivr_menu` (
  `id` SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
  `main_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `number` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `name` VARCHAR(100) NOT NULL DEFAULT '',
  `comments` TEXT,
  `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `function` VARCHAR(100) NOT NULL DEFAULT '',
  `domain_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `audio_file` VARCHAR(200) NOT NULL DEFAULT '',
  `chapter_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`main_id`, `name`, `chapter_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Voip IVR Menu';

CREATE TABLE IF NOT EXISTS `callcenter_cdr` (
  `calldate` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `clid` varchar(80) NOT NULL DEFAULT '',
  `src` varchar(80) NOT NULL DEFAULT '',
  `dst` varchar(80) NOT NULL DEFAULT '',
  `dcontext` varchar(80) NOT NULL DEFAULT '',
  `channel` varchar(80) NOT NULL DEFAULT '',
  `dstchannel` varchar(80) NOT NULL DEFAULT '',
  `lastapp` varchar(80) NOT NULL DEFAULT '',
  `lastdata` varchar(80) NOT NULL DEFAULT '',
  `duration` int(11) NOT NULL DEFAULT '0',
  `billsec` int(11) NOT NULL DEFAULT '0',
  `disposition` varchar(45) NOT NULL DEFAULT '',
  `amaflags` int(11) NOT NULL DEFAULT '0',
  `accountcode` varchar(20) NOT NULL DEFAULT '',
  `userfield` varchar(255) NOT NULL DEFAULT '',
  KEY `calldate` (`calldate`),
  KEY `dst` (`dst`),
  KEY `accountcode` (`accountcode`)
)
  DEFAULT CHARSET = utf8
  COMMENT='Callcenter asterisk CDR';

CREATE TABLE IF NOT EXISTS `callcenter_ivr_menu_chapters`(
	`id` SMALLINT(5) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(20)  NOT NULL  DEFAULT '',
  `numbers` VARCHAR(200) NULL NULL DEFAULT '',
  UNIQUE KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'IVR menus chapters';

-- CREATE TABLE IF NOT EXISTS `call_center_ast_config` (
--   `id` int(11) NOT NULL AUTO_INCREMENT,
--   `cat_metric` int(11) NOT NULL DEFAULT '0',
--   `var_metric` int(11) NOT NULL DEFAULT '0',
--   `commented` int(11) NOT NULL DEFAULT '0',
--   `filename` varchar(128) NOT NULL DEFAULT '',
--   `category` varchar(128) NOT NULL DEFAULT 'default',
--   `var_name` varchar(128) NOT NULL DEFAULT '',
--   `var_val` varchar(128) NOT NULL DEFAULT '',
--   PRIMARY KEY (`id`),
--   KEY `filename_comment` (`filename`,`commented`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=435 DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_cdr` (
--   `accountcode` varchar(20) DEFAULT NULL,
--   `src` varchar(80) DEFAULT NULL,
--   `dst` varchar(80) DEFAULT NULL,
--   `dcontext` varchar(80) DEFAULT NULL,
--   `clid` varchar(80) DEFAULT NULL,
--   `channel` varchar(80) DEFAULT NULL,
--   `dstchannel` varchar(80) DEFAULT NULL,
--   `lastapp` varchar(80) DEFAULT NULL,
--   `lastdata` varchar(80) DEFAULT NULL,
--   `start` datetime DEFAULT NULL,
--   `answer` datetime DEFAULT NULL,
--   `end` datetime DEFAULT NULL,
--   `duration` int(11) DEFAULT NULL,
--   `billsec` int(11) DEFAULT NULL,
--   `disposition` varchar(45) DEFAULT NULL,
--   `amaflags` varchar(45) DEFAULT NULL,
--   `userfield` varchar(256) DEFAULT NULL,
--   `uniqueid` varchar(150) DEFAULT NULL,
--   `linkedid` varchar(150) DEFAULT NULL,
--   `peeraccount` varchar(20) DEFAULT NULL,
--   `sequence` int(11) DEFAULT NULL
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_cel` (
--   `id` int(11) NOT NULL AUTO_INCREMENT,
--   `eventtype` varchar(30) NOT NULL,
--   `eventtime` datetime NOT NULL,
--   `cid_name` varchar(80) NOT NULL,
--   `cid_num` varchar(80) NOT NULL,
--   `cid_ani` varchar(80) NOT NULL,
--   `cid_rdnis` varchar(80) NOT NULL,
--   `cid_dnid` varchar(80) NOT NULL,
--   `exten` varchar(80) NOT NULL,
--   `context` varchar(80) NOT NULL,
--   `channame` varchar(80) NOT NULL,
--   `src` varchar(80) NOT NULL,
--   `dst` varchar(80) NOT NULL,
--   `channel` varchar(80) NOT NULL,
--   `dstchannel` varchar(80) NOT NULL,
--   `appname` varchar(80) NOT NULL,
--   `appdata` varchar(80) NOT NULL,
--   `amaflags` int(11) NOT NULL,
--   `accountcode` varchar(20) NOT NULL,
--   `uniqueid` varchar(32) NOT NULL,
--   `linkedid` varchar(32) NOT NULL,
--   `peer` varchar(80) NOT NULL,
--   `userdeftype` varchar(255) NOT NULL,
--   `eventextra` varchar(255) NOT NULL,
--   `userfield` varchar(255) NOT NULL,
--   PRIMARY KEY (`id`),
--   KEY `uniqueid_index` (`uniqueid`),
--   KEY `linkedid_index` (`linkedid`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_current_calls` (
--   `id` int(20) NOT NULL AUTO_INCREMENT,
--   `caller` varchar(20) NOT NULL DEFAULT '0',
--   `operator` varchar(20) NOT NULL DEFAULT '0',
--   `uid` int(20) NOT NULL DEFAULT '0',
--   `login` varchar(50) NOT NULL DEFAULT '0',
--   `status` int(2) NOT NULL DEFAULT '0',
--   PRIMARY KEY (`id`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_extensions` (
--   `id` int(11) NOT NULL AUTO_INCREMENT,
--   `context` varchar(20) NOT NULL DEFAULT '',
--   `exten` varchar(20) NOT NULL DEFAULT '',
--   `priority` int(4) NOT NULL,
--   `app` varchar(20) NOT NULL DEFAULT '',
--   `appdata` varchar(128) NOT NULL DEFAULT '',
--   KEY `id` (`id`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=2185 DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_incoming_routes` (
--   `id` int(5) NOT NULL AUTO_INCREMENT,
--   `name` varchar(100) DEFAULT NULL,
--   `mohclass` varchar(100) NOT NULL DEFAULT 'default',
--   `context` varchar(50) NOT NULL DEFAULT 'from_trunk',
--   `dest_type` int(20) DEFAULT NULL,
--   `dest_id` varchar(20) DEFAULT NULL,
--   PRIMARY KEY (`id`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_intervals` (
--   `id` int(5) NOT NULL AUTO_INCREMENT,
--   `name` varchar(50) NOT NULL,
--   `time_begin` varchar(5) NOT NULL DEFAULT '00:00',
--   `time_end` varchar(5) NOT NULL DEFAULT '00:00',
--   `week_begin` varchar(10) NOT NULL,
--   `week_end` varchar(10) NOT NULL,
--   `day_begin` int(2) NOT NULL,
--   `day_end` int(2) NOT NULL,
--   `month_begin` varchar(10) NOT NULL,
--   `month_end` varchar(10) NOT NULL,
--   `dest_type_true` int(5) NOT NULL DEFAULT '0',
--   `dest_id_true` varchar(20) NOT NULL DEFAULT '0',
--   `dest_type_false` int(5) NOT NULL DEFAULT '0',
--   `dest_id_false` varchar(20) NOT NULL DEFAULT '0',
--   PRIMARY KEY (`id`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_ivr` (
--   `id` int(5) unsigned NOT NULL AUTO_INCREMENT,
--   `name` varchar(50) CHARACTER SET utf8 NOT NULL,
--   `description` varchar(50) CHARACTER SET utf8 NOT NULL,
--   `message_id` int(5) unsigned NOT NULL,
--   `invalid_loops` int(2) unsigned NOT NULL DEFAULT '1',
--   `timeout` int(2) unsigned NOT NULL DEFAULT '1',
--   `err_message` int(5) unsigned NOT NULL DEFAULT '0',
--   `undef_message` int(5) unsigned NOT NULL DEFAULT '0',
--   PRIMARY KEY (`id`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4;

-- CREATE TABLE IF NOT EXISTS `call_center_ivr_function` (
--   `id` int(5) NOT NULL AUTO_INCREMENT,
--   `menu_id` int(5) NOT NULL DEFAULT '0',
--   `exten` int(1) NOT NULL DEFAULT '0',
--   `message_id` int(5) NOT NULL DEFAULT '0',
--   `dest_type` varchar(50) NOT NULL,
--   `dest_id` varchar(20) NOT NULL,
--   `menu_ret` int(1) NOT NULL DEFAULT '0',
--   PRIMARY KEY (`id`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_ivr_log` (
--   `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
--   `datetime` datetime NOT NULL  DEFAULT CURRENT_TIMESTAMP,
--   `phone` varchar(16) NOT NULL DEFAULT '',
--   `comment` varchar(20) NOT NULL DEFAULT '',
--   `ip` int(11) unsigned NOT NULL DEFAULT '0',
--   `status` tinyint(2) unsigned NOT NULL DEFAULT '0',
--   `uid` int(10) unsigned NOT NULL DEFAULT '0',
--   PRIMARY KEY (`id`),
--   KEY `uid` (`uid`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=129 DEFAULT CHARSET=utf8 COMMENT='Callcenter ivr log';


-- CREATE TABLE IF NOT EXISTS `call_center_ivr_log` (
--   `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
--   `datetime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
--   `phone` varchar(16) NOT NULL DEFAULT '',
--   `comment` varchar(20) NOT NULL DEFAULT '',
--   `ip` int(11) unsigned NOT NULL DEFAULT '0',
--   `status` tinyint(2) unsigned NOT NULL DEFAULT '0',
--   `uid` int(10) unsigned NOT NULL DEFAULT '0',
--   PRIMARY KEY (`id`),
--   KEY `uid` (`uid`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=129 DEFAULT CHARSET=utf8 COMMENT='Callcenter ivr log';

-- CREATE TABLE IF NOT EXISTS `call_center_messages` (
--   `id` int(5) NOT NULL AUTO_INCREMENT,
--   `name` varchar(50) NOT NULL,
--   `type` varchar(4) NOT NULL,
--   `value` varchar(100) NOT NULL,
--   `data` longblob NOT NULL,
--   `status` int(1) NOT NULL DEFAULT '1',
--   PRIMARY KEY (`id`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=67 DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_out_num` (
--   `id` int(5) unsigned NOT NULL AUTO_INCREMENT,
--   `exten` varchar(12) NOT NULL DEFAULT '0',
--   `fio` varchar(50) NOT NULL DEFAULT '0',
--   PRIMARY KEY (`id`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_outbound_routes` (
--   `id` int(10) NOT NULL AUTO_INCREMENT,
--   `name` varchar(50) NOT NULL,
--   `mohclass` varchar(50) NOT NULL,
--   `context` varchar(100) NOT NULL DEFAULT 'from_call_center',
--   PRIMARY KEY (`id`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=70 DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_queue_log` (
--   `time` varchar(32) DEFAULT NULL,
--   `callid` char(64) DEFAULT NULL,
--   `queuename` char(64) DEFAULT NULL,
--   `agent` char(64) DEFAULT NULL,
--   `event` char(32) DEFAULT NULL,
--   `data` char(64) DEFAULT NULL,
--   `data1` char(64) DEFAULT NULL,
--   `data2` char(64) DEFAULT NULL,
--   `data3` char(64) DEFAULT NULL,
--   `data4` char(64) DEFAULT NULL,
--   `data5` char(64) DEFAULT NULL
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_queue_members` (
--   `uniqueid` int(10) unsigned NOT NULL AUTO_INCREMENT,
--   `membername` varchar(40) DEFAULT NULL,
--   `queue_name` varchar(128) DEFAULT NULL,
--   `interface` varchar(128) DEFAULT NULL,
--   `penalty` int(11) DEFAULT NULL,
--   `paused` int(11) DEFAULT NULL,
--   PRIMARY KEY (`uniqueid`),
--   UNIQUE KEY `queue_interface` (`queue_name`,`interface`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_queues` (
--   `name` varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
--   `musiconhold` varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `message` varchar(20) DEFAULT NULL,
--   `announce` varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `context` varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `timeout` int(11) DEFAULT NULL,
--   `maxwait` int(10) DEFAULT NULL,
--   `timeoutpriority` varchar(5) DEFAULT NULL,
--   `monitor_type` varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `monitor_format` varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `queue_youarenext` varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `queue_thereare` varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `queue_callswaiting` varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `queue_holdtime` varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `queue_minutes` varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `queue_seconds` varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `queue_lessthan` varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `queue_thankyou` varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `queue_reporthold` varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `announce_frequency` tinyint(2) DEFAULT NULL,
--   `announce_round_seconds` int(11) DEFAULT NULL,
--   `announce_holdtime` varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `announce_position` varchar(10) DEFAULT NULL,
--   `retry` tinyint(2) DEFAULT NULL,
--   `wrapuptime` int(11) DEFAULT NULL,
--   `maxlen` int(11) DEFAULT NULL,
--   `servicelevel` int(11) DEFAULT NULL,
--   `strategy` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `joinempty` varchar(100) DEFAULT NULL,
--   `leavewhenempty` varchar(100) DEFAULT NULL,
--   `eventmemberstatus` tinyint(1) DEFAULT NULL,
--   `eventwhencalled` varchar(6) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `reportholdtime` varchar(5) DEFAULT NULL,
--   `memberdelay` int(11) DEFAULT NULL,
--   `weight` int(11) DEFAULT NULL,
--   `timeoutrestart` tinyint(1) DEFAULT NULL,
--   `periodic_announce` varchar(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
--   `periodic_announce_frequency` int(11) DEFAULT NULL,
--   `random_periodic_announce` varchar(10) DEFAULT NULL,
--   `ringinuse` varchar(5) DEFAULT NULL,
--   `setinterfacevar` tinyint(1) DEFAULT NULL,
--   `setqueuevar` tinyint(1) NOT NULL,
--   `setqueueentryvar` tinyint(1) NOT NULL,
--   UNIQUE KEY `name` (`name`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_sipusers` (
--   `id` int(11) NOT NULL AUTO_INCREMENT,
--   `sip_type` enum('trunk','user') DEFAULT 'user',
--   `username` varchar(50) DEFAULT NULL,
--   `name` varchar(100) NOT NULL,
--   `ringtimer` int(3) NOT NULL DEFAULT '60',
--   `disable` varchar(4) NOT NULL DEFAULT 'off',
--   `max_line` int(2) NOT NULL DEFAULT '2',
--   `ipaddr` varchar(45) DEFAULT NULL,
--   `port` int(5) DEFAULT '5060',
--   `regseconds` int(11) DEFAULT NULL,
--   `defaultuser` varchar(10) DEFAULT NULL,
--   `fullcontact` varchar(80) DEFAULT NULL,
--   `regserver` varchar(20) DEFAULT NULL,
--   `useragent` varchar(20) DEFAULT NULL,
--   `lastms` int(11) DEFAULT NULL,
--   `host` varchar(40) DEFAULT NULL,
--   `type` enum('friend','user','peer') DEFAULT NULL,
--   `context` varchar(40) DEFAULT NULL,
--   `deny` varchar(95) DEFAULT '0.0.0.0/0.0.0.0',
--   `permit` varchar(95) DEFAULT '0.0.0.0/0.0.0.0',
--   `secret` varchar(40) DEFAULT NULL,
--   `md5secret` varchar(40) DEFAULT NULL,
--   `remotesecret` varchar(40) DEFAULT NULL,
--   `transport` enum('udp','tcp','udp,tcp','tcp,udp') DEFAULT 'udp',
--   `dtmfmode` enum('rfc2833','info','shortinfo','inband','auto') DEFAULT 'auto',
--   `directmedia` enum('yes','no','nonat','update') DEFAULT NULL,
--   `nat` varchar(29) DEFAULT 'no',
--   `callgroup` varchar(40) DEFAULT '1',
--   `pickupgroup` varchar(40) DEFAULT '1',
--   `language` varchar(40) DEFAULT 'ru',
--   `disallow` varchar(40) DEFAULT 'all',
--   `allow` varchar(40) DEFAULT 'alaw;ulaw',
--   `insecure` varchar(40) DEFAULT NULL,
--   `trustrpid` enum('yes','no') DEFAULT NULL,
--   `progressinband` enum('yes','no','never') DEFAULT NULL,
--   `promiscredir` enum('yes','no') DEFAULT NULL,
--   `useclientcode` enum('yes','no') DEFAULT NULL,
--   `accountcode` varchar(40) DEFAULT NULL,
--   `setvar` varchar(40) DEFAULT NULL,
--   `callerid` varchar(40) DEFAULT NULL,
--   `amaflags` varchar(40) DEFAULT NULL,
--   `callcounter` enum('yes','no') DEFAULT 'yes',
--   `busylevel` int(11) DEFAULT NULL,
--   `allowoverlap` enum('yes','no') DEFAULT NULL,
--   `allowsubscribe` enum('yes','no') DEFAULT NULL,
--   `videosupport` enum('yes','no') DEFAULT NULL,
--   `maxcallbitrate` int(11) DEFAULT NULL,
--   `rfc2833compensate` enum('yes','no') DEFAULT NULL,
--   `mailbox` varchar(40) DEFAULT NULL,
--   `session-timers` enum('accept','refuse','originate') DEFAULT NULL,
--   `session-expires` int(11) DEFAULT NULL,
--   `session-minse` int(11) DEFAULT NULL,
--   `session-refresher` enum('uac','uas') DEFAULT NULL,
--   `t38pt_usertpsource` varchar(40) DEFAULT NULL,
--   `regexten` varchar(40) DEFAULT NULL,
--   `fromdomain` varchar(40) DEFAULT NULL,
--   `fromuser` varchar(40) DEFAULT NULL,
--   `qualify` varchar(10) DEFAULT 'no',
--   `defaultip` varchar(45) DEFAULT NULL,
--   `rtptimeout` int(11) DEFAULT NULL,
--   `rtpholdtimeout` int(11) DEFAULT NULL,
--   `sendrpid` enum('yes','no') DEFAULT NULL,
--   `outboundproxy` varchar(40) DEFAULT NULL,
--   `callbackextension` varchar(40) DEFAULT NULL,
--   `timert1` int(11) DEFAULT NULL,
--   `timerb` int(11) DEFAULT NULL,
--   `qualifyfreq` int(11) DEFAULT '60',
--   `constantssrc` enum('yes','no') DEFAULT NULL,
--   `contactpermit` varchar(95) DEFAULT NULL,
--   `contactdeny` varchar(95) DEFAULT NULL,
--   `usereqphone` enum('yes','no') DEFAULT NULL,
--   `textsupport` enum('yes','no') DEFAULT NULL,
--   `faxdetect` enum('yes','no') DEFAULT NULL,
--   `buggymwi` enum('yes','no') DEFAULT NULL,
--   `auth` varchar(40) DEFAULT NULL,
--   `fullname` varchar(40) DEFAULT NULL,
--   `trunkname` varchar(40) DEFAULT NULL,
--   `cid_number` varchar(40) DEFAULT NULL,
--   `callingpres` enum('allowed_not_screened','allowed_passed_screen','allowed_failed_screen','allowed','prohib_not_screened','prohib_passed_screen','prohib_failed_screen','prohib') DEFAULT NULL,
--   `mohinterpret` varchar(40) DEFAULT NULL,
--   `mohsuggest` varchar(40) DEFAULT NULL,
--   `parkinglot` varchar(40) DEFAULT NULL,
--   `hasvoicemail` enum('yes','no') DEFAULT NULL,
--   `subscribemwi` enum('yes','no') DEFAULT NULL,
--   `vmexten` varchar(40) DEFAULT NULL,
--   `autoframing` enum('yes','no') DEFAULT NULL,
--   `rtpkeepalive` int(11) DEFAULT NULL,
--   `call-limit` int(11) DEFAULT NULL,
--   `g726nonstandard` enum('yes','no') DEFAULT NULL,
--   `ignoresdpversion` enum('yes','no') DEFAULT NULL,
--   `allowtransfer` enum('yes','no') DEFAULT NULL,
--   `dynamic` enum('yes','no') DEFAULT NULL,
--   PRIMARY KEY (`id`),
--   UNIQUE KEY `name` (`name`),
--   KEY `ipaddr` (`ipaddr`,`port`),
--   KEY `host` (`host`,`port`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=178 DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_sys_func` (
--   `id` int(5) NOT NULL AUTO_INCREMENT,
--   `name` varchar(50) NOT NULL,
--   `function` varchar(20) NOT NULL DEFAULT '0',
--   `dest_type` int(5) NOT NULL DEFAULT '0',
--   `dest_id` varchar(20) NOT NULL DEFAULT '0',
--   PRIMARY KEY (`id`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_trunks` (
--   `id` int(11) NOT NULL AUTO_INCREMENT,
--   `name` varchar(50) NOT NULL DEFAULT '',
--   `trunk_type` varchar(20) NOT NULL,
--   `outcid` varchar(40) NOT NULL DEFAULT '',
--   `max_line` varchar(6) DEFAULT '',
--   `sip_type` varchar(10) DEFAULT NULL,
--   `channelid` varchar(255) NOT NULL DEFAULT '',
--   `prefix` varchar(50) DEFAULT NULL,
--   `channelcontext` int(10) DEFAULT NULL,
--   `usercontext` int(10) DEFAULT NULL,
--   `register` varchar(255) DEFAULT NULL,
--   `register_id` int(10) DEFAULT NULL,
--   `disabled` varchar(4) DEFAULT 'off',
--   `busy_next` varchar(4) DEFAULT 'off',
--   PRIMARY KEY (`id`),
--   UNIQUE KEY `trunk_type` (`trunk_type`,`channelid`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_users_phone` (
--   `id` int(10) NOT NULL AUTO_INCREMENT,
--   `uid` int(11) unsigned NOT NULL,
--   `phone` varchar(15) NOT NULL,
--   `name` varchar(50) NOT NULL,
--   PRIMARY KEY (`id`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=71 DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_voiceboxes` (
--   `uniqueid` int(4) NOT NULL AUTO_INCREMENT,
--   `customer_id` varchar(10) DEFAULT NULL,
--   `context` varchar(10) NOT NULL,
--   `mailbox` varchar(10) NOT NULL,
--   `password` varchar(12) NOT NULL,
--   `fullname` varchar(150) DEFAULT NULL,
--   `email` varchar(50) DEFAULT NULL,
--   `pager` varchar(50) DEFAULT NULL,
--   `tz` varchar(10) DEFAULT 'central',
--   `attach` enum('yes','no') NOT NULL DEFAULT 'yes',
--   `saycid` enum('yes','no') NOT NULL DEFAULT 'yes',
--   `dialout` varchar(10) DEFAULT NULL,
--   `callback` varchar(10) DEFAULT NULL,
--   `review` enum('yes','no') NOT NULL DEFAULT 'no',
--   `operator` enum('yes','no') NOT NULL DEFAULT 'no',
--   `envelope` enum('yes','no') NOT NULL DEFAULT 'no',
--   `sayduration` enum('yes','no') NOT NULL DEFAULT 'no',
--   `saydurationm` tinyint(4) NOT NULL DEFAULT '1',
--   `sendvoicemail` enum('yes','no') NOT NULL DEFAULT 'no',
--   `delete` enum('yes','no') DEFAULT 'no',
--   `nextaftercmd` enum('yes','no') NOT NULL DEFAULT 'yes',
--   `forcename` enum('yes','no') NOT NULL DEFAULT 'no',
--   `forcegreetings` enum('yes','no') NOT NULL DEFAULT 'no',
--   `hidefromdir` enum('yes','no') NOT NULL DEFAULT 'yes',
--   `stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
--   PRIMARY KEY (`uniqueid`),
--   KEY `mailbox_context` (`mailbox`,`context`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_voicemessages` (
--   `id` int(11) NOT NULL AUTO_INCREMENT,
--   `msgnum` int(11) NOT NULL DEFAULT '0',
--   `dir` varchar(80) DEFAULT '',
--   `context` varchar(80) DEFAULT '',
--   `macrocontext` varchar(80) DEFAULT '',
--   `callerid` varchar(40) DEFAULT '',
--   `origtime` varchar(40) DEFAULT '',
--   `duration` varchar(20) DEFAULT '',
--   `mailboxuser` varchar(80) DEFAULT '',
--   `mailboxcontext` varchar(80) DEFAULT '',
--   `recording` longblob,
--   `flag` varchar(128) DEFAULT '',
--   PRIMARY KEY (`id`),
--   KEY `dir` (`dir`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- CREATE TABLE IF NOT EXISTS `call_center_welcome` (
--   `id` int(5) NOT NULL AUTO_INCREMENT,
--   `name` varchar(50) NOT NULL,
--   `message_id` int(5) NOT NULL DEFAULT '0',
--   `dest_type` int(5) NOT NULL DEFAULT '0',
--   `dest_id` varchar(20) NOT NULL DEFAULT '0',
--   PRIMARY KEY (`id`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8;


