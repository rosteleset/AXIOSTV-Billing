ALTER TABLE `abon_user_list` ADD KEY `uid` (`uid`, `tp_id`);

ALTER TABLE `accident_address` ADD KEY `address_id` (`address_id`);
ALTER TABLE `accident_address` ADD KEY `type_id` (`type_id`);

ALTER TABLE `accident_log` ADD KEY `status` (`status`);

ALTER TABLE `admin_actions` ADD KEY `action_type` (`action_type`);
ALTER TABLE `admin_actions` ADD KEY `aid` (`aid`);
ALTER TABLE `admin_actions` ADD KEY `uid` (`uid`);

ALTER TABLE `admin_system_actions` ADD KEY `action_type` (`action_type`);
ALTER TABLE `admin_system_actions` ADD KEY `aid` (`aid`);

ALTER TABLE `admins_access` ADD KEY `aid` (`aid`);

ALTER TABLE `admins_contacts` ADD KEY `aid` (`aid`);
ALTER TABLE `admins_contacts` ADD KEY `type_id` (`type_id`);

ALTER TABLE `admins_full_log` ADD KEY `aid` (`aid`);

ALTER TABLE `admins_groups` ADD KEY `gid` (`gid`, `aid`);

ALTER TABLE `admins_payments_types` ADD KEY `aid` (`aid`);
ALTER TABLE `admins_payments_types` ADD KEY `payments_type_id` (`payments_type_id`);

ALTER TABLE `admins` ADD KEY domain_id (`domain_id`);

ALTER TABLE `bills` ADD KEY `uid` (`uid`, `company_id`);

ALTER TABLE `bonus_log` ADD KEY `date` (`date`);
ALTER TABLE `bonus_log` ADD KEY `uid` (`uid`);

ALTER TABLE `builds` DROP KEY `street_id`;

ALTER TABLE `cablecat_scheme_elements` ADD KEY `id` (`id`);

ALTER TABLE `cablecat_scheme_links` ADD KEY `id` (`id`);

ALTER TABLE `cablecat_schemes` ADD KEY `commutation_id` (`commutation_id`);

ALTER TABLE `callcenter_cdr` ADD KEY `accountcode` (`accountcode`);
ALTER TABLE `callcenter_cdr` ADD KEY `calldate` (`calldate`);
ALTER TABLE `callcenter_cdr` ADD KEY `dst` (`dst`);

ALTER TABLE `callcenter_ivr_log` ADD KEY `uid`(`uid`);

ALTER TABLE `cams_folder` DROP KEY `title`;

ALTER TABLE `cams_main` ADD KEY `uid` (`uid`);

ALTER TABLE `cams_tp` ADD KEY `tp_id` (`tp_id`);

ALTER TABLE `cards_users` ADD KEY `diller_id` (`diller_id`);
ALTER TABLE `cards_users` ADD KEY `login` (`login`);

ALTER TABLE `companies` ADD KEY `bill_id` (`bill_id`);

ALTER TABLE `crm_leads` ADD KEY competitor_id (`competitor_id`);

ALTER TABLE `dhcphosts_hosts` ADD KEY `mac` (`mac`);
ALTER TABLE `dhcphosts_hosts` ADD KEY `uid` (`uid`);

ALTER TABLE `dhcphosts_leases` ADD KEY `ends` (`ends`);
ALTER TABLE `dhcphosts_leases` ADD KEY `ip` (`ip`);
ALTER TABLE `dhcphosts_leases` ADD KEY `nas_id` (`nas_id`);

ALTER TABLE `docs_act_orders` ADD KEY `act_id` (`act_id`);

ALTER TABLE `docs_acts` ADD KEY `domain_id` (`domain_id`);

ALTER TABLE `docs_invoice_orders` ADD KEY `fees_id` (`fees_id`);
ALTER TABLE `docs_invoice_orders` ADD KEY `invoice_id` (`invoice_id`);

ALTER TABLE `docs_invoices` ADD KEY `aid` (`aid`);
ALTER TABLE `docs_invoices` ADD KEY `domain_id` (`domain_id`);
ALTER TABLE `docs_invoices` ADD KEY `payment_id` (`payment_id`);
ALTER TABLE `docs_invoices` ADD KEY `uid` (`uid`);

