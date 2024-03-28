<style>
	.card-teal .card-body a {
		margin-top: .25rem;
	}
</style>

<div class='card card-form card-teal card-outline %HIDE_SUBSCRIBE_BLOCK%'>
  <div class='card-header border-0'>
    <h2 class='card-title'>
      _{BOTS}_
    </h2>
  </div>
  <div class='card-body pt-1' >
    %SUBSCRIBE_BLOCK%
  </div>
</div>


<form action='$SELF_URL' METHOD='POST' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='AWEB_OPTIONS' value='1'/>
  <input id='skin' type='hidden' name='SKIN' value='%SKIN%'/>
  <input id='body_skin' type='hidden' name='BODY_SKIN' value='%BODY_SKIN%'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{PROFILE}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{LANGUAGE}_:</label>
        <div class='col-md-9'>
          %SEL_LANGUAGE%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 control-label'>_{REFRESH}_ (sec):</label>
        <div class='col-md-3'>
          <div class='input-group'>
            <input type='text' name='REFRESH' value='$admin->{SETTINGS}{REFRESH}' class='form-control'/>
          </div>
        </div>
        <label class='col-md-3 control-label'>_{ROWS}_:</label>
        <div class='col-md-2'>
          <div class='input-group'>
            <input type='text' name='PAGE_ROWS' value='$PAGE_ROWS' class='form-control'/>
          </div>
        </div>
      </div>
      <div class='row'>
        <div class='col-md-12'>
          <h3 class='profile-username text-center'>_{EVENTS}_</h3>
          <hr>
        </div>
      </div>

      <div class='form-group row'>
        <div class='col-md-6'>
          <div class='form-group custom-control custom-checkbox'>
            <input class='custom-control-input' type='checkbox' id='NO_EVENT' name='NO_EVENT' data-checked='%NO_EVENT%'
                   value='1' data-return='1'>
            <label for='NO_EVENT' class='custom-control-label'>_{DISABLE}_</label>
          </div>
        </div>
        <div class='col-md-6'>
          <div class='form-group custom-control custom-checkbox'>
            <input class='custom-control-input' type='checkbox' id='NO_EVENT_SOUND' name='NO_EVENT_SOUND'
                   data-checked='%NO_EVENT_SOUND%' value='1' data-return='1'>
            <label for='NO_EVENT_SOUND' class='custom-control-label'>_{DISABLE}_ _{SOUND}_</label>
          </div>
        </div>
      </div>

      <hr>

      <div class='form-group row %EVENTS_GROUPS_HIDDEN%'>
        <label class='control-label col-md-3' for='GROUP'>_{GROUP}_:</label>
        <div class='col-md-9'>
          %EVENT_GROUPS_SELECT%
        </div>
      </div>

      <div class='row'>
        <div class='col-md-12'>
          <h3 class='profile-username text-center'>_{DEFAULT}_</h3>
          <hr>
        </div>
      </div>

      <div class='form-group'>
        <div class='row'>
          <div class='col-sm-12 col-md-12'>
            <a href='$SELF_URL?index=$index&reset_schema=1' class='btn btn-danger w-100'>_{RESET_SCHEMA}_</a>
          </div>
        </div>
      </div>

      <div class='row'>
        <div class='col-md-12'>
          <h3 class='profile-username text-center'>_{COLOR}_</h3>
          <hr>
        </div>
      </div>

      <div class='form-group row'>
        <div class='col-md-12'>
          <ul class='list-unstyled clearfix'>
            <li>
              <a href='javascript:void(0);' data-skin='navbar-dark navbar-primary' class='clearfix full-opacity-hover'>
                <div>
                  <span class='skin skin-logo' style='background: #222;'></span>
                  <span class='skin skin-header navbar-dark navbar-primary'></span>
                </div>
                <div>
                  <span class='skin skin-sidebar' style='background: #222;'></span>
                  <span class='skin skin-content' style='background: #f4f5f7;'></span>
                </div>
              </a>
              <p class='text-center no-margin'>Blue</p>
            </li>
            <li>
              <a href='javascript:void(0);' data-skin='navbar-dark navbar-navy' class='clearfix full-opacity-hover'>
                <div style='card-shadow: 0 0 2px rgba(0,0,0,0.1)' class='clearfix'>
                  <span class='skin skin-logo' style='background: #222;'></span>
                  <span class='skin skin-header navbar-dark navbar-navy'></span>
                </div>
                <div>
                  <span class='skin skin-sidebar' style='background: #222;'></span>
                  <span class='skin skin-content' style='background: #f4f5f7;'></span>
                </div>
              </a>
              <p class='text-center no-margin'>Black</p>
            </li>
            <li>
              <a href='javascript:void(0);' data-skin='navbar-white navbar-light' class='clearfix full-opacity-hover'>
                <div style='card-shadow: 0 0 2px rgba(0,0,0,0.1)' class='clearfix'>
                  <span class='skin skin-logo' style='background: #222;'></span>
                  <span class='skin skin-header navbar-white navbar-light'></span>
                </div>
                <div>
                  <span class='skin skin-sidebar' style='background: #222;'></span>
                  <span class='skin skin-content' style='background: #f4f5f7;'></span>
                </div>
              </a>
              <p class='text-center no-margin'>White</p>
            </li>
            <li>
              <a href='javascript:void(0);' data-skin='navbar-dark navbar-indigo' class='clearfix full-opacity-hover'>
                <div>
                  <span class='skin skin-logo' style='background: #222;'></span>
                  <span
                      class='navbar-dark navbar-indigo'
                      style='display:block; width: 80%; float: left; height: 7px;'></span>
                </div>
                <div>
                  <span style='display:block; width: 20%; float: left; height: 40px; background: #222;'></span>
                  <span style='display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;'></span>
                </div>
              </a>
              <p class='text-center no-margin'>Purple</p>
            </li>
            <li>
              <a href='javascript:void(0);' data-skin='navbar-dark navbar-success' class='clearfix full-opacity-hover'>
                <div>
                  <span class='skin skin-logo' style='background: #222;'></span>
                  <span class='navbar-dark navbar-success'
                        style='display:block; width: 80%; float: left; height: 7px;'></span>
                </div>
                <div>
                  <span style='display:block; width: 20%; float: left; height: 40px; background: #222;'></span>
                  <span style='display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;'></span>
                </div>
              </a>
              <p class='text-center no-margin'>Green</p>
            </li>
            <li>
              <a href='javascript:void(0);' data-skin='navbar-dark navbar-danger' class='clearfix full-opacity-hover'>
                <div>
                  <span class='skin skin-logo' style='background: #222;'></span>
                  <span class='navbar-dark navbar-danger'
                        style='display:block; width: 80%; float: left; height: 7px;'></span>
                </div>
                <div>
                  <span style='display:block; width: 20%; float: left; height: 40px; background: #222;'></span>
                  <span style='display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;'></span>
                </div>
              </a>
              <p class='text-center no-margin'>Red</p>
            </li>
            <li>
              <a href='javascript:void(0);' data-skin='navbar-light navbar-warning' class='clearfix full-opacity-hover'>
                <div>
                  <span class='skin skin-logo' style='background: #222;'></span>
                  <span class='navbar-light navbar-warning'
                        style='display:block; width: 80%; float: left; height: 7px;'></span>
                </div>
                <div>
                  <span style='display:block; width: 20%; float: left; height: 40px; background: #222;'></span>
                  <span style='display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;'></span>
                </div>
              </a>
              <p class='text-center no-margin'>Yellow</p>
            </li>
            <li>
              <a href='javascript:void(0);' data-skin='navbar-dark navbar-teal' class='clearfix full-opacity-hover'>
                <div>
                  <span class='skin skin-logo' style='background: #222;'></span>
                  <span
                      class='navbar-dark navbar-teal'
                      style='display:block; width: 80%; float: left; height: 7px;'></span>
                </div>
                <div>
                  <span style='display:block; width: 20%; float: left; height: 40px; background: #222;'></span>
                  <span style='display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;'></span>
                </div>
              </a>
              <p class='text-center no-margin'>Teal</p>
            </li>
            <li>
              <a href='javascript:void(0);' data-skin='navbar-light navbar-orange' class='clearfix full-opacity-hover'>
                <div style='card-shadow: 0 0 2px rgba(0,0,0,0.1)' class='clearfix'>
                  <span class='skin skin-logo' style='background: #222;'></span>
                  <span class='navbar-light navbar-orange'
                        style='display:block; width: 80%; float: left; height: 7px;'></span>
                </div>
                <div>
                  <span style='display:block; width: 20%; float: left; height: 40px; background: #222;'></span>
                  <span style='display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;'></span>
                </div>
              </a>
              <p class='text-center no-margin'>Orange</p>
            </li>
            <li>
              <a href='javascript:void(0);' data-skin='navbar-dark navbar-pink' class='clearfix full-opacity-hover'>
                <div>
                  <span class='skin skin-logo' style='background: #222;'></span>
                  <span class='navbar-dark navbar-pink'
                        style='display:block; width: 80%; float: left; height: 7px;'></span>
                </div>
                <div>
                  <span style='display:block; width: 20%; float: left; height: 40px; background: #222;'></span>
                  <span style='display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;'></span>
                </div>
              </a>
              <p class='text-center no-margin'>Pink</p>
            </li>
            <li>
              <a href='javascript:void(0);' data-skin='navbar-dark navbar-lightblue' class='clearfix full-opacity-hover'>
                <div>
                  <span class='skin skin-logo' style='background: #222;'></span>
                  <span class='navbar-dark navbar-lightblue'
                        style='display:block; width: 80%; float: left; height: 7px;'></span>
                </div>
                <div>
                  <span style='display:block; width: 20%; float: left; height: 40px; background: #222;'></span>
                  <span style='display:block; width: 80%; float: left; height: 40px; background: #f4f5f7;'></span>
                </div>
              </a>
              <p class='text-center no-margin'>Light blue</p>
            </li>
            <li>
              <a href='javascript:void(0);' data-body-skin='dark-mode' data-skin='navbar-dark' class='clearfix full-opacity-hover'>
                <div>
                  <span class='skin skin-logo' style='background: #343a40;'></span>
                  <span class='navbar-dark'
                        style='display:block; width: 80%; float: left; height: 7px;'></span>
                </div>
                <div>
                  <span style='display:block; width: 20%; float: left; height: 40px; background: #343a40;'></span>
                  <span style='display:block; width: 80%; float: left; height: 40px; background: #454d55;'></span>
                </div>
              </a>
              <p class='text-center no-margin'>Dark mode</p>
            </li>
          </ul>
        </div>
      </div>

      <div class='form-group row'>
        <div class='col-md-6'>
          <div class='form-group custom-control custom-checkbox'>
            <input class='custom-control-input' type='checkbox' id='RIGHT_MENU_HIDDEN' name='RIGHT_MENU_HIDDEN'
                   data-checked='%RIGHT_MENU_HIDDEN%' value='1' data-return='1'>
            <label for='RIGHT_MENU_HIDDEN' class='custom-control-label'>_{ALWAYS_HIDE_RIGHT_MENU}_</label>
          </div>
        </div>
        <div class='col-md-6'>
          <div class='form-group custom-control custom-checkbox'>
            <input class='custom-control-input' type='checkbox' id='LARGE_TEXT' name='LARGE_TEXT' value='1' data-return='1'>
            <label for='LARGE_TEXT' class='custom-control-label'>_{LARGE_TEXT}_</label>
          </div>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' name='set' value='_{SET}_' class='btn btn-primary'/>
    </div>
  </div>

  %AUTH_HISTORY%

  %QUICK_REPORTS%

  <div class='axbills-form-main-buttons pb-3'>
    <input type='submit' name='default' value='_{DEFAULT}_' class='btn btn-secondary'/>
    <input type='submit' name='set' value='_{SET}_' class='btn btn-primary'/>
  </div>
