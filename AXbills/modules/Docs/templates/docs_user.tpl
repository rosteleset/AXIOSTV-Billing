
<form action='$SELF_URL' method='post'>
<input type=hidden name=index value=$index>
<input type=hidden name='UID' value='$FORM{UID}'>
<input type=hidden name='sid' value='$FORM{sid}'>
<input type=hidden name='step' value='$FORM{step}'>


<div class='card card-primary card-outline card-form'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{OPTIONS}_  </h4>

    <span class='float-right'>
        <a href='$SELF_URL?qindex=$index&STATEMENT_OF_ACCOUNT=1&UID=$FORM{UID}&header=1' target=new class='btn btn-xs btn-success'>_{STATEMENT_OF_ACCOUNT}_</a>
    </span>

  </div>
  <div class='card-body'>
  <fieldset>
    %MENU%

    <div class='form-group row'>
      <label class='control-label col-md-6' for='PERIODIC_CREATE_DOCS'>_{INVOICE_AUTO_GEN}_</label>
      <div class='col-md-6'>
        <input id='PERIODIC_CREATE_DOCS' name='PERIODIC_CREATE_DOCS' value='1' type='checkbox' %PERIODIC_CREATE_DOCS%>
      </div>
    </div>

    <div class='form-group row'>
      <label class='control-label col-md-6' for='SEND_DOCS'>_{SEND}_ E-mail</label>
      <div class='col-md-6'>
        <input id='SEND_DOCS' name='SEND_DOCS' value='1' type='checkbox' %SEND_DOCS%>
      </div>
    </div>

    <div class='form-group row'>
      <label class='control-label col-md-6' for='PERSONAL_DELIVERY'>_{PERSONAL_DELIVERY}_</label>
      <div class='col-md-6'>
        <input id='PERSONAL_DELIVERY' name='PERSONAL_DELIVERY' value='1' type='checkbox' %PERSONAL_DELIVERY%>
      </div>
    </div>

    <div class='form-group row'>
      <label class='control-label col-md-6' for='EMAIL'>E-mail</label>
      <div class='col-md-6'>
        <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='%EMAIL%' class='form-control' type='text'>
      </div>
    </div>

    <div class='form-group row'>
      <label class='control-label col-md-6' for='INVOICE_PERIOD'>_{INVOICING_PERIOD}_</label>
      <div class='col-md-6'>
        %INVOICE_PERIOD_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label class='control-label col-md-6' for='INVOICE_DATE'>_{INVOICE}_ _{DATE}_</label>
      <div class='col-md-6'>
        <input id='INVOICE_DATE' name='INVOICE_DATE' value='%INVOICE_DATE%' placeholder='%INVOICE_DATE%' class='form-control datepicker' type='text'>
      </div>
    </div>

    <div class='form-group row'>
      <label class='control-label col-md-6' for='NEXT_INVOICE_DATE'>_{NEXT_INVOICE_DATE}_</label>
      <div class='col-md-6'>
        %NEXT_INVOICE_DATE%
      </div>
    </div>

    <div class='form-group row'>
      <label class='control-label col-md-6' for='COMMENTS'>_{COMMENTS}_</label>
      <div class='col-md-6'>
        <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
      </div>
    </div>

  </fieldset>
  </div>
  <div class='card-footer with-border'>
    %BACK_BUTTON%
    <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
  </div>

</div>

</form>

