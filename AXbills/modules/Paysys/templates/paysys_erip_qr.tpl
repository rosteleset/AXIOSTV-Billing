<div class='card card-primary card-outline form-horizontal'>
	<div class='card-header with-border text-center pb-0'>
		<h4>_{BALANCE_RECHARCHE}_ %LOGIN%</h4>
    </div>
  <div class='card-body'>
      <div class='alert alert-info' role='alert'>
        <div>
          <h6>Как пополнить счет через QR-код ЕРИП:</h6>
           Для оплаты через QR-код необходимо открыть приложения банка, выбрать "QR платеж (название может отличатся)", отсканировать данный QR-код и подтвердить платеж.
		   Так же можно отсканировать приложением "Камера" или любым сканером QR-кодов, далее перейти по ссылке, выбрать необходимый банк и подтвердить платеж.
        </div>
      </div>
	<div id="qr-container" class='card-body text-center'></div>
    <div class='card-body pt-0'>
      <ul class='list-group list-group-unbordered mb-3'>
        <li class='list-group-item'>
          <b>_{DESCRIBE}_</b>
          <div class='float-right'>$FORM{DESCRIBE}</div>
        </li>
        <li class='list-group-item'>
          <b>_{BALANCE_RECHARCHE_SUM}_</b>
          <div class='float-right'>%PAYMENT_AMOUNT% %PAYMENT_CURRENCY%</div>
        </li>
			<li class='list-group-item'>
          <b>_{LINK}_</b>
          <div class='float-right'><a href="%QR_URL%" target="_blank">_{PAY_WITHOUT_CAM}_<a></div>
        </li>
        %EXTRA_DESCRIPTIONS%
      </ul>
    </div>
  </div>
</div>
	<script src="/styles/default/js/qrcode.js"></script>
    <script>
        var qrcode = new QRCode({ content: "%QR_URL%", join: true });
        var svg = qrcode.svg();
        document.getElementById("qr-container").innerHTML = svg;
    </script>