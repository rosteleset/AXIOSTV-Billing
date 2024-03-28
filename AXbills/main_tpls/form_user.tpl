<script TYPE='text/javascript'>
  'use strict';
	
	// START KTK-39
  function add_comments() {
    if (document.user_form.DISABLE.checked) {
      document.user_form.DISABLE.checked = false;

      if (document.user_form.ACTION_COMMENTS.disabled) {
        document.user_form.ACTION_COMMENTS.style.display = 'block';
        document.user_form.DISABLE.checked = true;
        document.getElementById('DISABLE_LABEL').innerHTML = '_{DISABLE}_';
      } else {
        var comments = prompt('_{COMMENTS}_', '');

        if (comments === '' || comments == null) {
          alert(_COMMENTS_PLEASE);
          document.user_form.ACTION_COMMENTS.style.display = 'none';
        } else {
          document.user_form.DISABLE.checked = true;
          document.user_form.ACTION_COMMENTS.value = comments;
          document.user_form.ACTION_COMMENTS.style.display = 'block';
          document.getElementById('DISABLE_LABEL').innerHTML = '_{DISABLE}_';
        }
      }
    } else {
      document.user_form.ACTION_COMMENTS.style.display = 'none';
      document.getElementById('DISABLE_LABEL').innerHTML = '_{ACTIV}_';
      if (!document.user_form.ACTION_COMMENTS.disabled) {
        document.user_form.ACTION_COMMENTS.value = '';
      }
    }
  }

  function add_comments_multi(e) {
    // That means 'active' so it's option without commenting and checking
    if (e.params.args.data.element.value == 0) {
      document.user_form.ACTION_COMMENTS.style.display = 'none';
      return;
    }

    if (e.params.args.data.element.value) {
      document.user_form.ACTION_COMMENTS.style.display = 'block';
      var comments = prompt('_{COMMENTS}_', '');

      if (comments === '' || comments == null) {
        e.preventDefault();
        alert(_COMMENTS_PLEASE);
        if (document.user_form.DISABLE.value == 0) {
          document.user_form.ACTION_COMMENTS.style.display = 'none';
        }
      } else {
        document.user_form.ACTION_COMMENTS.value = comments;
        document.user_form.ACTION_COMMENTS.style.display = 'block';
      }
    }
  }

  jQuery(function () {
    if (jQuery('#CUSTOM_DISABLE_FORM').length) {
      jQuery('#DISABLE_FORM').remove();
    }

    if (
      document.user_form.DISABLE.checked ||
      (document.user_form.DISABLE.checked === undefined &&
        document.user_form.DISABLE.value != 0)
    ) {
      document.user_form.ACTION_COMMENTS.style.display = 'block';
      document.user_form.ACTION_COMMENTS.disabled = true;
    } else {
      document.user_form.ACTION_COMMENTS.style.display = 'none';
    }

    jQuery('input#DISABLE').on('click', add_comments);  //XXX fix input#DISABLE in form_user_lite, add h-0-18 to it.
    jQuery('select#DISABLE').on('select2:selecting', add_comments_multi);
	// END KTK-39

    jQuery('#create_company').on('click', function () {
      if (this.checked) {
        var company_name_input = jQuery('<input/>', {
          'class': 'form-control',
          name: 'COMPANY_NAME',
          id: 'COMPANY_NAME'
        });
        jQuery('#create_company_wrapper').after(company_name_input);
        jQuery('#COMPANY_NAME').wrap("<div class='col-md-6 col-xs-12' id='company_name_wrapper'></div>");
      } else {
        jQuery('#company_name_wrapper').remove();
      }
    });

    if (jQuery('#create_company_id').val() == 1) {
      var company_name_input = jQuery('<input/>', {'class': 'form-control', name: 'COMPANY_NAME', id: 'COMPANY_NAME'});

      jQuery('#create_company').attr('checked', 'checked')
      jQuery('#create_company_wrapper').after(company_name_input);
      jQuery('#COMPANY_NAME').wrap("<div class='col-md-6 col-xs-12' id='company_name_wrapper'></div>");

      jQuery('#COMPANY_NAME').val(
        jQuery('#company_name').val()
      );
    }

    jQuery('#LOGIN').on('input', function () {
      var value = jQuery('#LOGIN').val();
      doDelayedSearch(value)
    });
  });

  var timeout = null;
  var next_disable = 1;

  function doDelayedSearch(val) {
    if (timeout) {
      clearTimeout(timeout);
    }
    timeout = setTimeout(function () {
      doSearch(val);
    }, 500);
  }

  function doSearch(val) {
    if (!val) {
      jQuery('#LOGIN').removeClass('is-valid').addClass('is-invalid');
      return 1;
    }
    jQuery.post('$SELF_URL', 'header=2&get_index=' + 'check_login_availability' + '&login_check=' + val, function (data) {
      if (data === 'success') {
        jQuery('#LOGIN').removeClass('is-invalid').addClass('is-valid');
        jQuery('input[name=next]').removeAttr('disabled', 'disabled');
        next_disable = 1;
        validate_after_login();
      } else {
        jQuery('#LOGIN').removeClass('is-valid').addClass('is-invalid');
        jQuery('input[name=next]').attr('disabled', 'disabled');
        next_disable = 2;
      }
    });
  }

</script>

