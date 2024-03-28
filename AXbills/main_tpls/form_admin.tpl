<form action='%SELF_URL%' METHOD='POST' class='form-horizontal' id='admin_form' name='admin_form'>
  <input type=hidden name='index' value='%INDEX%'>
  <input type=hidden name='AID' value='%AID%'>
  <div class='row'>
    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'>
          <h3 class='card-title'>%HEADER_NAME%</h3>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right required' for='A_LOGIN'>_{LOGIN}_:</label>
            <div class='col-md-9'>
              <input id='A_LOGIN' name='A_LOGIN' value='%A_LOGIN%' placeholder='%A_LOGIN%'
                     class='form-control' type='text' pattern= '%PATTERN%' >
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='A_FIO'>_{FIO}_:</label>
            <div class='col-md-9'>
              <input id='A_FIO' name='A_FIO' value='%A_FIO%' placeholder='%A_FIO%'
                     class='form-control'
                     type='text'>
            </div>
          </div>

<!--          <div class='form-group row'>-->
<!--            <label class='col-md-3 col-form-label text-md-right' for='PHONE'>_{PHONE}_:</label>-->
<!--            <div class='col-md-9'>-->
<!--              <input id='PHONE' name='PHONE' value='%PHONE%' placeholder='%PHONE%'-->
<!--                     class='form-control'-->
<!--                     type='text'>-->
<!--            </div>-->
<!--          </div>-->
<!--          <div class='form-group row'>-->
<!--            <label class='col-md-3 col-form-label text-md-right' for='EMAIL'>E-Mail:</label>-->
<!--            <div class='col-md-9'>-->
<!--              <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='%EMAIL%'-->
<!--                     class='form-control'-->
<!--                     type='text'>-->
<!--            </div>-->
<!--          </div>-->

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='DISABLE'>_{STATUS}_:</label>
            <div class='col-md-9'>
              %DISABLE_SELECT%
            </div>
          </div>

