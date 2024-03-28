CREATE TABLE IF NOT EXISTS `equipment_calculator`(
    `type` VARCHAR(20) NOT NULL DEFAULT '',
    `name` VARCHAR(20) NOT NULL  DEFAULT '',
    `value` VARCHAR(255) NOT NULL  DEFAULT ''
)
  DEFAULT CHARSET=utf8 COMMENT = 'Equipment calculator';

INSERT INTO equipment_calculator (type, name, value) VALUES
('olt', 'SFP B+', '1.5'),
('olt', 'SFP', '0'),
('olt', 'SFP C+', '3'),
('olt', 'SFP C++', '5'),
('divider', '1/4', '7.4'),
('divider', '1/8', '10.7'),
('splitter', '40/60', '4.01;2.34'),
('splitter', '10/90', '10.2;0.6'),
('splitter', '85/15', '0.76;8.16'),
('splitter', '70/30', '1.56;5.39'),
('splitter', '95/5', '0.32;13.7'),
('splitter', '75/25', '1.42;6.29'),
('splitter', '5/95', '13.7;0.32'),
('splitter', '45/55', '2.71;3.73'),
('splitter', '80/20', '1.6;7.11'),
('splitter', '15/85', '8.16;0.76'),
('splitter', '60/40', '2.34;4.01'),
('splitter', '30/70', '5.39;1.56'),
('splitter', '65/35', '1.93;4.56'),
('splitter', '90/10', '0.6;10.2'),
('splitter', '50/50', '3.17;3.19'),
('splitter', '25/75', '6.29;1.42'),
('splitter', '35/65', '4.56;1.93'),
('splitter', '20/80', '7.11;1.6'),
('splitter', '55/45', '3.73;2.71'),
('connector', 'SIGNAL_LOSS', '0');

ALTER TABLE telegram_tmp ADD `aid` INT(11) UNSIGNED DEFAULT '0' NOT NULL;
ALTER TABLE telegram_tmp
  MODIFY COLUMN `aid` INT(11) UNSIGNED NOT NULL DEFAULT '0' AFTER uid;