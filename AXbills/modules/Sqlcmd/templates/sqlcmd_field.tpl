<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<input type=hidden name=TABLE_INFO value=$FORM{TABLE_INFO}>
<input type=hidden name=FIELD value=$FORM{FIELD}>

<div class='card box-form box-primary form-horizontal'>
<div class='card-header with-border'><h4 class='card-title'>$FORM{TABLE_INFO}.$FORM{FIELD}</h4></div>
<div class='card-body'>
	<div class='form-group row'>
	  <label class='control-label col-md-3'>_{NAME}_:</label>
	  <div class='col-md-9'>
	  	<input class='form-control' type=text name=NAME value='%NAME%'>
	  </div>
	</div>
	<div class='form-group row'>
	  <label class='control-label col-md-3'>_{TYPE}_:</label>
	  <div class='col-md-9'>
	  	%COLUMN_TYPE_SEL%
	  </div>
	</div>
	<div class='form-group row'>
	  <label class='control-label col-md-3'>_{LENGTH}_:</label>
	  <div class='col-md-9'>
	  	<input class='form-control' type=text name=COLUMN_LENGTH value='%COLUMN_LENGTH%'>
	  </div>
	</div>
	<div class='form-group row'>
	  <label class='control-label col-md-3'>_{DEFAULT}_:</label>
	  <div class='col-md-9'>
	  	%DEFAULT_SEL%
	  </div>
	  <label class='control-label col-md-3'></label>
	  <div class='col-md-9'>
	  	<input class='form-control' type=text name=DEFAULT value='%DEFAULT%'>
	  </div>
	</div>
	<div class='form-group row'>
	  <label class='control-label col-md-3'>COLLATION:</label>
	  <div class='col-md-9'>
	  	%COLLATION_SEL%
	  </div>
	</div>
	<div class='form-group row'>
	  <label class='control-label col-md-3'>ATTRIBUTE:</label>
	  <div class='col-md-9'>
	  	%ATTRIBUTE_TYPE_SEL%
	  </div>
	</div>
	<div class='form-group row'>
    	<label class='control-label col-md-3' for='NULL'>Null:</label>
    	<div class='col-md-9'>
      	<input type='checkbox' name='NULL' value='1' %NULL%>
        </div>
	</div>
	<div class='form-group row'>
    	<label class='control-label col-md-3' for='AUTO_INCREMENT'>AUTO_INCREMENT:</label>

	  <div class='col-md-9'>
	  	<input type='checkbox' name='AUTO_INCREMENT' value='1' %AUTO_INCREMENT%>
	  </div>

	</div>
	<div class='form-group row'>
	  <label class='control-label col-md-3'>_{COMMENTS}_:</label>
	  <div class='col-md-9'>
	  	<input class='form-control' type=text name=COMMENTS value='%COMMENTS%'>
	  </div>
	</div>

	<div class='form-group row'>
	  <label class='control-label col-md-3'>_{SHOW}_:</label>
	  <div class='col-md-9'>
	  	<input type=checkbox name=SHOW value='1' %SHOW% >
	  </div>
	</div>

</div>
<div class='card-footer'>
	<input type=submit name=change value=_{CHANGE}_ class='btn btn-primary'>
</div>
</div>

</form>