ALTER TABLE `extreceipts_kkt`   ADD COLUMN     `check_header`   varchar(60)  NOT NULL DEFAULT '';
ALTER TABLE `extreceipts_kkt`   ADD COLUMN     `check_desc`     varchar(60)  NOT NULL DEFAULT '';
ALTER TABLE `extreceipts_kkt`   ADD COLUMN     `check_footer`   varchar(60)  NOT NULL DEFAULT '';
ALTER TABLE `extreceipts_api`   MODIFY COLUMN  `password`       BLOB         NOT NULL;
ALTER TABLE `msgs_attachments`  ADD COLUMN  `delivery_id`  SMALLINT(11) UNSIGNED NOT NULL  DEFAULT '0';