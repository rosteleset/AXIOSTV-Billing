<form name='report_panel' id='report_panel' method='post' class='form form-inline form-main' value='1'>
<input type='hidden' name='index' value='$index' />
<div class="well well-sm">

	<div class='form-group'>
	  <label>_{DATE_OF_EXECUTION}_</label>
	      %DATE_OF_EXECUTION%
	</div>

	<div class='form-group'>
	  <label>_{DATE_OF_CREATION}_</label>
	      %DATE_OF_CREATION%
	</div>
	
	<div class='form-group'>
	  <label>_{STATUS}_</label>
	      %STATUS_SELECT%
	</div>

	<div class='form-group'>
	  <label>_{RESPONSIBLE}_</label>
	        %RESPONSIBLE_SELECT%
	</div>

<br><br><div class="form-group"><input type="submit" name="show" value="Показать" class="btn btn-primary" form="report_panel" id="show"></div></div></form>