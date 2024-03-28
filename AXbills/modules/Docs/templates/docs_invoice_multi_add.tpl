<form action=$SELF_URL class='form-horizontal' id='multi_add'>
<input type=hidden name=index value=$index>
<input type=hidden name=INCLUDE_BALANCE value=1>
    <div class='card card-primary card-outline box-form'>
      <div class='card-header with-border'><h3 class='card-title'>_{CREATE}_ _{INVOICE}_</h3>
        <div class='card-tools float-right'>
        <button type='button' class='btn btn-secondary btn-xs' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>
        <div class='form-group'>
          <label class=' col-md-4 control-label' for='DATE'>_{DATE}_:</label>
          <div class='col-md-8'>
            <input class='form-control' data-provide='datepicker' data-date-format='yyyy-mm-dd' value='%DATE%' name='DATE'>
          </div>
        </div>
        <div class='form-group'>
          <label class='control-label col-md-4' for='ORDER'>_{ORDER}_:</label>
          <div class='col-md-8'>
            <input class='form-control' type='text' name=ORDER value=%ORDER%>
          </div>
        </div>
        <div class='form-group'>
          <label class='control-label col-md-4' for='SUM'>_{SUM}_:</label>
          <div class='col-md-8'>
            <input class='form-control' type='text' name=SUM value=%SUM%>
          </div>
        </div>
        <div class='form-group'>
          <label class='control-label col-md-4' for='SEND_EMAIL'>_{SEND}_ E-mail:</label>
          <div class='col-md-8'>
            <input type=checkbox name=SEND_EMAIL value='1' checked>
          </div>
        </div>
      </div>
      <div class='card-footer'>      
        <input type=submit name=create value='_{CREATE}_' class='btn btn-primary'>
      </div>
    </div>
    
%USERS_TABLE%
</form>