</form>

<style>
    ul.list-unstyled > li {
        float: left;
        width: calc(100% / 3);
        padding: 5px 5%;
    }

    ul.list-unstyled > li > a {
        display: block;
        box-shadow: 0 0 3px rgba(0, 0, 0, 0.4);
    }

    a[data-skin] .skin {
        display: block;
        float: left;
    }

    a[data-skin] span.skin-logo {
        width: 20%;
        height: 7px;
    }

    a[data-skin] span.skin-header {
        width: 80%;
        height: 7px;
    }

    a[data-skin] span.skin-sidebar {
        width: 20%;
        height: 40px;
    }

    a[data-skin] span.skin-content {
        width: 80%;
        height: 40px;
    }

</style>

<script>
  window['ENABLE_PUSH'] = '_{ENABLE_PUSH}_';
  window['DISABLE_PUSH'] = '_{DISABLE_PUSH}_';
  window['PUSH_IS_NOT_SUPPORTED'] = '_{PUSH_IS_NOT_SUPPORTED}_';
  window['PUSH_IS_DISABLED'] = '_{PUSH_IS_DISABLED}_';

  jQuery(function() {
    let largeText = jQuery('#LARGE_TEXT');

    if (localStorage.getItem('largeText') && localStorage.getItem('largeText') === 'true') largeText.prop('checked', true);

    largeText.on('change', function () {
      if (this.checked) {
        jQuery('body').removeClass('text-sm');
        localStorage.largeText = true;
      }
      else {
        jQuery('body').addClass('text-sm');
        localStorage.largeText = false;
      }
    });
  });
</script>