<html>

<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
</head>

<body>


  <style>
    h1 {
      font: bold 18px/1em Times;
      margin: 0;
    }

    h2 {
      font: bold 14px/1em Times;
      margin: 0;
    }

    .l {
      text-align: left;
    }

    .r {
      text-align: right;
    }

    .b {
      font-weight: bold;
    }

    .u {
      text-decoration: underline;
    }

    .i {
      font-style: italic;
    }

    p {
      text-align: justify;
      margin: 0;
    }

    .c {
      text-align: center !important;
    }

    .normal {
      font: 12px/1.1em Times;
    }

    .small {
      font: 10px/1.1em Times;
      margin-top: 5px;
    }

    .up {
      font-size: 0.7em;
      position: relative;
      top: -7px;
    }

    .abon_details {
      width: 100%;
    }

    .abon_details td {
      border-bottom: 1px solid #333;
      font: bold 12px/1.2em Arial;
    }


    .print_table {
      padding: 0;
      margin: 0;
      border-spacing: 0;
      width: 100%;
    }

    .print_table td {
      padding: 1px;
      margin: 0;
      font-size: 9pt;
      line-height: 9pt;
      font-family: 'Times New Roman';
      border-spacing: 0;
    }

    .print_table .abonent-data {
      font-size: 11pt;
      line-height: 11pt;
    }

    .print_table td.header {
      font-weight: bold;
      text-align: center;
      padding-top: 15px;
    }

    .print_table td.right {
      text-align: right;
    }

    .print_table td.center {
      text-align: center;
    }

    .print_table td.justify {
      text-align: justify;
    }

    .print_table td.vtop {
      vertical-align: top;
    }

    .print_table td.bottom {
      vertical-align: bottom;
    }

    .print_table td.pp {
      font-weight: bold;
      width: 21px;
      min-width: 21px;
      vertical-align: top;
    }

    .print_table td.ppp {
      width: 16px;
      min-width: 16px;
      vertical-align: top;
    }

    .small center {
      margin-top: 5px;
    }

    .qr {
      position: absolute;
      top: 1785px;
      left: 580px;
      text-align: center;
    }
