<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<input type=hidden name=TABLE_INFO value=$FORM{TABLE_INFO}>
<input type=hidden name=FIELD value=$FORM{FIELD}>

<div class='card box-form box-primary form-horizontal'>
<div class='card-header with-border'>$FORM{TABLE_INFO}.$FORM{FIELD}</div>
<div class='card-body'>
	<div class='form-group'>
	  <label class='control-label col-md-3'>_{NAME}_:</label>
	  <div class='col-md-9'>
	  	<input class='form-control' type=text name=NAME value='%NAME%'>
	  </div>
	</div>
	<div class='form-group'>
	  <label class='control-label col-md-3'>_{TYPE}_:</label>
	  <div class='col-md-9'>
	  	%COLUMN_TYPE_SEL%
	  </div>
	</div>
	<div class='form-group'>
	  <label class='control-label col-md-3'>_{LENGTH}_:</label>
	  <div class='col-md-9'>
	  	<input class='form-control' type=text name=COLUMN_LENGTH value='%COLUMN_LENGTH%'>
	  </div>
	</div>
	<div class='form-group'>
	  <label class='control-label col-md-3'>_{DEFAULT}_:</label>
	  <div class='col-md-9'>
	  	%DEFAULT_SEL%
	  </div>
	  <label class='control-label col-md-3'></label>
	  <div class='col-md-9'>
	  	<input class='form-control' type=text name=DEFAULT value='%DEFAULT%'>
	  </div>
	</div>
	<div class='form-group'>
	  <label class='control-label col-md-3'>Сравнение:</label>
	  <div class='col-md-9'>
	  	%COLLATION_SEL%
	  </div>
	</div>
	<div class='form-group'>
	  <label class='control-label col-md-3'>Атрибуты:</label>
	  <div class='col-md-9'>
	  	%ATTRIBUTE_TYPE_SEL%
	  </div>
	</div>
	<div class='form-group'>
		<div class='checkbox'>
    	<label>
      	<input type='checkbox' name='NULL' value='1' %NULL%><strong>Null</strong>
    	</label>
  	</div>
	</div>
	<div class='form-group'>
		<div class='checkbox'>
    	<label>
      	<input type='checkbox' name='AUTO_INCREMENT' value='1' %AUTO_INCREMENT%><strong>AUTO_INCREMENT</strong>
    	</label>
  	</div>
	</div>
	<div class='form-group'>
	  <label class='control-label col-md-3'>_{COMMENTS}_:</label>
	  <div class='col-md-9'>
	  	<input class='form-control' type=text name=COMMENTS value='%COMMENTS%'>
	  </div>
	</div>
</div>
<div class='card-footer'>
	<input class='btn btn-primary' type=submit name=change value=_{CHANGE}_ class='btn btn-primary'>
</div>
</div>
</form>