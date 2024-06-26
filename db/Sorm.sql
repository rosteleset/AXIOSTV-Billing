DROP TABLE IF EXISTS `SORM_ABONENT`;
DROP TABLE IF EXISTS `SORM_GATEWAY`;
DROP TABLE IF EXISTS `SORM_IP_PLAN`;
DROP TABLE IF EXISTS `SORM_PAYMENT`;
DROP TABLE IF EXISTS `SORM_SUPPLEMENTARY_SERVICE`;

ALTER TABLE `users_pi` DROP IF EXISTS `last_update`;
ALTER TABLE `users` DROP IF EXISTS `last_update` ;
ALTER TABLE `companies` DROP IF EXISTS `last_update` ;
ALTER TABLE `internet_main` DROP IF EXISTS `last_update` ;
ALTER TABLE `tarif_plans` DROP IF EXISTS `last_update` ;


--
-- Структура таблицы `SORM_ABONENT`
--

CREATE TABLE `SORM_ABONENT` (
  `ABONENT_ID` int(255) NOT NULL,
  `CONTRACT_DATE` date NOT NULL DEFAULT '0000-00-00',
  `CONTRACT` varchar(10) NOT NULL DEFAULT '',
  `ACCOUNT` varchar(10) NOT NULL DEFAULT '' COMMENT 'номер счёта',
  `ABONENT_TYPE` int(2) NOT NULL DEFAULT '42',
  `UNSTRUCT_NAME` varchar(255) NOT NULL DEFAULT '',
  `BIRTH_DATE` varchar(10) NOT NULL,
  `IDENT_CARD_TYPE_ID` int(2) DEFAULT '0',
  `IDENT_CARD_SERIAL` varchar(16) NOT NULL DEFAULT '',
  `IDENT_CARD_DESCRIPTION` varchar(300) NOT NULL DEFAULT '',
  `COMPANY_ID` int(10) NOT NULL,
  `BANK` varchar(512) NOT NULL DEFAULT '',
  `BANK_ACCOUNT` varchar(250) NOT NULL DEFAULT '',
  `FULL_NAME` varchar(128) NOT NULL DEFAULT '',
  `INN` varchar(64) NOT NULL DEFAULT '',
  `CONTACT` varchar(128) NOT NULL DEFAULT '',
  `PHONE_FAX` varchar(128) NOT NULL DEFAULT '',
  `STATUS` tinyint(1) NOT NULL DEFAULT '0',
  `NETWORK_TYPE` int(2) NOT NULL DEFAULT '4',
  `ACTUAL_FROM` timestamp NULL DEFAULT NULL,
  `ACTUAL_TO` timestamp NULL DEFAULT NULL,
  `ATTACH` timestamp NULL DEFAULT NULL,
  `DETACH` timestamp NULL DEFAULT NULL,
  `ZIP` varchar(7) NOT NULL DEFAULT '',
  `COUNTRY` varchar(21) NOT NULL DEFAULT '',
  `REGION` varchar(20) NOT NULL DEFAULT '',
  `ZONE` varchar(17) NOT NULL DEFAULT '',
  `CITY` varchar(20) NOT NULL DEFAULT '',
  `STREET` varchar(255) NOT NULL DEFAULT '',
  `BUILDING` varchar(10) NOT NULL DEFAULT '',
  `APARTMENT` varchar(10) NOT NULL DEFAULT '',
  `ABONENT_ADDR_BEGIN_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ABONENT_ADDR_END_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `PHONE` varchar(32) NOT NULL,
  `EQUIPMENT_TYPE` int(1) NOT NULL DEFAULT '0',
  `LOGIN` varchar(20) NOT NULL,
  `E_MAIL` varchar(255) NOT NULL,
  `IP_TYPE` int(11) NOT NULL DEFAULT '0',
  `IPV4` int(10) UNSIGNED NOT NULL,
  `IPV4_MASK` int(10) UNSIGNED NOT NULL DEFAULT '4294967294',
  `ABONENT_IDENT_BEGIN_TIME` timestamp NULL DEFAULT NULL,
  `ABONENT_IDENT_END_TIME` timestamp NULL DEFAULT NULL,
  `TP_ID` int(10) NOT NULL COMMENT 'ID услуги',
  `ABONENT_SRV_BEGIN_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ABONENT_SRV_END_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `PARAMETER` varchar(256) NOT NULL DEFAULT '',
  `users_pi_updated` timestamp NULL DEFAULT NULL,
  `users_updated` timestamp NULL DEFAULT NULL,
  `internet_main_updated` timestamp NULL DEFAULT NULL,
  `companies_updated` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- --------------------------------------------------------

--
-- Структура таблицы `SORM_GATEWAY`
--

CREATE TABLE `SORM_GATEWAY` (
  `record_id` int(255) NOT NULL,
  `GATE_ID` int(255) NOT NULL,
  `BEGIN_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `END_TIME` timestamp NOT NULL DEFAULT '2030-12-31 17:59:59',
  `DESCRIPTION` varchar(250) NOT NULL,
  `GATE_TYPE` int(1) NOT NULL DEFAULT '7',
  `ADDRESS_TYPE_ID` int(1) NOT NULL DEFAULT '0',
  `ZIP` int(6) NOT NULL DEFAULT '000000',
  `CITY` varchar(10) NOT NULL DEFAULT '',
  `STREET` varchar(40) NOT NULL DEFAULT '',
  `BUILDING` varchar(4) NOT NULL DEFAULT '',
  `APARTMENT` int(4) NOT NULL DEFAULT '0',
  `IP_TYPE` int(1) NOT NULL DEFAULT '0',
  `IPV4` varchar(15) DEFAULT NULL,
  `IP_PORT` varchar(25) NOT NULL,
  `DISABLE` int(1) NOT NULL DEFAULT '0',
  `ended` int(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Структура таблицы `SORM_IP_PLAN`
--

CREATE TABLE `SORM_IP_PLAN` (
  `id` int(255) NOT NULL,
  `DESCRIPTION` varchar(255) NOT NULL,
  `IP_TYPE` int(1) NOT NULL DEFAULT '0',
  `IPV4_START` varchar(15) NOT NULL,
  `IPV4_END` varchar(15) NOT NULL,
  `BEGIN_TIME` timestamp NOT NULL DEFAULT '2015-01-01 09:00:01',
  `END_TIME` timestamp NOT NULL DEFAULT '2030-12-31 20:59:59',
  `actual` int(11) NOT NULL DEFAULT '1',
  `reported` int(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Структура таблицы `SORM_PAYMENT`
--

CREATE TABLE `SORM_PAYMENT` (
  `PAYMENT_TYPE` int(2) NOT NULL DEFAULT '83',
  `PAY_TYPE_ID` int(4) NOT NULL,
  `PAYMENT_DATE` datetime NOT NULL,
  `AMOUNT` int(10) NOT NULL,
  `AMOUNT_CURRENCY` int(10) NOT NULL,
  `ABONENT_ID` int(10) NOT NULL COMMENT 'UID AXbills',
  `COUNTRY` varchar(20) DEFAULT NULL,
  `ZIP` int(6) NOT NULL,
  `REGION` varchar(20) DEFAULT NULL,
  `ZONE` varchar(20) DEFAULT NULL,
  `CITY` varchar(20) DEFAULT NULL,
  `STREET` varchar(20) DEFAULT NULL,
  `BUILDING` int(4) DEFAULT NULL,
  `APARTMENT` int(4) DEFAULT NULL,
  `axbills_id` int(11) NOT NULL,
  `PHONE` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Структура таблицы `SORM_SUPPLEMENTARY_SERVICE`
--

CREATE TABLE `SORM_SUPPLEMENTARY_SERVICE` (
  `record_id` int(255) NOT NULL,
  `ID` int(10) NOT NULL,
  `BEGIN_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `END_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `DESCRIPTION` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `SORM_GATEWAY`
--
ALTER TABLE `SORM_GATEWAY`
  ADD PRIMARY KEY (`record_id`);

--
-- Индексы таблицы `SORM_IP_PLAN`
--
ALTER TABLE `SORM_IP_PLAN`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `SORM_PAYMENT`
--
ALTER TABLE `SORM_PAYMENT`
  ADD PRIMARY KEY (`axbills_id`),
  ADD UNIQUE KEY `axbills_id` (`axbills_id`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `SORM_GATEWAY`
--
ALTER TABLE `SORM_GATEWAY`
  MODIFY `record_id` int(255) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT для таблицы `SORM_IP_PLAN`
--
ALTER TABLE `SORM_IP_PLAN`
  MODIFY `id` int(255) NOT NULL AUTO_INCREMENT;

ALTER TABLE `users_pi` ADD `last_update` DATETIME on update CURRENT_TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE `users` ADD `last_update` DATETIME on update CURRENT_TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE `companies` ADD `last_update` DATETIME on update CURRENT_TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE `internet_main` ADD `last_update` DATETIME on update CURRENT_TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE `tarif_plans` ADD `last_update` DATETIME on update CURRENT_TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