ALTER TABLE `docs_receipt_orders` ADD KEY `fees_id` (`fees_id`);
ALTER TABLE `docs_receipt_orders` ADD KEY `receipt_id` (`receipt_id`);

ALTER TABLE `docs_receipts` ADD KEY `domain_id` (`domain_id`);
ALTER TABLE `docs_receipts` ADD KEY `payment_id` (`payment_id`);

ALTER TABLE `docs_tax_invoice_orders` ADD KEY `aid` (`tax_invoice_id`);

ALTER TABLE `docs_tax_invoices` ADD KEY `domain_id` (`domain_id`);

ALTER TABLE `dv_calls` ADD KEY `acct_session_id` (`acct_session_id`);
ALTER TABLE `dv_calls` ADD KEY `framed_ip_address` (`framed_ip_address`);
ALTER TABLE `dv_calls` ADD KEY `uid` (`uid`);
ALTER TABLE `dv_calls` ADD KEY `user_name` (`user_name`);

ALTER TABLE `dv_log_intervals` ADD KEY `acct_session_id` (`acct_session_id`);
ALTER TABLE `dv_log_intervals` ADD KEY `session_interval` (`acct_session_id`, `interval_id`);
ALTER TABLE `dv_log_intervals` ADD KEY `uid` (`uid`);

ALTER TABLE `dv_log` ADD KEY `uid` (`uid`, `start`);

ALTER TABLE `dv_main` ADD KEY `CID` (`cid`);
ALTER TABLE `dv_main` ADD KEY `tp_id` (`tp_id`);

ALTER TABLE `economizer_tariffs` ADD KEY `id` (`id`);
ALTER TABLE `economizer_user_info` ADD KEY `id` (`id`);

ALTER TABLE `employees_cashboxes_moving` ADD KEY `aid` (`aid`);

ALTER TABLE `employees_coming` ADD KEY `aid` (`aid`);

ALTER TABLE `employees_daily_notes` ADD KEY `aid` (`aid`);

ALTER TABLE `employees_duty` ADD KEY `aid` (`aid`);

ALTER TABLE `employees_ext_params` ADD KEY `aid` (`aid`);

ALTER TABLE `employees_geolocation` ADD KEY `build_id` (`build_id`);
ALTER TABLE `employees_geolocation` ADD KEY `district_id` (`district_id`);
ALTER TABLE `employees_geolocation` ADD KEY `employee_id` (`employee_id`);
ALTER TABLE `employees_geolocation` ADD KEY `street_id` (`street_id`);

ALTER TABLE `employees_mobile_reports` ADD KEY `aid` (`aid`);

ALTER TABLE `employees_rfid_log` ADD KEY `aid` (`aid`);

ALTER TABLE `employees_salaries_payed` ADD KEY `aid` (`aid`);

ALTER TABLE `employees_salary_bonus` ADD KEY `aid` (`aid`);

ALTER TABLE `employees_spending` ADD KEY `aid` (`aid`);

ALTER TABLE `employees_works` ADD KEY `aid` (`aid`);
ALTER TABLE `employees_works` ADD KEY `ext_id` (`ext_id`);

ALTER TABLE `equipment_graphs` ADD KEY (`nas_id`);

ALTER TABLE `equipment_infos` ADD KEY model_id (model_id);

ALTER TABLE `equipment_mac_log` ADD KEY `mac` (`mac`);
ALTER TABLE `equipment_mac_log` ADD KEY `nas_id` (`nas_id`);

ALTER TABLE `equipment_models` ADD KEY type_id (`type_id`);

ALTER TABLE `equipment_pon_onu` ADD KEY onu_dhcp_port (`onu_dhcp_port`);
ALTER TABLE `equipment_pon_onu` ADD KEY onu_status (`onu_status`);
ALTER TABLE `equipment_pon_onu` ADD KEY port_id (`port_id`);
ALTER TABLE `equipment_pon_onu` ADD KEY onu_mac_serial (`onu_mac_serial`);

