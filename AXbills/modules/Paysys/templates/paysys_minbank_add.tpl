<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<input type='hidden' name='MerchantId' value='%merchantid%'>
<input type='hidden' name='OrderID' value='%OrderId%'>
<input type='hidden' name='Version' value='1.0'>
<input type='hidden' name='Amount' value='%sum%'>
<input type='hidden' name='Currency' value='643'>
<input type='hidden' name='Description' value='%desc%'>
<input type='hidden' name='UrlApprove' value='%returnurl%'>
<input type='hidden' name='UrlDecline' value='%returnurl%'>
<input type='hidden' name='CustId' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='ServerURL' value='%form_url%'>
<input type='hidden' name='sid' value='%sid%'>
<input type='hidden' name='minbank_action' value='1'>
<link rel='stylesheet' type='text/css' href='https://gate.minbank.ru/api-client/template.css' />

<div class='card box-primary'>
    <div class='card-header with-border text-center'>Московский Индустриальный Банк</div>

<div class='card-body text-center'>
<div class='alert alert-info'>Вы собираетесь оплатить лицевой счет %account% на сумму %amount%.
<strong><br>Введите данные для продолжения оплаты.</strong></div>
  <div class='mb-gate-template' data-id='%MB_ID%'>
    <form class='mb-gate-template__form'>
      <input type='hidden' name='account' value='%account%' />
      <input type='hidden' name='amount' value='%amount%' />
      <div class='mb-gate-template__gateway'></div>
      <div class='mb-gate-template__email-n-submit'></div>
      <div class='mb-gate-template__locker'></div>
    </form>
  </div>
  <script src='https://gate.minbank.ru/api-client/lib.min.js' data-mb-merchant='%MB_MERCHANT%'></script>

</div>

</div>