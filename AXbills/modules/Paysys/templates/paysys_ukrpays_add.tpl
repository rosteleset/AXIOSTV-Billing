<div class='card card-primary card-outline'>
	<form id='ukrpays_form' method='post' accept-charset='utf-8' action='$conf{PAYSYS_UKRPAYS_URL}'>
		<input type='hidden' name='charset' value='UTF-8' />
		<input type='hidden' name='order' value='%UID%'>
		<input type='hidden' name='sus_url' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1&index=$index&PAYMENT_SYSTEM=46&OPERATION_ID=$FORM{OPERATION_ID}&TP_ID=$FORM{TP_ID}&DOMAIN_ID=$FORM{DOMAIN_ID}%SUS_URL_PARAMS%'>
		<input type='hidden' name='lang' value='uk'>
		<input type='hidden' name='fio' value='%FIO%'>
		<input type='hidden' name='note' value='Upays:$FORM{OPERATION_ID}'>
		<input type='hidden' name='service_id' value='$conf{PAYSYS_UKRPAYS_SERVICE_ID}'>
		<input type='hidden' name='amount' value='%AMOUNT%'>

		<div class='card-header with-border text-center pb-0'>
			<h4>_{BALANCE_RECHARCHE}_</h4>
		</div>
		<div class='card-body pt-0'>
			<div class='text-center'>
				<img src='/styles/default/img/paysys_logo/ukrpays-logo.png'
						 style='max-width: 300px; max-height: 200px;'
						 alt='UkrPays'>
			</div>

			<ul class='list-group list-group-unbordered mb-3'>
				<li class='list-group-item'>
					<b>_{DESCRIBE}_</b>
					<div class='float-right'>%DESC%</div>
				</li>
				<li class='list-group-item'>
					<b>_{ORDER}_</b>
					<div class='float-right'>$FORM{OPERATION_ID}</div>
				</li>
				<li class='list-group-item'>
					<b>_{BALANCE_RECHARCHE_SUM}_</b>
					<div class='float-right'>%AMOUNT%</div>
				</li>
				%EXTRA_DESCRIPTIONS%
			</ul>
			<input type='submit' class='btn btn-primary float-right' value='_{PAY}_'>
		</div>
	</form>
</div>