ALTER TABLE `equipment_pon_ports` ADD KEY nas_id (`nas_id`);

ALTER TABLE `errors_log` ADD KEY `i_user_date` (`user`, `date`);
ALTER TABLE `errors_log` ADD KEY `log_type` (`log_type`);

ALTER TABLE `events_priority_send_types` ADD KEY `priority_id` (`priority_id`);

ALTER TABLE `events` ADD KEY `aid` (`aid`);
ALTER TABLE `events` ADD KEY `group_id` (`group_id`);
ALTER TABLE `events` ADD KEY `priority_id` (`priority_id`);
ALTER TABLE `events` ADD KEY `privacy_id` (`privacy_id`);
ALTER TABLE `events` ADD KEY `state_id` (`state_id`);

ALTER TABLE `exchange_rate_log` ADD KEY `date` (`date`);

ALTER TABLE `extfin_paids_periodic` ADD KEY `aid` (`aid`);
ALTER TABLE `extfin_paids_periodic` ADD KEY `type_id` (`type_id`);
ALTER TABLE `extfin_paids_periodic` ADD KEY `uid` (`uid`);

ALTER TABLE `fees` ADD KEY `aid` (`aid`);
ALTER TABLE `fees` ADD KEY `date` (`date`);
ALTER TABLE `fees` ADD KEY `uid` (`uid`);

ALTER TABLE `filearch_film_actors` ADD KEY `actor_id` (`actor_id`);
ALTER TABLE `filearch_film_genres` ADD KEY `video_id` (`video_id`);

ALTER TABLE `filearch_state` ADD KEY `file_id` (`file_id`);

ALTER TABLE `info_change_comments` ADD KEY `aid` (`aid`);
ALTER TABLE `info_change_comments` ADD KEY `uid` (`uid`);

ALTER TABLE `info_info` ADD KEY `admin_id` (`admin_id`);
ALTER TABLE `info_info` ADD KEY `comment_id` (`comment_id`);
ALTER TABLE `info_info` ADD KEY `location_id` (`location_id`);

ALTER TABLE `internet_log_intervals` ADD KEY `acct_session_id` (`acct_session_id`);
ALTER TABLE `internet_log_intervals` ADD KEY `session_interval` (`acct_session_id`, `interval_id`);
ALTER TABLE `internet_log_intervals` ADD KEY `uid` (`uid`);

ALTER TABLE `internet_log` ADD KEY `uid` (`uid`, `start`);

ALTER TABLE `internet_main` ADD KEY `cid` (`cid`);
ALTER TABLE `internet_main` ADD KEY `cpe_mac` (`cpe_mac`);
ALTER TABLE `internet_main` ADD KEY `nas_id` (`nas_id`);
ALTER TABLE `internet_main` ADD KEY `port` (`port`);
ALTER TABLE `internet_main` ADD KEY `tp_id` (`tp_id`);
ALTER TABLE `internet_main` ADD KEY `uid` (`uid`);

ALTER TABLE `internet_online` ADD KEY (`switch_mac`);
ALTER TABLE `internet_online` ADD KEY `acct_session_id` (`acct_session_id`);
ALTER TABLE `internet_online` ADD KEY `framed_ip_address` (`framed_ip_address`);
ALTER TABLE `internet_online` ADD KEY `nas_id` (`nas_id`);
ALTER TABLE `internet_online` ADD KEY `service_id` (`service_id`);
ALTER TABLE `internet_online` ADD KEY `switch_mac` (`switch_mac`);
ALTER TABLE `internet_online` ADD KEY `uid` (`uid`);
ALTER TABLE `internet_online` ADD KEY `user_name` (`user_name`);
ALTER TABLE `internet_online` ADD KEY nas_id (`nas_id`);

ALTER TABLE `ipn_log` ADD KEY `session_id` (`session_id`);
ALTER TABLE `ipn_log` ADD KEY `uid_traffic_class` (`uid`, `traffic_class`);
ALTER TABLE `ipn_log` ADD KEY `uid` (`uid`);

