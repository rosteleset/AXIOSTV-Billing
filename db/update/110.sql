ALTER TABLE msgs_messages ADD send_type SMALLINT (6) UNSIGNED DEFAULT 0 NULL;
ALTER TABLE ureports_tp ADD last_active DATE DEFAULT '0000-00-00';