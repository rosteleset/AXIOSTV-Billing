ALTER TABLE internet_online CHANGE COLUMN acct_session_id acct_session_id varchar(36) NOT NULL DEFAULT '';
ALTER TABLE iptv_device RENAME TO iptv_devices;
ALTER TABLE msgs_chat CHANGE `reed` `msgs_unread` TINYINT(1);