ALTER TABLE `ippools_ips` ADD KEY `ip_status` (`ip`, `status`);
ALTER TABLE `ippools_ips` ADD KEY `ippool_id` (`ippool_id`);

ALTER TABLE `ippools` ADD KEY `ipv6_prefix` (`ipv6_prefix`);
ALTER TABLE `ippools` ADD KEY `guest` (`guest`);
ALTER TABLE `ippools` ADD KEY `priority` (`priority`);
ALTER TABLE `ippools` ADD KEY `static` (`static`);

ALTER TABLE `iptv_calls` ADD KEY `acct_session_id` (`acct_session_id`);
ALTER TABLE `iptv_calls` ADD KEY `service_id` (`service_id`);
ALTER TABLE `iptv_calls` ADD KEY `uid` (`uid`);

ALTER TABLE `iptv_devices` ADD KEY `service_id` (`service_id`);
ALTER TABLE `iptv_devices` ADD KEY `uid` (`uid`);

ALTER TABLE `iptv_main` ADD KEY `tp_id` (`tp_id`);
ALTER TABLE `iptv_main` ADD KEY `uid` (`uid`);

ALTER TABLE `iptv_services` ADD KEY `status` (`status`);

ALTER TABLE `iptv_subscribes` ADD KEY `ext_id` (`ext_id`);
ALTER TABLE `iptv_subscribes` ADD KEY `tp_id` (`tp_id`);

ALTER TABLE `iptv_ti_channels` ADD KEY interval_id (`interval_id`);

ALTER TABLE `iptv_users_channels` ADD KEY `uid` (`uid`);

ALTER TABLE `mail_boxes` ADD KEY `username_antispam` (`username`, `antispam`);
ALTER TABLE `mail_boxes` ADD KEY `username_antivirus` (`username`, `antivirus`);

ALTER TABLE `mail_spamassassin` ADD KEY `preference` (`preference`);
ALTER TABLE `mail_spamassassin` ADD KEY `username_preference_value` (`username`, `preference`, `value`);
ALTER TABLE `mail_spamassassin` ADD KEY `username` (`username`);

ALTER TABLE `maps_points` ADD KEY `location_id` (`location_id`);

ALTER TABLE `maps_polygon_points` ADD KEY `polygon_id` (`polygon_id`);

ALTER TABLE `maps_polygons` ADD KEY `object_id` (`object_id`);

ALTER TABLE `maps_polyline_points` ADD KEY `polyline_id` (`polyline_id`);

ALTER TABLE `maps_polylines` ADD KEY `object_id` (`object_id`);

ALTER TABLE `mdelivery_attachments` ADD KEY `article_attachment_article_id` (`message_id`);

ALTER TABLE `msgs_attachments` ADD KEY `article_attachment_article_id` (`message_id`);

ALTER TABLE `msgs_dispatch` ADD KEY `plan_date` (`plan_date`, `state`);

ALTER TABLE `msgs_message_pb` ADD KEY (`main_msg`);

ALTER TABLE `msgs_messages` ADD KEY `chapter` (`chapter`);
ALTER TABLE `msgs_messages` ADD KEY `date` (`date`);
ALTER TABLE `msgs_messages` ADD KEY `dispatch_id` (`dispatch_id`);
ALTER TABLE `msgs_messages` ADD KEY `state` (`state`);
ALTER TABLE `msgs_messages` ADD KEY `uid` (`uid`);

ALTER TABLE `msgs_permits` ADD KEY `aid` (`aid`);

ALTER TABLE `msgs_quick_replys_tags` ADD KEY `msg_id` (`msg_id`);

ALTER TABLE `msgs_reply` ADD KEY `datetime` (`datetime`);
ALTER TABLE `msgs_reply` ADD KEY `main_msg` (`main_msg`);

ALTER TABLE `msgs_team_ticket` ADD KEY `msgs_id_team_fk` (`id_team`);

ALTER TABLE `msgs_unreg_requests` ADD KEY `datetime` (`datetime`);
ALTER TABLE `msgs_unreg_requests` ADD KEY `location_id` (`location_id`);
ALTER TABLE `msgs_unreg_requests` ADD KEY `state` (`state`);

