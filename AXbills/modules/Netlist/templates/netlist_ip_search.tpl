<div class='d-print-none'>
<FORM action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>


<div class='card card-primary card-outline box-form'>
<div class='card-header with-border text-center'>_{SEARCH}_</div>

<div class='card-body form-horizontal'>
	<div class='form-group'>
		<label class='col-md-3 control-label'>IP:</label>
		<div class='col-md-9'><input class='form-control' type='text' name='IP' value='%IP%'></div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>NETMASK:</label>
		<div class='col-md-9'><input class='form-control' type='text' name='NETMASK' value='%NETMASK%'></div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>HOSTNAME:</label>
		<div class='col-md-9'><input class='form-control' type='text' name='HOSTNAME' value='%HOSTNAME%'></div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>_{DESCRIBE}_:</label>
		<div class='col-md-9'><input class='form-control' type='text' name='DESCR' value='%DESC%'></div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>Netlist _{GROUP}_:</label>
		<div class='col-md-9'>%GROUP_SEL%</div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>_{STATE}_:</label>
		<div class='col-md-9'>%STATE_SEL%</div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>_{PHONE}_:</label>
		<div class='col-md-9'><input class='form-control' type='text' name='PHONE' value='%PHONE%'></div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>E-Mail:</label>
		<div class='col-md-9'><input class='form-control' type='text' name='EMAIL' value='%EMAIL%'></div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>_{COMMENTS}_:</label>
		<div class='col-md-9'><input class='form-control' type='text' name='COMMENTS' value='%COMMNETS%'></div>
	</div>
	<div class='form-group'>
		<label class='col-md-3 control-label'>_{ROWS}_:</label>
		<div class='col-md-9'><input class='form-control' type='text' name='PAGE_ROWS' value='%PAGE_ROWS%'></div>
	</div>
</div>

<div class='card-footer'>
	<input class='btn btn-primary' type='submit' name='search' value='_{SEARCH}_'>
</div>

</div>

</FORM>
</div>
