ALTER TABLE `extreceipts_kkt`   ADD COLUMN      `kkt_key`     varchar(30)  NOT NULL DEFAULT '';
ALTER TABLE `extreceipts_kkt`   ADD COLUMN      `shift_uuid`  varchar(36)  NOT NULL DEFAULT '';
ALTER TABLE `extreceipts_kkt`   MODIFY COLUMN   `aid`         varchar(60)  NOT NULL DEFAULT '';