ALTER TABLE `msgs_watch` ADD KEY (`main_msg`);

ALTER TABLE `nas_ippools` ADD KEY `pool_id` (`pool_id`);

ALTER TABLE `nas` ADD KEY `mac` (`mac`);

ALTER TABLE `netblock_domain_mask` ADD KEY `id` (`id`);
ALTER TABLE `netblock_domain` ADD KEY `id` (`id`);

ALTER TABLE `netblock_ip` ADD KEY `id` (`id`);

ALTER TABLE `netblock_ports` ADD KEY `id` (`id`);

ALTER TABLE `netblock_ssl` ADD KEY `id` (`id`);

ALTER TABLE `netblock_url` ADD KEY `id` (`id`);

ALTER TABLE `notepad_checklist_rows` ADD KEY `note_id` (`note_id`);

ALTER TABLE `notepad` ADD KEY `aid` (`aid`);

ALTER TABLE `payments_pool` ADD KEY `payment_id` (`payment_id`);
ALTER TABLE `payments_pool` DROP KEY `date`;
ALTER TABLE `payments_pool` DROP KEY `ext_id`;
ALTER TABLE `payments_pool` DROP KEY `uid`;

ALTER TABLE `payments` ADD KEY `aid` (`aid`);
ALTER TABLE `payments` ADD KEY `date` (`date`);
ALTER TABLE `payments` ADD KEY `ext_id` (`ext_id`);
ALTER TABLE `payments` ADD KEY `uid` (`uid`);

ALTER TABLE `paysys_groups_settings` ADD KEY `paysys_id` (`paysys_id`);

ALTER TABLE `ping_actions` ADD KEY `uid` (`uid`);

ALTER TABLE `portal_articles` ADD KEY `fk_portal_content_portal_menu` (`portal_menu_id`);

ALTER TABLE `push_contacts` ADD KEY `aid` (`aid`);
ALTER TABLE `push_contacts` ADD KEY `uid` (`uid`);

ALTER TABLE `referral_log` ADD KEY referral_request (`referral_request`);
ALTER TABLE `referral_log` ADD KEY uid (`uid`);

ALTER TABLE `referral_main` ADD KEY uid (`uid`);

ALTER TABLE `referral_requests` ADD KEY referral_uid (`referral_uid`);

ALTER TABLE `s_detail` ADD KEY `sid` (`acct_session_id`);
ALTER TABLE `s_detail` ADD KEY `uid` (`uid`);

ALTER TABLE `sharing_log` ADD KEY `username` (`username`);

ALTER TABLE `sharing_main` ADD KEY `uid` (`uid`);

ALTER TABLE `sharing_priority` ADD KEY `file` (`file`);

ALTER TABLE `shedule` ADD KEY `aid` (`aid`);
ALTER TABLE `shedule` ADD KEY `date_type_uid` (`date`, `type`, `uid`);
ALTER TABLE `shedule` ADD KEY `uid` (`uid`);
ALTER TABLE `shedule` DROP KEY `uniq_action`;

ALTER TABLE `snmputils_binding` ADD KEY `uid` (`uid`);

ALTER TABLE `sqlcmd_history` ADD KEY `aid` (`aid`);

ALTER TABLE `storage_accountability` ADD KEY `id` (`id`);
ALTER TABLE `storage_accountability` ADD KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`);

ALTER TABLE `storage_articles` ADD KEY `article_type` (`article_type`);

ALTER TABLE `storage_discard` ADD KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`);

ALTER TABLE `storage_incoming_articles` ADD KEY `article_id` (`article_id`);
ALTER TABLE `storage_incoming_articles` ADD KEY `sn` (`sn`);
ALTER TABLE `storage_incoming_articles` ADD KEY `storage_incoming_id` (`storage_incoming_id`);

ALTER TABLE `storage_incoming` ADD KEY `supplier_id` (`supplier_id`);

ALTER TABLE `storage_inner_use` ADD KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`);
ALTER TABLE `storage_inner_use` KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`);