<form action='$SELF_URL' method='post' id='user_form' name='user_form' role='form'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='COMPANY_ID' value='%COMPANY_ID%'>
  <input type=hidden name='step' value='$FORM{step}'>
  <input type=hidden name='NOTIFY_FN' value='%NOTIFY_FN%'>
  <input type=hidden name='NOTIFY_ID' value='%NOTIFY_ID%'>
  <input type=hidden name='TP_ID' value='%TP_ID%'>
  <input type=hidden name='REFERRAL_REQUEST' value='%REFERRAL_REQUEST%'>
  <input type=hidden name='create_company_id' id='create_company_id' value='$FORM{company}'>
  <input type=hidden name='company_name' id='company_name' value='$FORM{company_name}'>

  <div id='form_1' class='card card-primary card-outline container-md for_sort pr-0 pl-0'> <!-- XXX card-big-form? -->
    <div class='card-header with-border'>
      <h4 class='card-title'>_{USER_ACCOUNT}_</h4>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>
							 
      %EXDATA%

      <div class='form-group row'>
        <label class='col-4 col-md-2 col-form-label text-right mb-3 mb-md-0' for='CREDIT'>_{CREDIT}_:</label>
        <div class='col-8 col-md-4 mb-3 mb-md-0'>
          <input id='CREDIT' name='CREDIT' value='%CREDIT%' placeholder='%CREDIT%' class='form-control r-0-9'
                 type='number' step='0.01' min='0'
                 data-tooltip='<h6>_{SUM}_:  %CREDIT%</h6><h6>_{DATE}_: %DATE_CREDIT%</h6>'
                 data-tooltip-position='top'>
          <!-- XXX tooltip shows every time, even if it is not needed. look at TOOLTIP_DISABLE. look at this tooltip at form_user_lite-->
        </div>

        <label class='col-4 col-md-2 col-form-label text-right' for='CREDIT_DATE'>_{TO}_:</label>
        <div class='col-8 col-md-4'>
          <input id='CREDIT_DATE' type='text' name='CREDIT_DATE' value='%CREDIT_DATE%'
                 class='datepicker form-control d-0-9'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-4 col-md-2 col-form-label text-right mb-3 mb-md-0' for='REDUCTION'>_{REDUCTION}_:</label>
        <div class='col-8 col-md-4 mb-3 mb-md-0'>
          <input id='REDUCTION' name='REDUCTION' value='%REDUCTION%' placeholder='%REDUCTION%'
                 class='form-control r-0-11'
                 type='number ' min='0' max='100' step='0.01'>
        </div>

        <label class='col-4 col-md-2 col-form-label text-right' for='REDUCTION_DATE'>_{TO}_:</label>
        <div class='col-8 col-md-4'>
          <input id='REDUCTION_DATE' type='text' name='REDUCTION_DATE' value='%REDUCTION_DATE%'
                 class='datepicker form-control d-0-11'>
        </div>
      </div>

      <div id='DISABLE_FORM' class='form-group row h-0-18 %DISABLE_COLOR%' %HIDE_DISABLE_FORM%>
        <label class='col-form-label text-right col-4 col-md-2' for='DISABLE'>_{DISABLE}_:</label>
        <div class='col-1 col-md-1'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='DISABLE' name='DISABLE' value='1'
                   data-checked='%DISABLE%'>
            %FORM_DISABLE%
          </div>
        </div>
        <div class='col-7 col-md-9'>
          <input id='ACTION_COMMENTS'
                 name='ACTION_COMMENTS'
                 value='%DISABLE_COMMENTS%'
                 class='form-control mt-2'
                 type='text'
                 style='display: none;'>
        </div>
      </div>

      <div %HIDE_PASSWORD% class='text-center'>%PASSWORD% %DEPOSIT_MESSAGE%</div>
    </div>

    <div class='card card-outline card-big-form collapsed-card mb-0 border-top'>
      <div class='card-header with-border'>
        <h3 class='card-title'>_{EXTRA}_</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'>
            <i class='fa fa-plus'></i>
          </button>
        </div>
      </div>

      <div class='card-body'>
        <div class='form-group row' %HIDE_COMPANY%>
          <label class='col-sm-2 col-form-label' for='COMP'>_{COMPANY}_</label>
          <div class='col-sm-10'>
            <div class='input-group'>
              <input type='text' name='COMP' value='%COMPANY_NAME%' ID='COMP' class='form-control' readonly>
              <div class='input-group-append'>
                <a class='btn input-group-button' href='$SELF_URL?index=13&COMPANY_ID=%COMPANY_ID%'>
                  <i class='fa fa-arrow-left'></i>
                </a>
                <a class='btn input-group-button' href='$SELF_URL?index=21&UID=$FORM{UID}'>
                  <i class='fa fa-pencil-alt'></i>
                </a>
              </div>
            </div>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-md-2 col-sm-2 col-form-label' for='ACTIVATE'>_{ACTIVATE}_</label>
          <div class='col-md-4 col-sm-10'>
            <input id='ACTIVATE' name='ACTIVATE' value='%ACTIVATE%' placeholder='%ACTIVATE%'
                   class='form-control datepicker d-0-19' type='text'>
          </div>
          <label class='col-md-2 col-sm-2 col-form-label' for='EXPIRE'>_{EXPIRE}_</label>
          <div class='col-md-4 col-sm-10'>
            <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%'
                   class='form-control datepicker d-0-20' type='text'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-md-2 col-sm-2 col-form-label' for='BILL'>_{BILL}_</label>
          <div class='col-md-4 col-sm-10'>
            <div class='input-group'>
              <input type=text name='BILL' value='%BILL_ID%' ID='BILL' class='form-control' readonly>
              <div class='input-group-append'>
                %BILL_CORRECTION%
              </div>
            </div>
          </div>

          <label class='col-md-2 col-sm-2 col-form-label' for='REG'>_{REGISTRATION}_</label>
          <div class='col-md-4 col-sm-10'>
            <input type='text' name='REG' value='%REGISTRATION%' ID='REG' class='form-control' readonly>
          </div>
        </div>

      </div>
    </div>

    <div class='card-footer'>
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary double_click_check'>
    </div>
  </div>
</form>
