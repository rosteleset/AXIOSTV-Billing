<!-- Tab panes -->
<form action='$SELF_URL' method='post' id='FORM_ADMIN_QUICK_SETTINGS'>
  <input type='hidden' name='index' value='%INDEX%'/>
  <input type='hidden' name='AWEB_OPTIONS' value='1'/>
  <input type='hidden' name='SKIN' value='%SKIN%' id='skin'/>
  <input type='hidden' name='QUICK' value='1'/>

  <h4 class='control-sidebar-heading'>_{PROFILE}_</h4>
  <div class='form-group'>
    <label class='control-sidebar-subheading'>_{LANGUAGE}_
      <p>%SEL_LANGUAGE%</p>
    </label>
  </div>
  <div class='form-group'>
    <label class='control-sidebar-subheading'>
      _{ROWS}_
      <input type='text' name='PAGE_ROWS' value='$PAGE_ROWS' class='form-control'/>
    </label>
  </div>
  <h4 class='control-sidebar-heading'>_{EVENTS}_</h4>

  <div class="row">
    <div class="col-md-12">
      <div class="btn-group-vertical">
        %SUBSCRIBE_BLOCK%
      </div>
    </div>
  </div>
  <div class='form-group'>
    <label class='control-sidebar-subheading'>
      _{DISABLE}_
      <input type='checkbox' class='float-right' data-return='1' name='NO_EVENT'
             value='1' data-checked='%NO_EVENT%'/>
    </label>
  </div>
  <div class='form-group'>
    <label class='control-sidebar-subheading'>
      _{DISABLE}_ _{SOUND}_
      <input type='checkbox' class='float-right' data-return='1'
             name='NO_EVENT_SOUND' value='1' data-checked='%NO_EVENT_SOUND%'/>
    </label>
  </div>
  <h4 class='control-sidebar-heading'>_{VIEW}_</h4>
  <div class='form-group'>
    <label class='control-sidebar-subheading'>
      _{LIGHT_SKIN_MENU}_
      <input type='checkbox' data-sidebarskin='toggle' class='float-right' data-return='1'
             name='MENU_SKIN' value='1' data-checked='%MENU_SKIN%'/>
    </label>
  </div>
  <input type="hidden" name="FIXED" value="0"/>
  <!--    <div class='form-group'>
          <label class='control-sidebar-subheading'>
              _{FIXED_LAYOUT}_
              <input type='checkbox' data-layout='fixed' class='float-right' data-return='1'
                     name='FIXED' value='1' data-checked='%FIXED%'/>
          </label>
      </div>-->
  <div class='form-group'>
    <label class='control-sidebar-subheading'>
      _{FIXED_HEADER}_
      <input type='checkbox' data-header='fixed' class='float-right' data-return='1'
             name='HEADER_FIXED' value='1' data-checked='%HEADER_FIXED%'/>
    </label>
  </div>
  <div class='form-group'>
    <label class='control-sidebar-subheading'>
      _{ALWAYS_HIDE_RIGHT_MENU}_
      <input type='checkbox' class='float-right' data-return='1'
             name='RIGHT_MENU_HIDDEN' value='1' data-checked='%RIGHT_MENU_HIDDEN%'/>
    </label>
  </div>
  <ul class='list-unstyled clearfix'>
    <li style='float:left; width: 33.33333%; padding: 5px;'><a href='javascript:void(0);' data-skin='skin-blue'
                                                               style='display: block; box-shadow: 0 0 3px rgba(0,0,0,0.4)'
                                                               class='clearfix full-opacity-hover'>
      <div><span
          style='display:block; width: 20%; float: left; height: 7px; background: #367fa9;'></span><span
          class='bg-light-blue' style='display:block; width: 80%; float: left; height: 7px;'></span></div>
      <div><span
          style='display:block; width: 20%; float: left; height: 20px; background: #222;'></span><span
          style='display:block; width: 80%; float: left; height: 20px; background: #f4f5f7;'></span></div>
    </a>
      <p class='text-center no-margin'>Blue</p></li>
    <li style='float:left; width: 33.33333%; padding: 5px;'><a href='javascript:void(0);' data-skin='skin-black'
                                                               style='display: block; box-shadow: 0 0 3px rgba(0,0,0,0.4)'
                                                               class='clearfix full-opacity-hover'>
      <div style='card-shadow: 0 0 2px rgba(0,0,0,0.1)' class='clearfix'><span
          style='display:block; width: 20%; float: left; height: 7px; background: #fefefe;'></span><span
          style='display:block; width: 80%; float: left; height: 7px; background: #fefefe;'></span></div>
      <div><span style='display:block; width: 20%; float: left; height: 20px; background: #222;'></span><span
          style='display:block; width: 80%; float: left; height: 20px; background: #f4f5f7;'></span></div>
    </a>
      <p class='text-center no-margin'>White</p></li>
    <li style='float:left; width: 33.33333%; padding: 5px;'><a href='javascript:void(0);'
                                                               data-skin='skin-purple'
                                                               style='display: block; box-shadow: 0 0 3px rgba(0,0,0,0.4)'
                                                               class='clearfix full-opacity-hover'>
      <div><span style='display:block; width: 20%; float: left; height: 7px;'
                 class='bg-purple-active'></span><span
          class='bg-purple' style='display:block; width: 80%; float: left; height: 7px;'></span></div>
      <div><span
          style='display:block; width: 20%; float: left; height: 20px; background: #222;'></span><span
          style='display:block; width: 80%; float: left; height: 20px; background: #f4f5f7;'></span></div>
    </a>
      <p class='text-center no-margin'>Purple</p></li>
    <li style='float:left; width: 33.33333%; padding: 5px;'><a href='javascript:void(0);' data-skin='skin-green'
                                                               style='display: block; box-shadow: 0 0 3px rgba(0,0,0,0.4)'
                                                               class='clearfix full-opacity-hover'>
      <div><span style='display:block; width: 20%; float: left; height: 7px;'
                 class='bg-green-active'></span><span class='bg-green'
                                                      style='display:block; width: 80%; float: left; height: 7px;'></span>
      </div>
      <div><span
          style='display:block; width: 20%; float: left; height: 20px; background: #222;'></span><span
          style='display:block; width: 80%; float: left; height: 20px; background: #f4f5f7;'></span></div>
    </a>
      <p class='text-center no-margin'>Green</p></li>
    <li style='float:left; width: 33.33333%; padding: 5px;'><a href='javascript:void(0);' data-skin='skin-red'
                                                               style='display: block; box-shadow: 0 0 3px rgba(0,0,0,0.4)'
                                                               class='clearfix full-opacity-hover'>
      <div><span style='display:block; width: 20%; float: left; height: 7px;'
                 class='bg-red-active'></span><span class='bg-red'
                                                    style='display:block; width: 80%; float: left; height: 7px;'></span>
      </div>
      <div><span
          style='display:block; width: 20%; float: left; height: 20px; background: #222;'></span><span
          style='display:block; width: 80%; float: left; height: 20px; background: #f4f5f7;'></span></div>
    </a>
      <p class='text-center no-margin'>Red</p></li>
    <li style='float:left; width: 33.33333%; padding: 5px;'><a href='javascript:void(0);'
                                                               data-skin='skin-yellow'
                                                               style='display: block; box-shadow: 0 0 3px rgba(0,0,0,0.4)'
                                                               class='clearfix full-opacity-hover'>
      <div><span style='display:block; width: 20%; float: left; height: 7px;'
                 class='bg-yellow-active'></span><span
          class='bg-yellow' style='display:block; width: 80%; float: left; height: 7px;'></span></div>
      <div><span
          style='display:block; width: 20%; float: left; height: 20px; background: #222;'></span><span
          style='display:block; width: 80%; float: left; height: 20px; background: #f4f5f7;'></span></div>
    </a>
      <p class='text-center no-margin'>Yellow</p></li>
    <li style='float:left; width: 33.33333%; padding: 5px;'><a href='javascript:void(0);'
                                                               data-skin='skin-blue-light'
                                                               style='display: block; box-shadow: 0 0 3px rgba(0,0,0,0.4)'
                                                               class='clearfix full-opacity-hover'>
      <div><span
          style='display:block; width: 20%; float: left; height: 7px; background: #367fa9;'></span><span
          class='bg-light-blue' style='display:block; width: 80%; float: left; height: 7px;'></span></div>
      <div><span
          style='display:block; width: 20%; float: left; height: 20px; background: #f9fafc;'></span><span
          style='display:block; width: 80%; float: left; height: 20px; background: #f4f5f7;'></span></div>
    </a>
      <p class='text-center no-margin' style='font-size: 12px'>Blue Light</p></li>
    <li style='float:left; width: 33.33333%; padding: 5px;'><a href='javascript:void(0);'
                                                               data-skin='skin-black-light'
                                                               style='display: block; box-shadow: 0 0 3px rgba(0,0,0,0.4)'
                                                               class='clearfix full-opacity-hover'>
      <div style='card-shadow: 0 0 2px rgba(0,0,0,0.1)' class='clearfix'><span
          style='display:block; width: 20%; float: left; height: 7px; background: #fefefe;'></span><span
          style='display:block; width: 80%; float: left; height: 7px; background: #fefefe;'></span></div>
      <div><span
          style='display:block; width: 20%; float: left; height: 20px; background: #f9fafc;'></span><span
          style='display:block; width: 80%; float: left; height: 20px; background: #f4f5f7;'></span></div>
    </a>
      <p class='text-center no-margin' style='font-size: 12px'>Black Light</p></li>
    <li style='float:left; width: 33.33333%; padding: 5px;'><a href='javascript:void(0);'
                                                               data-skin='skin-purple-light'
                                                               style='display: block; box-shadow: 0 0 3px rgba(0,0,0,0.4)'
                                                               class='clearfix full-opacity-hover'>
      <div><span style='display:block; width: 20%; float: left; height: 7px;'
                 class='bg-purple-active'></span><span
          class='bg-purple' style='display:block; width: 80%; float: left; height: 7px;'></span></div>
      <div><span
          style='display:block; width: 20%; float: left; height: 20px; background: #f9fafc;'></span><span
          style='display:block; width: 80%; float: left; height: 20px; background: #f4f5f7;'></span></div>
    </a>
      <p class='text-center no-margin' style='font-size: 12px'>Purple Light</p></li>
    <li style='float:left; width: 33.33333%; padding: 5px;'><a href='javascript:void(0);'
                                                               data-skin='skin-green-light'
                                                               style='display: block; box-shadow: 0 0 3px rgba(0,0,0,0.4)'
                                                               class='clearfix full-opacity-hover'>
      <div><span style='display:block; width: 20%; float: left; height: 7px;'
                 class='bg-green-active'></span><span class='bg-green'
                                                      style='display:block; width: 80%; float: left; height: 7px;'></span>
      </div>
      <div><span
          style='display:block; width: 20%; float: left; height: 20px; background: #f9fafc;'></span><span
          style='display:block; width: 80%; float: left; height: 20px; background: #f4f5f7;'></span></div>
    </a>
      <p class='text-center no-margin' style='font-size: 12px'>Green Light</p></li>
    <li style='float:left; width: 33.33333%; padding: 5px;'><a href='javascript:void(0);'
                                                               data-skin='skin-red-light'
                                                               style='display: block; box-shadow: 0 0 3px rgba(0,0,0,0.4)'
                                                               class='clearfix full-opacity-hover'>
      <div><span style='display:block; width: 20%; float: left; height: 7px;'
                 class='bg-red-active'></span><span class='bg-red'
                                                    style='display:block; width: 80%; float: left; height: 7px;'></span>
      </div>
      <div><span
          style='display:block; width: 20%; float: left; height: 20px; background: #f9fafc;'></span><span
          style='display:block; width: 80%; float: left; height: 20px; background: #f4f5f7;'></span></div>
    </a>
      <p class='text-center no-margin' style='font-size: 12px'>Red Light</p></li>
    <li style='float:left; width: 33.33333%; padding: 5px;'><a href='javascript:void(0);'
                                                               data-skin='skin-yellow-light'
                                                               style='display: block; box-shadow: 0 0 3px rgba(0,0,0,0.4)'
                                                               class='clearfix full-opacity-hover'>
      <div><span style='display:block; width: 20%; float: left; height: 7px;'
                 class='bg-yellow-active'></span><span
          class='bg-yellow' style='display:block; width: 80%; float: left; height: 7px;'></span></div>
      <div><span
          style='display:block; width: 20%; float: left; height: 20px; background: #f9fafc;'></span><span
          style='display:block; width: 80%; float: left; height: 20px; background: #f4f5f7;'></span></div>
    </a>
      <p class='text-center no-margin' style='font-size: 12px;'>Yellow Light</p></li>
  </ul>
  <button type='submit' class='btn btn-success btn-block btn-flat'>_{APPLY}_</button>
</form>
<!-- /.tab-pane -->

<script>

  window['ENABLE_PUSH']           = '_{ENABLE_PUSH}_';
  window['DISABLE_PUSH']          = '_{DISABLE_PUSH}_';
  window['PUSH_IS_NOT_SUPPORTED'] = '_{PUSH_IS_NOT_SUPPORTED}_';
  window['PUSH_IS_DISABLED']      = '_{PUSH_IS_DISABLED}_';

  jQuery(function () {
    // Sending form as AJAX request, to prevent tab reloading
    var form_id = 'FORM_ADMIN_QUICK_SETTINGS';
    var form    = jQuery('form#' + form_id);

    var submit_btn = form.find('button[type="submit"]');

    form.on('submit', function (e) {
      e.preventDefault();
      // Read form data to string
      var formData = form.serialize();

      // Disable button to prevent multiple submits
      submit_btn.prop('disabled', true);

      //Send data
      jQuery.post('/admin/index.cgi', formData, function () {
        jQuery('.generated-checkbox').remove();
        submit_btn.prop('disabled', false);
      });
    });
  });
</script>