ALTER TABLE `storage_installation` ADD KEY `aid` (`aid`);
ALTER TABLE `storage_installation` ADD KEY `installed_aid` (`installed_aid`);
ALTER TABLE `storage_installation` ADD KEY `location_id` (`location_id`);
ALTER TABLE `storage_installation` ADD KEY `mac` (`mac`);
ALTER TABLE `storage_installation` ADD KEY `nas_id` (`nas_id`);
ALTER TABLE `storage_installation` ADD KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`);
ALTER TABLE `storage_installation` ADD KEY `uid` (`uid`);

ALTER TABLE `storage_invoices_payments` ADD KEY `invoice_id` (`invoice_id`);

ALTER TABLE `storage_reserve` ADD KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`);

ALTER TABLE `storage_sn` ADD KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`);
ALTER TABLE `storage_sn` ADD KEY `storage_installation_id` (`storage_installation_id`);

ALTER TABLE `streets` ADD KEY `district_id` (`district_id`);

ALTER TABLE `tags_responsible` ADD KEY `aid` (`aid`);

ALTER TABLE `tarif_plans` ADD KEY `name` (`name`, `domain_id`);

ALTER TABLE `tp_geolocation` ADD KEY `build_id` (`build_id`);
ALTER TABLE `tp_geolocation` ADD KEY `district_id` (`district_id`);
ALTER TABLE `tp_geolocation` ADD KEY `street_id` (`street_id`);
ALTER TABLE `tp_geolocation` ADD KEY `tp_gid` (`tp_gid`);

ALTER TABLE `tp_groups_users_groups` ADD KEY `gid` (`gid`);
ALTER TABLE `tp_groups_users_groups` ADD KEY `tp_gid` (`tp_gid`);

ALTER TABLE `tp_nas` ADD KEY `tp_id` (`tp_id`);

ALTER TABLE `traffic_prepaid_sum` ADD KEY `uid` (`uid`, `started`, `traffic_class`);

ALTER TABLE `trafic_tarifs` ADD KEY `interval_id` (`interval_id`);

ALTER TABLE `turbo_mode` ADD KEY `uid` (`uid`, `start`);

ALTER TABLE `ureports_log` ADD KEY `uid` (`uid`);

ALTER TABLE `ureports_main` ADD KEY `tp_id` (`tp_id`);

ALTER TABLE `ureports_spool` ADD KEY `uid` (`uid`);

ALTER TABLE `ureports_tp_reports` ADD KEY `tp_id` (`tp_id`, `report_id`);

ALTER TABLE `ureports_tp` ADD KEY `tp_id` (`tp_id`);

ALTER TABLE `ureports_user_send_types` ADD KEY (`type`);
ALTER TABLE `ureports_user_send_types` ADD KEY (`uid`);

ALTER TABLE `users_bruteforce` ADD KEY `login` (`login`);

ALTER TABLE `users_contracts` ADD KEY `uid` (`uid`);

ALTER TABLE `users_development` ADD KEY `date` (`date`);
ALTER TABLE `users_development` ADD KEY `uid` (`uid`);

ALTER TABLE `users_nas` ADD KEY `uid` (`uid`);

ALTER TABLE `users_pi` ADD KEY `location_id` (`location_id`);

ALTER TABLE `users` ADD KEY `bill_id` (`bill_id`);
ALTER TABLE `users` ADD KEY `company_id` (`company_id`);
ALTER TABLE `users` ADD KEY `deleted` (`deleted`);
ALTER TABLE `users` ADD KEY `gid` (`gid`);
ALTER TABLE `users` ADD KEY `login` (`id`);

ALTER TABLE `voip_calls` ADD KEY `tp_id` (`tp_id`);
ALTER TABLE `voip_calls` ADD KEY `uid` (`uid`);

ALTER TABLE `voip_log` ADD KEY `uid` (`uid`);

ALTER TABLE `voip_main` ADD KEY `tp_id` (`tp_id`);
ALTER TABLE `voip_main` ADD KEY `uid` (`uid`);

ALTER TABLE `voip_phone_aliases` ADD KEY `uid` (`uid`);

ALTER TABLE `web_online` ADD KEY (`aid`);
