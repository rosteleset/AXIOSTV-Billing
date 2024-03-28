<style>
.odd{
	background-color:#fafafa;
}
</style>
<FORM action='$SELF_URL' METHOD='POST'  enctype='multipart/form-data' class='form form-horizontal'>

<div class='card card-primary card-outline'>
<div class='card-header with-border'><h4 class='card-title'>%SUBJECT%</h4></div>
<div class='card-body'>
<input type='hidden' name='qindex' value='$index'/>
<input type='hidden' name='UID' value='$FORM{UID}'/>
<input type='hidden' name='ID' value='%ID%'/>
<input type='hidden' name='PARENT' value='%PARENT%'/>
<input type='hidden' name='REACTION_TIME' value='%REACTION_TIME%'/>
<input type='hidden' name='DATETIME' value='%DATETIME%'/>
<input type='hidden' name='OLD_PLANNED_CONTACT' value='%OLD_PLANNED_CONTACT%'/>
<input type='hidden' name='header' value='1'/>

<div class='form-group'>
	<div class='col-xs-2'>
		<label>ID:</label>
	</div>
	<div class='col-xs-4'>
		<label>%ID%</label>
	</div>

	<div class='col-xs-2'>
        <label>_{CHAPTERS}_:</label>
	</div>
	<div class='col-xs-4'>
		<label>%CHAPTER%</label>
	</div>
</div> <!--end row-->

<div class='form-group odd'>
	<div class='col-xs-2'>
        <label>_{STATUS}_:</label>
	</div>
	<div class='col-xs-4'>
		<label>%STATE_SEL%</label>
	</div>
	<div class='col-xs-2'>
        <label>_{PRIORITY}_:</label>
	</div>
	<div class='col-xs-4'>
		<label>%PRIORITY_SEL%</label>
	</div>
</div> <!--end row-->

<div class='form-group'>
	<div class='col-xs-2'>
        <label>_{CREATED}_:</label>
	</div>
	<div class='col-xs-4'>
		<label>%DATETIME%</label>
	</div>
	<div class='col-xs-2'>
        <label>_{CLOSED}_:</label>
	</div>
	<div class='col-xs-4'>
		<label>%CLOSED_DATE%</label>
	</div>
</div> <!--end row-->

<div class='form-group bg-info odd'>
	<div class='col-xs-6'>
        <label>_{CONNECTION_TIME}_:</label>
	</div>
	<div class='col-xs-6'>
		<input type='text' name='CONNECTION_TIME' value='%CONNECTION_TIME%' class='form-control' ID='CONNECTION_TIME'/>
	</div>
</div> <!--end row-->

    <div class='form-group bg-info odd'>
		<div class='col-xs-6'>
			<label>_{RESPONSIBLE}_:</label>
		</div>
		<div class='col-xs-6'>
            <label>%RESPOSIBLE_SEL%</label>
		</div>
	</div> <!--end row-->

<div class='form-group'>
	<div class='col-xs-3'>
        <label>_{FIO}_:</label>
	</div>
	<div class='col-xs-4'>
		<label> %FIO% </label>
	</div>
</div> <!--end row-->

<div class='form-group'>
	%UNREG_EXTRA_INFO%
</div>

<div class='form-group odd'>
	<div class='col-xs-3'>
        <label>_{COMPANY}_:</label>
	</div>
	<div class='col-xs-4'>
		<label>%COMPANY%</label>
	</div>
</div> <!--end row-->

<div class='form-group'>
	<div class='col-xs-3'>
        <label>_{PHONE}_:</label>
	</div>
	<div class='col-xs-4'>
		<label> %PHONE% </label>
	</div>
</div> <!--end row-->

<div class='form-group odd'>
	<div class='col-xs-3'>
        <label>_{ADDRESS}_:</label>
	</div>
	<div class='col-xs-4'>
		<label> %ADDRESS_DISTRICT% %ADDRESS_STREET%, %ADDRESS_BUILD%  %ADDRESS_FLAT% </label>
	</div>
</div> <!--end row-->

<div class='form-group'>
	<div class='col-xs-3'>
		<label>E-mail:</label>
	</div>
	<div class='col-xs-4'>
		<label> %EMAIL% </label>
	</div>
</div> <!--end row-->

<div class='form-group odd' style='margin:0px; padding:0px;'>
	<div class='col-xs-3'>

	</div>
	<div class='col-xs-4'>
		<p> %REQUEST% </p>
	</div>
</div> <!--end row-->

<div class='form-group'>
	<div class='col-md-6'>
		<div class="row">
			<div class='col-xs-4'>
				<label>_{LAST_CONTACT}_:</label>
			</div>
			<div class='col-xs-8'>
				<label>%LAST_CONTACT%</label>
			</div>
		</div><!--end row-->

		<div class="row">
			<div class='col-xs-4'>
				<label>_{SUBSEQENT_CONTACT}_:</label>
			</div>
			<div class='col-xs-8'>
				<label>%PLANNED_CONTACT%</label>
			</div>
		</div><!--end row-->

	</div>

	<div class='col-md-12'>
	<label> _{NOTE}_: </label>
	</div>
	<div class='col-md-12'>
	<textarea cols=60 ID=CONTACT_NOTE rows=2 name=CONTACT_NOTE class='form-control'>%CONTACT_NOTE%</textarea>
	</div>
</div>

	<div class='form-group'>
		<div class='col-md-12'>
			<label> _{COMMENTS}_: </label>
		</div>
		<div class='col-md-12'>
			<textarea cols=60 ID=COMMENTS rows=4 name=COMMENTS class='form-control'>%COMMENTS%</textarea>
		</div>
	</div> <!--end row-->

</div><!--end row-->



<div class='card-footer'>
    <input type=submit class='btn btn-primary' name=change value='_{CHANGE}_'>
</div>
</div> <!--box-->
</form>


<div class='d-print-none' align=center>
<p>
    <a href='javascript:window.print();' class='btn btn-secondary btn-xs print'>_{PRINT}_</a>
    <a href='javascript:window.close();' class='btn btn-secondary btn-xs del'>_{CLOSE}_</a>
</p>
</div>