/* 
    .qr img {
      width: 50%;
      height: 50%;
    } */

    .qr p {
      font-size: 10px;
      text-align: center;
    }
  </style>

  <h1 class="c">ДОГОВОР № <span class='b u'>%CONTRACT_ID%</span></h1>
  <h2 class="c">ОДО «Передовые технологии»</h2>
  <h2 class="c">Лицевой счёт для оплаты услуг %CONTRACT_ID%</h2>
  <table width='100%'>
    <tr>
      <td class='l b'>г. Витебск</td>
      <td class='r b u'>%CONTRACT_DATE_LIT%</td>
    </tr>
  </table>
  <br />

  <div class="small">
    <p>ОДО «Передовые технологии» (оператор услуг электросвязи, далее – <b>Оператор</b>) в лице его представителя
      Тишурова Дениса Валерьевича, действующего на основании Доверенности №1 от 04.01.2021 г., с одной стороны и:</p>
    <table class="print_table">
      <tr>
        <td colspan="2" class="justify"><span class="abonent-data"> <b>%FIO%</b></span>,</td>
      </tr>
      <tr>
        <td>Паспорт: № %PASPORT_NUM%, выдал %PASPORT_GRANT% в %PASPORT_DATE_EURO%</td>
      </tr>
      <tr>
        <td>Личный номер: %TAX_NUMBER%</td>
      </tr>
      <tr>
        <td>Дата рождения: %BIRTH_DATE% </td>
      </tr>
      <tr>
        <td>Зарегистрирован(на) по адресу: %REG_ADDRESS%</td>
      </tr>
      <tr>
        <td><b>Адрес подключения услуги: г. Витебск, %ADDRESS_FULL%</b></td>
      </tr>
      <tr>
        <td>Домашний телефон: %PHONE%</td>
      </tr>
      <tr>
        <td>Мобильный телефон: %CELL_PHONE%</td>
      </tr>
      <tr>
        <td>
          с другой стороны (далее <b>Абонент</b>), вместе далее именуемые <b>Стороны</b>, заключили настоящий Договор о
          нижеследующем:</td>
      </tr>
    </table>
    <div class="small">
      <center class="b">1. ПРЕДМЕТ ДОГОВОРА И УСЛОВИЯ ПОДКЛЮЧЕНИЯ</center>

      <p>1.1 Настоящий Договор заключается в соответствии с Правилами оказания услуг электросвязи, утвержденными
        постановлением СМ РБ от 17.08.2006г №1055, в редакции постановления СМ РБ от 26.09.2022 г. №645 (далее -
        Правила), с использованием сети электросвязи Оператора. Оператор, действующий на основании лицензии Министерства
        связи и информатизации Республики Беларусь №02140/698 от 30 апреля 2004 года, предоставляет Абоненту услугу сети
        передачи данных (далее - Услуга).</p>
      <p>1.2 Услуга предоставляется исходя из технической возможности Оператора по проводной или беспроводной технологии
        передачи данных в соответствии с Прейскурантом на услуги связи Оператора (далее Прейскурант).</p>
      <p>1.3 По заявке Абонента Оператор выполняет работы по прокладке кабеля, установке оборудования (адаптер, роутер
        или др.), настройке соединений, демонстрации работоспособности, а также проводит инструктаж по правилам
        эксплуатации Услуги (далее — Работы по подключению).</p>
      <p>1.4 Для подключения Услуги обязательно наличие у Абонента устройства (компьютера или др.) с установленной и
        работоспособной операционной системой, и программным обеспечением. При этом ответственность за работоспособность
        и соблюдение лицензионных условий операционной системы и других программ несет Абонент.</p>
      <p>1.5 Работы по подключению Абонента выполняются Оператором на безвозмездной основе. При подключении составляется
        Акт приема-передачи имущества в безвозмездное пользование на время действия настоящего Договора, который
        подписывается Сторонами и является неотъемлемой частью Договора (Приложение 1 к Договору).</p>


      <center class="b">2. ПОРЯДОК И КАЧЕСТВО ПРЕДОСТАВЛЕНИЯ УСЛУГИ</center>

      <p>2.1 Услуга передачи данных, а также дополнительные услуги предоставляются в соответствии с утвержденным
        Тарифным планом Оператора (далее — <b>Тарифный план или Тариф</b>), выбранным Абонентом Тарифом и набором услуг.
        Учет объема предоставленных Абоненту Услуг ведется Оператором.</p>
      <p>2.2 Смена Тарифа, а также подключение и отключение дополнительных Услуг производятся по письменному заявлению,
        либо в личном кабинете Абонента в соответствии с Тарифным планом Оператора.</p>
      <p>2.3 При наличии задолженности у Абонента Оператор без предварительного уведомления блокирует доступ к ресурсам
        сети Интернет, при этом Абонент может пользоваться другими доступными Услугами (ресурсами) и оплачивает
        абонентскую плату в соответствии с выбранным Тарифом. При погашении задолженности перед Оператором Абоненту
        восстанавливается доступ к сети Интернет.</p>
      <p>2.4 В случае, если задолженность Абонента составляет более одного календарного месяца, Оператор блокирует
        доступ к Услуге; абонентская плата далее не начисляется. На момент блокировки Абоненту доступа к Услуге его
        задолженность перед Оператором составляет стоимость тарифного плана за 1 месяц. Для продолжения пользования
        Услугой Абоненту необходимо погасить образовавшуюся задолженность, а также уведомить об этом Оператора.</p>
      <p>2.5 Скорость передачи данных и качественные характеристики Услуги определяются выбранным Тарифным планом,
        текущей загрузкой сети передачи данных и запрашиваемых удаленных серверов, а также быстродействием оборудования
        Абонента (компьютер или др., роутер, сетевой адаптер).</p>
      <p>2.6 Параметры качества Услуг передачи данных, показатели качества работы сети и качества обслуживания абонентов
        сети Оператора должны соответствовать Правилам оказания услуг электросвязи (постановление СМ № 1055 от
        17.08.2006 года) не ниже установленных значений. Абонент самостоятельно контролирует качество предоставленных
        ему Услуг.</p>

      <center class="b">3. ПРАВА И ОБЯЗАННОСТИ АБОНЕНТА</center>

      <p><b>3.1 Абонент имеет право:</b></p>
      <p>3.1.1 Пользоваться Услугами, в том числе и дополнительными, предоставленным в пользование оборудованием (Wi-Fi
        маршрутизатором, усилителем Wi-Fi сигнала, беспроводным USB Wi-Fi адаптером и др. - далее Имущество) в
        соответствии с Тарифами, правилами и условиями пользования (см. сайт Оператора).</p>
      <p>3.1.2 Получать техническую и консультационную поддержку по вопросам оказания Услуг.</p>
      <p>3.1.3 На добровольное приостановление Услуг в соответствии с Тарифами Оператора на срок не более 62-х дней в
        течение календарного года.</p>
      <p>3.1.4 По письменному обращению расторгнуть настоящий Договор, письменно уведомив об этом Оператора и исполнив
        свои обязательства в соответствии с п.п. 3.2.4 и 3.2.5 настоящего Договора.</p>
      <p><b>3.2 Абонент обязан:</b></p>
      <p>3.2.1 Обеспечить беспрепятственный доступ технического персонала Оператора в помещение, где проводятся Работы
        по подключению или обслуживанию оборудования, самостоятельно согласовать с собственником жилого помещения факт
        выполнения Работ.</p>
      <p>3.2.2 Быть ознакомленным с Правилами оказания услуг электросвязи и с условиями пользования Имуществом (см. сайт
        Оператора).</p>
      <p>3.2.3 Своевременно и в полном объеме осуществлять оплату платежей, согласно выбранному Тарифу, набору
        дополнительных Услуг, а также за пользование Имуществом, контролировать состояние счета в «личном кабинете»
        Абонента, своевременно вносить предоплату для пополнения счета.</p>
      <p>3.2.4 В день расторжения настоящего Договора по соглашению Сторон или по инициативе любой из Сторон оплатить
        текущую задолженность (при ее наличии), вернуть в технически исправном и пригодном к дальнейшей эксплуатации
        полученное в пользование Имущество в полной комплектации (приложение 1 к настоящему Договору), либо в тот же
        срок возместить его стоимость.</p>
      <p>3.2.5 При расторжении настоящего Договора по инициативе любой из Сторон ранее 12 месяцев с даты начала
        пользования Услугой (далее активация), дополнительно оплатить Оператору неустойку в размере одной базовой
        величины, действующей на дату оплаты. </p>
      <p>3.2.6 Оплатить Оператору неустойку в размере одной базовой величины в случае, если Услуга не будет активирована
        по вине Абонента в течение 12 месяцев с даты подписания Акта приема-передачи имущества.</p>
      <p>3.2.7 Не осуществлять несанкционированного изменения существующей абонентской сети, не производить действий,
        которые могут повлечь за собой нарушения функционирования сетей электросвязи или помешать работе других
        пользователей, не допускать использования сети электросвязи для передачи информации, запрещенной к
        распространению законодательством Республики Беларусь, соблюдать Закон об электросвязи Республики Беларусь.</p>
      <p>3.2.8 Сохранять конфиденциальность персональных данных (логин, пароль), своевременно менять пароль доступа к
        получению Пакета услуг.</p>
      <p>3.2.9 Самостоятельно подать заявку по тел. +375-29-5-101-149 либо 603-233 в случаях низкого качества услуг,
        возникновения неисправностей, отсутствия связи в сети Оператора с указанием конкретной проблемы или
        неисправности (ошибки и т.п.).</p>
      <p>3.2.10 В течение 10 (десяти) календарных дней информировать Оператора об изменениях фамилии, собственного
        имени, отчества, места жительства, контактных телефонов и других данных необходимых для исполнения Договора.</p>

      <center class="b">4. ПРАВА И ОБЯЗАННОСТИ ОПЕРАТОРА</center>

      <p><b>4.1 Оператор имеет право:</b></p>
      <p>4.1.1 Проводить ремонтные и профилактические работы для нормального функционирования сети с временным или
        полным выключением Услуг.</p>
      <p>4.1.2 Временно приостанавливать доступ к ресурсам сети при наличии задолженности у Абонента, а также при
        невыполнении Абонентом обязанностей, указанных в п. 3.2 настоящего Договора.</p>
      <p>4.1.3 В одностороннем порядке расторгнуть настоящий Договор при неисполнении или ненадлежащем исполнении
        Абонентом обязанностей, указанных в п.п. 3.2.7 настоящего Договора или попытке несанкционированного доступа
        Абонентом к ресурсам сети Интернет и (или) к оборудованию Оператора, поступлении письменного заявления от
        собственника жилого помещения.</p>
      <p>4.1.4 В одностороннем порядке без получения согласия Абонента изменять действующие Тарифы, предварительно
        информируя об этом на своем сайте. В случае несогласия с изменением Тарифов Абонент имеет право расторгнуть
        настоящий Договор с соблюдением требований настоящего Договора.</p>
      <p><b>4.2 Оператор обязуется:</b></p>
      <p>4.2.1 Произвести работы по подключению и активации Услуг при соблюдении условий раздела 1 настоящего Договора.
        Активация Услуги производится в течение 24-х часов после выполнения подключения Абонента.</p>
      <p>4.2.2 Производить замену Имущества в случае его неисправности при условии обеспечения сохранности Имущества и
        отсутствии повреждений.</p>
      <p>4.2.3 Обеспечить Абонентам качество оказываемых услуг в соответствии с требованиями Правил оказания услуг
        электросвязи и настоящим Договором.</p>
      <p>4.2.4 Проводить техническую, информационную и консультационную поддержку Абонента по вопросам оказания Услуг по
        телефону и на сайте Оператора. Своевременно информировать Абонентов о профилактических работах, об отключаемых
        районах или Услугах, а также о крупных авариях, принятых мерах и сроках устранения. Информация размещается на
        сайте Оператора.</p>

      <center class="b">5. СТОИМОСТЬ УСЛУГ И ПОРЯДОК РАСЧЕТОВ</center>

      <p>5.1 Стоимость Услуг устанавливается в соответствии с Тарифами Оператора. Тарифы определяются Оператором
        самостоятельно в соответствии с действующим законодательством Республики Беларусь. Подписание Договора Абонентом
        подтверждает факт ознакомления и согласия с Тарифами Оператора, а также с процедурами их изменения. Абонент
        может ознакомиться с информацией о действующих Тарифных планах по телефонам и на сайте Оператора.</p>
      <p>5.2 Абонентская плата списывается со счета Абонента с момента активации Услуги, независимо от пользования
        ежедневно в 00:00 часов равными долями в зависимости от количества дней в месяце (абонплата/кол-во дней в
        месяце). Плата за дополнительные Услуги списывается в соответствии с условиями оказания этих услуг. Размер
        месячной абонентской платы зависит от суммы выбранного Тарифного плана.</p>
      <p>5.3 Внесение средств на счет Абонента может производиться непосредственно по месту расположения Оператора, в
        учреждениях банков, инфокиосках, в отделениях Белпочты или другими доступными способами. </p>

      <center class="b">6. ОТВЕТСТВЕННОСТЬ СТОРОН </center>

      <p> 6.1 Оператор и Абонент несут ответственность за невыполнение или ненадлежащее выполнение возложенных на них
        обязательств в соответствии с действующим законодательством Республики Беларусь.</p>
      <p> 6.2 В случае порчи, неисправности или повреждения Имущества, произошедших по вине Абонента, последний обязан
        оплатить Оператору стоимость восстановительного ремонта Имущества, указанного в Акте приема-передачи на
        основании Акта о выявленных дефектах. При повреждении Имущества, когда его восстановление и использование по
        назначению невозможно, либо утрате Имущества, Абонент обязан оплатить Оператору стоимость Имущества согласно
        Акту приема-передачи Имущества.</p>
      <p> 6.3 В случае несвоевременной передачи Оператору Имущества в соответствии с пунктом 3.2.4 настоящего Договора,
        Абонент уплачивает пеню в размере 3% базовой величины за каждый день просрочки. Размер базовой величины
        определяется на день совершения платежа. </p>
      <p> 6.4 Настоящий Договор действует до полного исполнения Сторонами своих обязательств. </p>
      <p> 6.5 Оператор не несет ответственности и не возмещает убытки, возникшие по причине несанкционированного
        использования пароля Абонента и доступа к Услуге от имени Абонента третьими лицами; не несет ответственности за
        достоверность и целостность информации и программ, полученных Абонентом с использованием Услуги, за прямой или
        косвенный ущерб, причиненный Абоненту и (или) любым третьим лицам в результате пользования Услугой или
        невозможности ее использования, а также по искам Абонентов или третьих лиц за упущенную выгоду, потерю клиентов,
        репутации и т. д.</p>
      <p> 6.6 Оператор не несет ответственности за частичную или полную неработоспособность абонентского оборудования
        или ПО, неправильную их настройку; за доступ в сеть передачи данных (включая сеть Интернет) программ и устройств
        Абонента без его ведома.</p>
      <p> 6.7 Оператор несет ответственность за предоставление Услуг надлежащего качества в сегменте сети Оператора.
        Устранение неисправностей в сегменте сети Оператора — 48 часов с момента поступления информации или заявки
        Абонента. В случае нарушения срока устранения неисправностей Оператор по письменному заявлению Абонента
        возвращает на лицевой счет Абонента снятую абонентскую плату за весь срок неисправности (сбоя), при этом начало
        срока неисправности исчисляется с момента подачи заявки Абонентом, а заканчивается моментом устранения
        неисправности.</p>
      <p> 6.8 Стороны освобождаются от ответственности за полное или частичное неисполнение своих обязательств по
        настоящему Договору, если таковое явилось следствием обстоятельств непреодолимой силы, возникших после
        вступления в силу настоящего Договора.</p>
      <p> К обстоятельствам непреодолимой силы относится также принятие государственными органами актов, препятствующих
        надлежащему исполнению сторонами своих обязательств по настоящему Договору.</p>

      <center class="b">7. СРОК ДЕЙСТВИЯ ДОГОВОРА И УСЛОВИЯ РАСТОРЖЕНИЯ ДОГОВОРА</center>

      <p> 7.1 Настоящий Договор заключен на неопределенный срок и вступает в силу с даты его подписания; при этом ранее
        действующие Договор(ы) на услуги Оператора считается расторгнутым по соглашению сторон с момента подписания
        настоящего Договора.</p>
      <p> 7.2 Настоящий Договор может быть расторгнут по соглашению сторон либо по требованию одной из сторон с
        уведомлением об этом письменно.</p>
      <p> 7.3 Договор может быть расторгнут по инициативе Оператора в одностороннем порядке без обращения в суд в
        случае, если задолженность по оплате составляет более двух месяцев. При этом Абоненту высылается письменное
        уведомление о расторжении Договора или текстовое сообщение на номер мобильного телефона Абонента, указанный в
        Договоре.</p>
      <p> 7.4 При расторжении Договора Абонент обязуется полностью выполнить свои обязательства по настоящему Договору в
        течение 5 рабочих дней с момента получения уведомления.</p>

      <center class="b">8. РАССМОТРЕНИЕ СПОРОВ</center>

      <p> 8.1 Все споры и разногласия, возникающие при исполнении настоящего Договора, разрешаются путем переговоров,
        письменных или устных.</p>
      <p> 8.2 В случае если стороны не достигнут согласия по спорным вопросам путем переговоров, указанные вопросы
        подлежат рассмотрению в порядке, установленном законодательством Республики Беларусь. В случаях, предусмотренных
        законодательством, взыскатель вправе обратиться к нотариусу для совершения исполнительной надписи.</p>
      <p> 8.3 Настоящий Договор составлен в двух экземплярах, имеющих одинаковую юридическую силу, один из которых
        хранится в ОДО "Передовые технологии", другой - у Абонента.</p>

      <center><b>9. ТАРИФНЫЙ ПЛАН АБОНЕНТА И ПЕРСОНАЛЬНЫЕ ДАННЫЕ</b> (информация, не подлежащая разглашению):</center>

      <style>
        .param_table {
          width: 100%;
          margin-top: 10px;
        }

        .param_table td {
          text-align: center;
          font: 10px/1em Times;
        }
      </style>

      <table class="param_table" cellspacing="0" border=1>
        <tr>
          <td>Первоначальный тарифный план:</td>
          <td></td>
          <!--      <td></td>  -->
          <td colspan="2">Личный кабинет (https://my.ptech.by)</td>
        </tr>
        <tr>
          <td>Имя пользователя:</td>
          <td>%LOGIN%</td>
          <!--        <td>%LOGIN%nt1</td> -->
          <td>%LOGIN%</td>
        </tr>
        <tr>
          <td>Первоначальный пароль:</td>
          <td>%PASSWORD%</td>
          <!--        <td>%PASSWORD%</td> -->
          <td>%PASSWORD%</td>
        </tr>
        <tr>
          <td>Порт подключения и mac адрес:</td>
          <td colspan="4"></td>
        </tr>
      </table>

      <center class="b">10. ЮРИДИЧЕСКИЕ АДРЕС И РЕКВИЗИТЫ</center>

      <div style="margin: 10px 20px;" class="normal">

        <p><b>ОДО «Передовые технологии» УНП 390150916 ОКПО 29143039</b></p>
        <p><b>р/с</b> BY77SLAN30122245600240000000 ЗАО БАНК ВТБ (Беларусь) БИК SLANBY22</p>
        <p><b>Юридический адрес:</b> 210015 г. Витебск, пр-т Строителей, д.2</p>
        <p><b>Для корреспонденции:</b> 210015 г. Витебск, пр-т Строителей, д.2</p>
        <p><b>Офис:</b> 210015 г. Витебск, пр-т Строителей, д.2</p>
        <p><b>Наш сайт:</b>ptech.by | vk.com/ptechby <b>Личный кабинет:</b> my.ptech.by</p>
        <p><b>Консультация абонентов по телефону:</b> 8 0212 603-233, +375-29-510-11-49 (круглосуточно без выходных)</p>
        <div class="qr"  >        
          <p>QR-код для оплаты услуг:</p>
          <div id="qr-container" >
              <!-- <img src="https://support.ptech.by/files/qr.png" alt="QR-код для оплаты услуг"> -->
          </div>
      </div>

        <br /><br /><br />

        <table width='100%'>
          <tr>
            <td>______________ / Тишуров Д.В. /</td>
            <td> Абонент ______________ /_________________ /</td>
          </tr>
          <tr>
            <td>&nbsp;&nbsp;&nbsp;&nbsp;<span class="up">М.П.&nbsp;&nbsp;подпись</span></td>
            <td>
              &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span
                class="up">подпись</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span
                class="up">ФИО:</span></td>
          </tr>
        </table>
      </div>

</body>
<script src="/styles/default/js/qrcode.js"></script>
<script>
    var qrcode = new QRCode({ content: "%QR_URL%", 
    join: true,
    width: 110,
    height: 110 });

    var svg = qrcode.svg();
    document.getElementById("qr-container").innerHTML = svg;
</script>

</html> 