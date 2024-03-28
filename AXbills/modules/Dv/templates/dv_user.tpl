

<!-- STATUS COLOR -->
<style>
    .alert-%STATUS%
    {
    /*color : %STATUS_COLOR%;*/

        background-image: -webkit-linear-gradient(top, %STATUS_COLOR_GR_S% 0, %STATUS_COLOR_GR_F% 100%);
        background-image: -o-linear-gradient(top, %STATUS_COLOR_GR_S% 0, %STATUS_COLOR_GR_F% 100%);
        background-image: -webkit-gradient(linear, left top, left bottom, from(%STATUS_COLOR_GR_S%), to(%STATUS_COLOR_GR_F%));
        background-image: linear-gradient(to bottom, %STATUS_COLOR_GR_S% 0, %STATUS_COLOR_GR_F% 100%);
        filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='%STATUS_COLOR_GR_S%', endColorstr='%STATUS_COLOR_GR_F%', GradientType=0);
        background-repeat: repeat-x;
        border-color:%STATUS_COLOR%;

    }
</style>

<form class='form-horizontal' action='$SELF_URL' method='post'>

  <input type=hidden name='index' value='$index'>
  <input type=hidden name='UID' value='$FORM{UID}'>
  <input type=hidden name='STATUS_DAYS' value='%STATUS_DAYS%'>
  <input type=hidden name='step' value='$FORM{step}'>
  <input type='hidden' name='LEAD_ID' value='$FORM{LEAD_ID}'>

  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{DV}_</h4>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-box-tool' data-card-widget='collapse'><i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='nav-tabs-custom box-body'>
      <div class='row no-padding'>
        <div class="col-md-12 text-center">
        %MENU%
        </div>
      </div>
      %ONLINE_TABLE%
      <div style='padding: 10px; padding-top : 0'>

        %PAYMENT_MESSAGE%

        %NEXT_FEES_WARNING%

        %LAST_LOGIN_MSG%

        %LOGIN_FORM%
        <div class='form-group'>
          <label class='control-label col-xs-4 float-left' for='TP'>_{TARIF_PLAN}_</label>
          <div class='col-xs-8'>
            %TP_ADD%
            <div class='input-group' %TP_DISPLAY_NONE%>
              <span class='hidden-xs input-group-addon bg-primary'>%TP_ID%</span>
              <input type=text name='GRP' value='%TP_NAME%' ID='TP' class='form-control hidden-xs'
                     readonly>
              <input type=text name='GRP1' value='%TP_ID%:%TP_NAME%' ID='TP' class='form-control visible-xs'
                     readonly>
              <span class='input-group-addon'>%CHANGE_TP_BUTTON%</span>
              <span class='input-group-addon'><a
                  href='$SELF_URL?index=$index&UID=$FORM{UID}&pay_to=1'
                  class='$conf{CURRENCY_ICON}' title='_{PAY_TO}_'></a></span>
            </div>
          </div>
          <div class='col-md-12'>%PERSONAL_TP_MSG%</div>
        </div>

        <div class='form-group alert alert-%STATUS%'>
          <label class='control-label col-xs-4'>_{STATUS}_</label>
          <div class='col-xs-8'>
            <div class='input-group'>
              %STATUS_SEL%
              <span class='input-group-addon'>%SHEDULE%</span>
            </div>
            <div class='row text-center'>
              <strong>%STATUS_INFO%</strong>
            </div>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-xs-4 col-md-2'>_{STATIC}_ IP Pool</label>
          <div class='col-xs-8 col-md-4'>
            %STATIC_IP_POOL%
          </div>
          <span class='visible-xs visible-sm col-xs-12' style='padding-top: 10px'> </span>
          <label class='control-label col-xs-4 col-md-2' for='IP'>_{STATIC}_ IP</label>
          <div class='col-xs-8 col-md-4'>
            <input id='IP' name='IP' value='%IP%' placeholder='%IP%' class='form-control'
                   type='text'>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-xs-4 col-md-2' for='NETMASK'>MASK</label>
          <div class='col-xs-8 col-md-4 %NETMASK_COLOR%'>
            <input id='NETMASK' name='NETMASK' value='%NETMASK%' placeholder='%NETMASK%'
                   class='form-control' type='text'>
          </div>
          <span class='visible-xs visible-sm col-xs-12' style='padding-top: 10px'> </span>
          <label class='control-label col-xs-4 col-md-2' for='CID'>CID (;)</label>
          <div class='col-xs-8 col-md-4'>
            <input id='CID' name='CID' value='%CID%' placeholder='%CID%' class='form-control'
                   type='text'>
          </div>
        </div>
      </div>


      <div class='card box-default box-big-form collapsed-box'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{EXTRA}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-box-tool' data-card-widget='collapse'><i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>

          <div class='form-group'>
            <label class='control-label col-md-3' for='SPEED'>_{SPEED}_ (kb)</label>
            <div class='col-md-3'>
              <input id='SPEED' name='SPEED' value='%SPEED%' placeholder='%SPEED%'
                     class='form-control' type='text'>
            </div>

            <label class='control-label col-md-3' for='LOGINS'>_{SIMULTANEOUSLY}_</label>
            <div class='col-md-3'>
              <input id='LOGINS' type='text' name='LOGINS' value='%LOGINS%' class='form-control'>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='EXPIRE'>_{EXPIRE}_</label>
            <div class='col-md-9 %EXPIRE_COLOR%'>
              <input id='EXPIRE' name='DV_EXPIRE' value='%DV_EXPIRE%' placeholder='%DV_EXPIRE%'
                     class='form-control datepicker' rel='tcal' type='text'>
            </div>
          </div>


          <div class='form-group'>
            <label class='control-label col-md-3' for='FILTER_ID'>_{FILTERS}_</label>
            <div class='col-md-9'>
              <input id='FILTER_ID' name='FILTER_ID' value='%FILTER_ID%' placeholder='%FILTER_ID%'
                     class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='PORT'>_{PORT}_</label>
            <div class='col-md-9'>
              <input id='PORT' name='PORT' value='%PORT%' placeholder='%PORT%'
                     class='form-control' type='text'>
            </div>
          </div>

          <div class='row'>
            <div class='checkbox col-md-6'>
              <label>
                <input id='CALLBACK' type='checkbox' name='CALLBACK' data-return='1' value='1' %CALLBACK%>
                <strong>Callback</strong>
              </label>
            </div>

            <div class='checkbox col-md-6'>
              <label>
                <input type='checkbox' id='DETAIL_STATS' name='DETAIL_STATS' data-return='1' value='1' %DETAIL_STATS%/>
                <strong>_{DETAIL}_</strong>
              </label>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3 float-left'>_{PERSONAL}_ _{TARIF_PLAN}_</label>
            <div class='col-md-9'>
              <input type='text' class='form-control' name='PERSONAL_TP' value='%PERSONAL_TP%'>
            </div>
          </div>
          <div class='form-group'>
            <label class='control-label col-md-3'>$lang{MEMO}</label>
            <div class='col-md-3' align='left'>
              %REGISTRATION_INFO%
            </div>
            <label class='control-label col-md-3' style='display: %PDF_VISIBLE% none'>$lang{MEMO} (PDF)</label>
            <div class='col-md-3' align='left' style='display: %PDF_VISIBLE% none'>
              %REGISTRATION_INFO_PDF%
              %PASSWORD_BTN%
            </div>
          </div>
          %TURBO_MODE_FORM%
          %DEL_FORM%
        </div>
      </div>

      <div class='card-footer'>
        %BACK_BUTTON%
        <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'/>
      </div>
    </div>
  </div>
</form>

