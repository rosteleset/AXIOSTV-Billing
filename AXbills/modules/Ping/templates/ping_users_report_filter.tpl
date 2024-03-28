<form action='$SELF_URL' class='form-horizontal'>
  <input type=hidden  name=index value='$index'>

  <fieldset>

  <div class='card card-primary card-outline collapsed-box'>
        <div class="card-header with-border">
          <h3 class="card-title"><i class='fa fa-fw fa-filter'></i>_{FILTERS}_</h3>
          <div class="card-tools float-right">
            <button type="button" class="btn btn-secondary btn-xs" data-card-widget="collapse"><i class="fa fa-plus"></i>
            </button>
          </div>
        </div>

        <div class='card-body' style="padding: 0px">

        <div style="padding: 10px">

            <div class='form-group'>
              <label class='col-md-2 control-label' for='GROUP'>Ping _{STATUS}_</label>
              <div class='col-md-10'>
                %PING_STATUS%
              </div>
            </div>

           <div class='form-group'>
              <label class='col-md-2 control-label' for='GROUP'>_{DATE}_</label>
              <div class='col-md-10'>
                %DATE_RANGE%
              </div>
            </div>
            <div class='form-group'>
              <label class='col-md-2 control-label' for='GROUP'>_{GROUP}_</label>
              <div class='col-md-10'>
                %GROUP_SEL%
              </div>
            </div>
            <div class='form-group'>
              <label class='col-md-2 control-label' for='GROUP'>_{LOGIN}_</label>
              <div class='col-md-10'>
                %USER_LOGIN%
              </div>
            </div>
        </div>

          <div class="card card-primary card-outline collapsed-box">
            <div class="card-header with-border">
              <h4 class="card-title">_{ADDRESS}_</h4>
              <div class="card-tools float-right">
                <button type="button" class="btn btn-secondary btn-xs" data-card-widget="collapse"><i class="fa fa-plus"></i>
                </button>
              </div>
            </div>
            <div class="card-body">
              %ADDRESS_FORM%
            </div>
          </div>

          <div style="padding: 10px">
         <input name="apply" value="_{APPLY}_" class="btn btn-primary" type="submit">
         </div>
        </div>
      </div>
  </fieldset>
</form>