<form action='%SELF_URL%' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='ID' value='%ID%'>

<div class='card box-big-form box-primary '>
<div class='card-header with-border'><h4>_{TARIF_PLANS}_</h4></div>
<div class='card-body'>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{NAME}_:</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name=NAME value='%NAME%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{PERCENTAGE}_:</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name=PERCENTAGE value='%PERCENTAGE%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{OPERATION_PAYMENT}_:</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name=OPERATION_PAYMENT value='%OPERATION_PAYMENT%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{OPERATION_PAYMENT}_ _{EXPRESSION}_:</label>
    <div class='col-md-9'>
      <textarea class='form-control' placeholder='COUNT>10=PRICE:100;
TOTAL_SUM>100=PRICE:20;' name='PAYMENT_EXPR' cols=20 rows=5>%PAYMENT_EXPR%</textarea>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{PAYMENT_TYPE}_:</label>
    <div class='col-md-9'>
      %PAYMENT_TYPE_SEL%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{ACTIVATE}_:</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name=ACTIVATE_PRICE value='%ACTIVATE_PRICE%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{CHANGE}_:</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name=CHANGE_PRICE value='%CHANGE_PRICE%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{CREDIT}_:</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name=CREDIT value='%CREDIT%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{MIN_USE}_:</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name=MIN_USE value='%MIN_USE%'>
    </div>
  </div>
  <div class='form-group'>
<!--
  <div class='checkbox'>
    <label>
      <input type='checkbox' name=NAS_TP value='1' %NAS_TP%><strong>_{NAS}_</strong>
    </label>
  </div>
-->
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{BONUS}_ _{CARDS}_:</label>
    <div class='col-md-9'>
      <input class='form-control' type=text name=BONUS_CARDS value='%BONUS_CARDS%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{COMMENTS}_:</label>
    <div class='col-md-9'>
      <textarea class='form-control' cols=60 rows=6 name=COMMENTS>%COMMENTS%</textarea>
    </div>
  </div>
</div>
<div class='card-footer'>
  <input class='btn btn-primary' type=submit name='%ACTION%' value='%LNG_ACTION%'>
</div>
</div>

</form>
