<form action='$SELF_URL' ID='mapAddRoute' name='mapAddRoute' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='$FORM{chg}'>
  <input type='hidden' name='route' value='1'>

  <div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'>
      <h4>_{ADD}_ _{ROUTE}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{NAME}_:</label>

        <div class='col-md-9'>
          <input class='form-control' name='NAME' type='text' value='%NAME%'/>
        </div>

      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{TYPE}_:</label>

        <div class='col-md-9'>
          %TYPES%
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{DESCRIBE}_:</label>

        <div class='col-md-9'>
          <textarea class='form-control' name='DESCR'>%DESCR%</textarea>
        </div>
      </div>
      <hr/>
      <div class='form-group'>
        <div class='col-md-6'>
          <label class='control-label col-md-3'>NAS1:</label>

          <div class='col-md-9'>
            %NAS1_SEL%
          </div>
        </div>
        <div class='col-md-6'>
          <label class='control-label col-md-3'>NAS1 port:</label>

          <div class='col-md-9'>
            <input class='form-control' name='NAS1_PORT' type='text' value='%NAS1_PORT%'/>
          </div>
        </div>
      </div>

      <div class='form-group'>
        <div class='col-md-6'>
          <label class='control-label col-md-3'>NAS2:</label>

          <div class='col-md-9'>
            %NAS2_SEL%
          </div>
        </div>
        <div class='col-md-6'>
          <label class='control-label col-md-3'>NAS2 port:</label>

          <div class='col-md-9'>
            <input class='form-control' name='NAS2_PORT' type='text' value='%NAS2_PORT%'/>
          </div>
        </div>
      </div>
      <hr/>
      <div class='form-group'>
        <label class='control-label col-md-3'>_{LENGTH}_:</label>

        <div class='col-md-9'>
          <input class='form-control' name='LENGTH' type='text' value='%LENGTH%'/>
        </div>
      </div>

      <hr/>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PARENT_ID'>_{PARENT_M}_ _{ROUTE}_</label>
        <div class='col-md-9'>
          %PARENT_ROUTE_ID%
        </div>
      </div>
      <div class='form-group'>
        <label class='control-label col-md-3' for='GROUP_ID'>_{PARENT_F}_ _{GROUP}_</label>
        <div class='col-md-9'>
          %GROUP_ID%
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%'>
    </div>


  </div>


</form>