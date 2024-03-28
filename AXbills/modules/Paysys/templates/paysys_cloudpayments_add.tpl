<script src="https://widget.cloudpayments.ru/bundles/cloudpayments"></script>

<div class='row text-center'>
  <input type='button' id='checkout' value='Открыть виджет для тестовой оплаты' class='btn btn-primary'>

</div>
<script type="text/javascript">
  window.pay = function () {
    var widget = new cp.CloudPayments();
    var amount = parseFloat('%SUM%');
    var accountId = 1;

    widget.charge({ // options
        publicId: '$conf{PAYSYS_CLOUDPAYMENTS_ID}', //id из личного кабинета
        description: 'Пополнение счета абонента ' + '%FIO%', //назначение
        amount: amount, //сумма
        currency: 'RUB', //валюта
        accountId: accountId, //идентификатор плательщика (обязательно для создания подписки)
        invoiceId: '%TRANSACTION%',
        onSuccess: '%SUCCESS_URL%',
        onFail: 'http://axbills.net.ua/wiki/doku.php/axbills:docs:modules:paysys:cloudpayments',
        data: ''
    });
};    

jQuery('#checkout').on('click',pay);
</script>