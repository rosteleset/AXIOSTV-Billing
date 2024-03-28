<form method='post' class='form'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='poll'  value='$FORM{poll}'>
<input type='hidden' name='UID'   value='%UID%'>
<input type='hidden' name='RESULT' value='1'>

	<div class='card card-%PANEL_COLOR%'>
		<div class='card-header with-border'>
			<h3>%SUBJECT%</h3>
		</div>
		<div class='card-body'>
			<div class='form-group'>
				<h4>%DESCRIPTION%</h4>
			</div>
			<div class='form-group'>
				%ANSWERS%
			</div>
		</div>
		<div class='card-footer'>
			%BUTTONS%
		</div>
	</div>
</form>