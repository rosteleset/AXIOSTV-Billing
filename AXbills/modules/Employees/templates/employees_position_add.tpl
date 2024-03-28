<form action=$SELF_URL METHOD=POST class='form-horizontal'>
	<input type='hidden' name='index' value='$index'>
	<input type='hidden' name='action' value='%ACTION%'>
	<input type='hidden' name='id' value=%ID%>

	<div class='card card-primary card-outline container-md'>

		<div class='card-header with-border'>_{ADD_POSITION}_</div>
		<div class='card-body'>

			<div class='form-group row'>
				<label class='col-md-4 col-form-label text-md-right'>_{POSITION}_:</label>
				<div class='col-md-8'>
					<input type='text' class='form-control' name='POSITION' value='%POSITION%'>
				</div>
			</div>

			<div class='form-group row'>
				<label class='col-md-4 col-form-label text-md-right'>_{SUBORDINATION}_:</label>
				<div class='col-md-8'>
					%SUBORDINATION%
				</div>
			</div>

			<div class='form-group row'>
				<label class='col-md-4 col-form-label text-md-right'>_{OPEN_VACANCY}_:</label>
				<div class='col-md-8'>
					<input name='VACANCY' %check% value='1'  type='checkbox'>
				</div>
			</div>
		</div>
		<div class='card-footer'>
			<input type='submit' class='btn btn-primary' name='BUTTON' value='%BUTTON_NAME%'>
		</div>

	</div>

	%POSITION_TABLE%

</form>