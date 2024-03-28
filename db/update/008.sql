ALTER TABLE `builds`
  ADD COLUMN `zip` VARCHAR(7) NOT NULL DEFAULT '';
ALTER TABLE `districts`
  ADD COLUMN `domain_id` SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `msgs_unreg_requests`
  ADD `last_contact` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `msgs_unreg_requests`
  ADD `planned_contact` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `msgs_unreg_requests`
  ADD `contact_note` TEXT NOT NULL;
