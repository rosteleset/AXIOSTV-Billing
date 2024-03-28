<link rel='stylesheet' type='text/css'  href='login.css'>

<div class='modal fade' id='rulesModal' tabindex='-1' role='dialog'>
  <div class='modal-dialog' role='document'>
  %RULES%
    </div>
</div><!-- /.modal -->


<div class='row'>
  <div class='col-md-6 col-md-offset-3'>
    <div class='card box-login'>
      <div class='card-header with-border'>
        <div class='row' style='display: %RULES_SHOW_STYLE%;'>
          <div class='col-md-2'>
            <button type='button' id='rules-btn' class='btn btn-success float-left' data-toggle='modal' data-target='#rulesModal'>
              _{RULES}_
            </button>
          </div>
          <hr/>
        </div>
        <div class='row' id='tabs-row'>
          <div class='col-xs-6'>
            <a href='#' class='active' id='login-form-link'>_{AUTH}_</a>
          </div>
          <div class='col-xs-6'>
            <a href='#' id='guest-form-link'>_{GUEST}_</a>
          </div>
        </div>
        <hr>
      </div>
      <div class='card-body'>
        <div class='row'>
          <div class='col-lg-12'>
            <form id='login-form' method='post' role='form'>

              <input type='hidden' name='usertype' value='Login'>
              <input type='hidden' name='ap' value='%USER_AP%'>
              <!--<input type='hidden' name='userurl' value='%USERURLDECODE%'>-->

              <div class='col-md-10 col-md-offset-1'>
                <div class='form-group'>
                  <div class='input-group'>
                                    <span class='input-group-addon'><span
                                        class='fa fa-user'></span></span>
                    <input type='text' name='username' id='username' tabindex='1'
                           class='form-control'
                           placeholder='_{LOGIN}_' value='%HOTSPOT_USERNAME%'>
                  </div>
                </div>
                <div class='form-group'>
                  <div class='input-group'>
                                    <span class='input-group-addon'><span
                                        class='fa fa-lock'></span></span>
                    <input type='password' name='password' id='password' tabindex='2'
                           class='form-control' placeholder='_{PASSWD}_' value='%HOTSPOT_PASSWORD%'>
                  </div>
                </div>
              </div>
              <div class='form-group text-center'>
                <div class='checkbox'>
                  <label>
                    <input name='remember' type='checkbox' checked> _{REMEMBER}_
                  </label>
                </div>
              </div>
              <div class='form-group'>
                <div class='row'>
                  <div class='col-sm-6'>
                    <a id='buy_card_link' tabindex='5' class='form-control btn btn-info'
                       href='$conf{BILLING_URL}/start.cgi?UNIFI_SITENAME=%UNIFI_SITENAME%&login_return_url=%RETURN_URL%'>_{BUY}_
                      _{ACCESS}_ </a>
                  </div>
                  <div class='col-sm-6'>
                    <input type='submit' id='login-submit' tabindex='4'
                           class='form-control btn btn-success' name='login-submit'
                           value='_{ENTER}_'>
                  </div>
                </div>
              </div>
            </form>

            <form id='guest-form' action='$conf{BILLING_URL}/start.cgi' method='post' role='form'
                  style='display: none;'>

              <input type='hidden' name='usertype' value='Guest'>
              <input type='hidden' name='GUEST_ACCOUNT' value='1'>
              <input type='hidden' name='mac' value='%USER_MAC%'>
              <input type='hidden' name='ap' value='%USER_AP%'>
              <input type='hidden' name='login_return_url' value='%RETURN_URL%'>
              <input type='hidden' name='UNIFI_SITENAME' value='%UNIFI_SITENAME%'>

              <div class='form-group text-center'>
                <label>$conf{HOTSPOT_GUEST_MESSAGE}</label>
              </div>
              <div class='form-group'>
                <div class='row'>
                  <div class='col-sm-6 col-sm-offset-3'>
                    <input type='submit' id='guest-submit' tabindex='4'
                           class='form-control btn btn-guest'
                           value='_{LOGON}_ _{DV}_'>
                  </div>
                </div>
              </div>
            </form>

          </div>
        </div>
      </div>
    </div>
  </div>
</div> <!-- row end -->

%EXTRA_INFO%
