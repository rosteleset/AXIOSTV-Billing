<form name='SORM_DICTIONARIES' class='form form-horizontal hidden-print form-main'>
  <input type='hidden' name='index' value=$index>
  <div class='card card-primary card-outline col-md-8 container'>

    <div class='card-header with-border'>SORM_DICTIONARIES</div>

    <div class='card-body'>
      <div class='form-group align-content-center'>
        <label for='SORM_IP_PLAN'>Справочник IP_PLAN</label>
<table>
<th>DESC</th><th>IPv4</th><th>IPv6</th><th>Маска</th><th>От</th><th>До</th>
<tr>
<td><input type='text' class='form-control' name ='SORM_IP_PLAN_DESC' id='SORM_IP_PLAN_DESC' value='%SORM_IP_PLAN_DESC%'</td>
<td><input type='text' class='form-control' id='SORM_IP_PLAN_V4' >%SORM_IP_PLAN%</td>
<td><input type='text' class='form-control' id='SORM_IP_PLAN_V6' >%SORM_IP_PLAN%</td>
<td><input type='text' class='form-control' id='SORM_IP_PLAN_MASK' >%SORM_IP_PLAN%</td>
<td><input type='text' class='form-control' id='SORM_IP_PLAN_FROM' >%SORM_IP_PLAN%</td>
<td><input type='text' class='form-control' id='SORM_IP_PLAN_TO' >%SORM_IP_PLAN%</td>
</tr>
<tr>
<td><input type='text' class='form-control' name ='SORM_IP_PLAN_DESC' id='SORM_IP_PLAN_DESC' value='%SORM_IP_PLAN_DESC%'</td>
<td><input type='text' class='form-control' id='SORM_IP_PLAN_V4' >%1SORM_IP_PLAN%</td>
<td><input type='text' class='form-control' id='SORM_IP_PLAN_V6' >%1SORM_IP_PLAN%</td>
<td><input type='text' class='form-control' id='SORM_IP_PLAN_MASK' >%1SORM_IP_PLAN%</td>
<td><input type='text' class='form-control' id='SORM_IP_PLAN_FROM' >%1SORM_IP_PLAN%</td>
<td><input type='text' class='form-control' id='SORM_IP_PLAN_TO' >%1SORM_IP_PLAN%</td>
</tr>
</table>


$html->form_select(
  'TP_ID',
  {
    SELECTED => $FORM{TP_ID} || q{},
    SEL_LIST => $tariffs->list({ MODULE => 'Dv', COLS_NAME => 1 }),
    SEL_KEY  => 'id',
    SEL_VALUE=> 'name'
  }
);

    <div class='card-body'>
      <div class='form-group align-content-center'>
        <label class='col-sm-12 col-md-12' for='SORM_IP_PLAN'>Справочник IP_PLAN</label>
        <div class='col-md-12'>
          <textarea class='form-control' id='SORM_IP_PLAN_DESC' name='SORM_IP_PLAN_DESC'>%SORM_IP_PLAN_DESC%</textarea>
        </div>
      </div>

      <div class='form-group'>
        <label class='col-sm-12 col-md-12' for='SORM_EXTERNAL_END_COMMAND'>_{END_COMMAND}_</label>
        <div class='col-md-12'>
          <textarea class='form-control' id='SORM_EXTERNAL_END_COMMAND' name='SORM_EXTERNAL_END_COMMAND'>%SORM_EXTERNAL_END_COMMAND%</textarea>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-sm-12 col-md-12' for='SORM_EXTERNAL_ATTEMPTS'>_{ATTEMPTS}_</label>
        <div class='col-md-12'>
          <input type='number' class='form-control' id='SORM_EXTERNAL_ATTEMPTS' name='SORM_EXTERNAL_ATTEMPTS' value='%SORM_EXTERNAL_ATTEMPTS%'>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-sm-12 col-md-12' for='SORM_EXTERNAL_TIME'>_{TIME}_ (_{IN}_ _{MINUTES}_)</label>
        <div class='col-md-12'>
          <input type='number' class='form-control' id='SORM_EXTERNAL_TIME' name='SORM_EXTERNAL_TIME' value='%SORM_EXTERNAL_TIME%'>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LANG%'>
    </div>
  </div>
</form>
