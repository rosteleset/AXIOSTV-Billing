<form class='form-horizontal' action='$SELF_URL' name='users_pi' METHOD='POST' ENCTYPE='multipart/form-data'>
  <div class='card card-primary card-outline box-big-form'>
    <div class='card-header with-border'><h3 class='card-title'>_{INFO}_</h3></div>
    <div class='card-body'>
      <div class='col-md-12 col-xs-12'>
        <div class='input-group' style='margin-bottom: -1px;'>
          <span class='input-group-addon'><span class='fa fa-user'></span></span>
          <input class='form-control' type='text' readonly value='%FIO%' placeholder='_{FIO}_'>
        </div>
        <div class='input-group' style='margin-bottom: -1px;'>
          <span class='input-group-addon'><span class='fa fa-home'></span></span>
            <input class='form-control' type='text' readonly value='%CITY%, %ADDRESS_FULL%' placeholder='_{ADDRESS}_'>
        </div>
        <div class='input-group' style='margin-bottom: -1px;'>
          <span class='input-group-addon'><span class='fa fa-phone'></span></span>
          <input class='form-control' type='text' readonly value='%PHONE%' placeholder='_{PHONE}_'>
        </div>
      </div>
      <div class='col-md-12 col-xs-12'>
        <div class='input-group' style='margin-top: 5px;'>
        <span class='input-group-addon'><span class='align-middle fa fa-exclamation-circle'></span></span>
        <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3' readonly>%COMMENTS%</textarea>
          </div>
        </div>
    </div>
  </div>
</form>
