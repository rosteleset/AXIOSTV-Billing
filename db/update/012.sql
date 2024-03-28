ALTER TABLE `fees` ADD COLUMN `reg_date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP;
RENAME TABLE voip_ivr_log TO callcenter_ivr_log;
RENAME TABLE voip_ivr_menu TO callcenter_ivr_menu;


