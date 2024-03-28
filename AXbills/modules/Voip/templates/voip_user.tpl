<form action=%SELF_URL% method=post id='VOIP_USER_FORM'>
  <input type=hidden name=index value=%index%>
  <input type=hidden name=UID value='$FORM{UID}'>
  <input type=hidden name='ID' value='%ID%'>
  <div class='card card-primary card-outline container-md'>

    <div class='card-header with-border'>
      <h4 class='card-title'>VOIP: %ID%</h4>
    </div>

    <div class='card-body'>
      <div class='row no-padding'>
        <div class="col-md-12 text-center">
          %MENU%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='NUMBER'>_{NUMBER}_:</label>
        <div class='col-md-9'>
          <input id='NUMBER' name='NUMBER' value='%NUMBER%' placeholder='%NUMBER%' class='form-control'
                 type='text'>
        </div>
      </div>


      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='TP'>_{TARIF_PLAN}_:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            %TP_ADD%
            <div class='input-group' %TP_DISPLAY_NONE%>
              <div class='input-group-prepend'>
                <div class='input-group-text'>
                  <span class='hidden-xs'>%TP_NUM%</span>
                </div>
              </div>
              <input type='text' name='GRP' value='%TP_NAME%' ID='TP' class='form-control hidden-xs' %TARIF_PLAN_TOOLTIP% readonly>
              <div class='input-group-append'>
                %CHANGE_TP_BUTTON%
                <a class='btn input-group-button hidden-print px-3' title='_{PAY_TO}_'
                   href='$SELF_URL?index=$index&UID=$FORM{UID}&ID=%ID%&pay_to=1'>
                  <i class='$conf{CURRENCY_ICON}'></i>
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='SIMULTANEOUSLY'>_{SIMULTANEOUSLY}_:</label>
        <div class='col-md-9'>
          <input id='SIMULTANEOUSLY' name='SIMULTANEOUSLY' value='%SIMULTANEOUSLY%'
                 placeholder='%SIMULTANEOUSLY%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='IP'>IP:</label>
        <div class='col-md-9'>
          <input id='IP' name='IP' value='%IP%' placeholder='%IP%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='CID'>CID:</label>
        <div class='col-md-9'>
          <input id='CID' name='CID' value='%CID%' placeholder='%CID%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='ALLOW_ANSWER'>_{ALLOW_ANSWER}_:</label>
        <div class='col-md-3 mt-2'>
          <input id='ALLOW_ANSWER' name='ALLOW_ANSWER' value='1' %ALLOW_ANSWER% type='checkbox'>
        </div>

        <label class='col-md-3 col-form-label text-md-rights' for='ALLOW_CALLS'>_{ALLOW_CALLS}_:</label>
        <div class='col-md-3 mt-2'>
          <input id='ALLOW_CALLS' name='ALLOW_CALLS' value='1' %ALLOW_CALLS% type='checkbox'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='STATUS_SEL'>_{STATUS}_:</label>
        <div class='col-md-9'>
          %STATUS_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='FILTER_ID'>FILTER ID:</label>
        <div class='col-md-9'>
          <input id='FILTER_ID' name='FILTER_ID' value='%FILTER_ID%' placeholder='%FILTER_ID%'
                 class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <div class="col-md-3"></div>
        <div class='col-md-9'>
          %PROVISION%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='VOIP_EXPIRE'>_{EXPIRE}_:</label>
        <div class='col-md-9'>
          <input id='VOIP_EXPIRE' name='VOIP_EXPIRE' value='%VOIP_EXPIRE%' placeholder='%VOIP_EXPIRE%'
                 class='tcal form-control' type='text'>
        </div>
      </div>


    </div>
    <div class='card-footer'>
      %DEL_TP_BUTTON%
      <input type=submit name=%ACTION% value='%LNG_ACTION%' ID='submitbutton' class='btn btn-primary'>
    </div>
  </div>

</form>