<!--          <div class='form-group row'>-->
<!--            <label class='col-md-3 col-form-label text-md-right' for='CELL_PHONE'>_{CELL_PHONE}_:</label>-->
<!--            <div class='col-md-9'>-->
<!--              <input id='CELL_PHONE' name='CELL_PHONE' value='%CELL_PHONE%' placeholder='%CELL_PHONE%'-->
<!--                     class='form-control' type='text'>-->
<!--            </div>-->
<!--          </div>-->

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right'>_{DEPARTMENT}_:</label>
            <div class='col-md-9'>
              %DEPARTMENTS%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right'>_{POSITION}_:</label>
            <div class='col-md-9'>
              %POSITIONS%
            </div>
          </div>


          <div class='form-group row %OLD_ADDRESS_CLASS%'>
            <label class='col-md-3 col-form-label text-md-right' for='ADDRESS'>_{ADDRESS}_:</label>
            <div class='col-md-9'>
              <input id='ADDRESS' name='ADDRESS' value='%ADDRESS%' placeholder='%ADDRESS%'
                     class='form-control' type='text'>
            </div>
          </div>

          <div class='card card-primary card-outline collapsed-card %ADDRESS_CARD_CLASS%'>
            <div class='card-header with-border'>
              <h3 class='card-title'>_{ADDRESS}_:</h3>
              <div class='card-tools'>
                <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                  <i class='fa fa-plus'></i>
                </button>
              </div>
            </div>
            <div class='card-body'>
              %ADDRESS_FORM%
            </div>
          </div>

          <div class='card card-primary card-outline collapsed-card'>
            <div class='card-header with-border'>
              <h3 class='card-title'>_{PASPORT}_:</h3>
              <div class='card-tools'>
                <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                  <i class='fa fa-plus'></i>
                </button>
              </div>
            </div>
            <div id='_passport' class='card-collapse card-body'>
              <div class='form-group row'>
                <label class='col-md-3 col-form-label text-md-right' for='PASPORT_NUM'>_{NUM}_:</label>
                <div class='col-md-9'>
                  <input id='PASPORT_NUM' name='PASPORT_NUM' value='%PASPORT_NUM%'
                         placeholder='%PASPORT_NUM%' class='form-control' type='text'>
                </div>
              </div>

              <div class='form-group row'>
                <label for='PASPORT_DATE' class='col-md-3 col-form-label text-md-right'>_{DATE}_:</label>
                <div class='col-md-9'>
                  %PASPORT_DATE%
                </div>
              </div>

              <div class='form-group row'>
                <label class='col-md-3 col-form-label text-md-right' for='PASPORT_GRANT'>_{GRANT}_:</label>
                <div class='col-md-9'>
                  <textarea class='form-control' id='PASPORT_GRANT' name='PASPORT_GRANT'
                            rows='1'>%PASPORT_GRANT%</textarea>
                </div>
              </div>
            </div>
          </div>
          <br/>

          <div class='form-group row'>
            <label for='GROUP_SEL' class='col-md-3 col-form-label text-md-right'>_{USERS}_ _{GROUPS}_:</label>
            <div class='col-md-9'>
              %GROUP_SEL%
            </div>
          </div>

          <div class='form-group row'>
            <label for='DOMAIN_ID' class='col-md-3 col-form-label text-md-right'>Domain:</label>
            <div class='col-md-9'>
              %DOMAIN_SEL%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right'>_{COMMENTS}_</label>
            <div class='col-md-9'>
              <textarea cols='30' rows='4' name='COMMENTS' class='form-control'>%COMMENTS%</textarea>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{OTHER}_</h3>
          <div class='card-tools'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-minus'></i>
            </button>
          </div>
        </div>

        <div id='_other' class='card-collapse card-body'>
          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='INN'>_{INN}_:</label>
            <div class='col-md-9'>
              <input id='INN' name='INN' value='%INN%' placeholder='%INN%' class='form-control'
                     type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='BIRTHDAY'>_{BIRTHDAY}_:</label>
            <div class='col-md-9'>
              <input id='BIRTHDAY' name='BIRTHDAY' value='%BIRTHDAY%' placeholder='%BIRTHDAY%'
                     class='form-control datepicker' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='MAX_ROWS'>_{MAX_ROWS}_:</label>
            <div class='col-md-9'>
              <input id='MAX_ROWS' name='MAX_ROWS' value='%MAX_ROWS%' placeholder='%MAX_ROWS%'
                     class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='MIN_SEARCH_CHARS'>_{MIN_SEARCH_CHARS}_:</label>
            <div class='col-md-9'>
              <input id='MIN_SEARCH_CHARS' name='MIN_SEARCH_CHARS' value='%MIN_SEARCH_CHARS%'
                     placeholder='%MIN_SEARCH_CHARS%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='MAX_CREDIT'>_{MAX}_ _{CREDIT}_:</label>
            <div class='col-md-9'>
              <input id='MAX_CREDIT' name='MAX_CREDIT' value='%MAX_CREDIT%' placeholder='%MAX_CREDIT%'
                     class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='CREDIT_DAYS'>_{MAX}_ _{CREDIT}_ _{DAYS}_:</label>
            <div class='col-md-9'>
              <input id='CREDIT_DAYS' name='CREDIT_DAYS' value='%CREDIT_DAYS%'
                     placeholder='%CREDIT_DAYS%'
                     class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='EXPIRE'>_{EXPIRE}_:</label>
            <div class='col-md-9'>
              <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%'
                     class='form-control datepicker' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='FULL_LOG'>Paranoid _{LOG}_:</label>
            <div class='col-md-9'>
              <div class='form-check'>
                <input type='checkbox' class='form-check-input' id='FULL_LOG' name='FULL_LOG' value='1' %FULL_LOG%>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='RFID_NUMBER'>Android ID:</label>
            <div class='col-md-9'>
              <input id='ANDROID_ID' name='ANDROID_ID' value='%ANDROID_ID%' type='text' class='form-control'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='SIP_NUMBER'>SIP _{PHONE}_:</label>
            <div class='col-md-9'>
              <input id='SIP_NUMBER' name='SIP_NUMBER' value='%SIP_NUMBER%' class='form-control'
                     type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='API_KEY'>API_KEY:</label>
            <div class='col-md-9 input-group-append'>
              <input id='API_KEY' name='API_KEY_NEW' value='%API_KEY%' type='password' class='form-control'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='API_KEY'>Telegram ID:</label>
            <div class='col-md-9'>
              <input id='TELEGRAM_ID' name='TELEGRAM_ID' value='%TELEGRAM_ID%' type='text' class='form-control'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='API_KEY'>GPS IMEI:</label>
            <div class='col-md-9'>
              <input id='gps_imei' name='GPS_IMEI' value='%GPS_IMEI%' type='text'
                     class='form-control'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='RFID_NUMBER'>RFID _{NUMBER}_:</label>
            <div class='col-md-9'>
              <input id='RFID_NUMBER' name='RFID_NUMBER' value='%RFID_NUMBER%' type='text' class='form-control'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='G2FA'>_{G2FA}_:</label>
            <div class='col-md-9'>
              <div class='form-check'>
                <input type='checkbox' class='form-check-input' id='G2FA' name='G2FA' value='%G2FA%' %G2FA_CHECKED%>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <div class='col-md-1'>
              %GPS_ROUTE_BTN%
            </div>
            <div class='col-md-1'>
              %GPS_ICON_BTN%
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class='axbills-form-main-buttons mb-3'>
    <input type=submit name=%ACTION% value='%LNG_ACTION%' ID='submitbutton' class='btn btn-primary'>
  </div>

</form>

