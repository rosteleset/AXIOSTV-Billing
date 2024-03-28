<style>
  body  {
    padding: 3%;
  }
  .paysys-chooser{
    background-color: white;
  }

  input:checked + .paysys-chooser-box  {
    transform: scale(1.01,1.01);
    box-shadow: 8px 8px 3px #AAAAAA;
    z-index: 100;
  }

  input:checked + .paysys-chooser-box > .box-footer{
    background-color: lightblue;
  }

  .paysys-chooser:hover{
    transform: scale(1.05,1.05);
    box-shadow: 10px 10px 5px #AAAAAA;
    z-index: 101;
  }
</style>

<form method='POST' action='$SELF_URL'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='sid' value='$FORM{sid}'>
  <input type='hidden' name='recharge' value='$FORM{recharge}'>
  <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'>
  <input type='hidden' name='SUM' value='%SUM%'>
  <input type='hidden' name='DESCRIBE' value='Hotspot $FORM{TP_ID}'>
  <input type='hidden' name='BUY_CARDS' value='1'>
  <input type='hidden' name='TP_ID' value='$FORM{TP_ID}'>
  <input type='hidden' name='UID' value='%UID%'>
  <input type='hidden' name='DOMAIN_ID' value='%DOMAIN_ID%'>
  <input type='hidden' name='mac' value='%MAC%'>
  <input type='hidden' name='UNIFI_SITENAME' value='%UNIFI_SITENAME%'>
  <input type='hidden' name='server_name' value='%server_name%'>
  <input type='hidden' name='link_login_only' value='%link_login_only%'>

  <div class='row'>
    <div class='col-md-3 col-lg-3 col-xs-3 hidden-xs'></div>
    <div class='col-md-6 col-sm-12 col-xs-12 col-lg-6'>
      <div class='card box-success'>
        <div class='card-header with-border text-center'>
          <h3 style='margin:0'> _{ICARDS}_ - _{BUY}_ </h3>
        </div>
        <div class='card-body' style='margin-top: 0%; padding-top: 1%;'>
          <div style='margin-left:2%; margin-top:0%;'>
            <div class='row'>
              <div class='col-sm-6 col-xs-4 text-right'>
                <label>ID:</label>
              </div>
              <div class='col-sm-6 col-xs-7'>
                %OPERATION_ID%
              </div>
            </div>

            <div class='row' style='padding-bottom: 25px; padding-top:5px; margin-bottom: 5px;'>
              <div class='col-sm-6 col-xs-4 text-right'>
                <label>_{SUM}_:</label>
              </div>
              <div class='col-sm-6  col-xs-8'>
                %SUM%
              </div>
            </div>

            <div class='row'>
              <div class='col-md-6 col-sm-6 col-xs-4 text-right'>
                <label>_{DESCRIBE}_:</label>
              </div>
              <div class='col-md-6 col-sm-6 col-xs-8'>
                Hotspot $FORM{TP_ID}
              </div>
            </div>

            <div class='row form-group'>
              <div class='col-md-6 col-sm-6 col-xs-4 text-right'>
                <label style='margin-top:5px;'>_{PHONE}_:</label>
              </div>
              <div class='col-md-6 col-sm-6 col-xs-8'>
                <input type=text name='PHONE' value='%PHONE%' class='form-control'>
              </div>

            </div>


            <label class='col-md-12 bg-primary text-center' style='margin-top:5px;'>_{PAY_SYSTEM}_:</label>

            %PAYSYS_SYSTEM_SEL%
          </div>

        </div>
        <div class='card-footer' style='margin:0%; padding: 0%;'>
          <div class='row'>
            <div class='col-sm-5 col-xs-5 col-md-5 col-xs-5 col-lg-5 col-xs-5'></div>
            <div class='col-md-4'>
              <input class='btn btn-lg btn-primary' type='submit' name=pre value='_{BUY}_'/>
            </div>
            <div class='col-sm-5 col-xs-5 col-md-5 col-xs-5 col-lg-5 col-xs-5'></div>
          </div>
        </div>
      </div>
    </div>
    <div class='col-md-3 col-lg-3 col-xs-3 hidden-xs'></div>
  </div>

</form>