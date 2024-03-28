<form action='%SELF_URL%' name='users_pi' METHOD='POST' ENCTYPE='multipart/form-data'>

  <input type='hidden' name='index' value='$index'>
  <input type=hidden name=UID value='%UID%'>

  <div class='%FORM_ATTR%'>
    %MAIN_USER_TPL%
  </div>
  <div id='form_2' class='card for_sort card-primary card-outline %FORM_ATTR%'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{INFO}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i>
        </button>
      </div>
    </div>

    <div class='card-body'>
      <div class='form-group row' id='simple_fio'>
        <label class='col-sm-3 col-md-2 text-right control-label %FIO_REQ%' for='FIO'>_{FIO}_:</label>
        <div class='col-sm-9 col-md-10'>
          <div class='input-group'>
            <input name='FIO' class='form-control' %FIO_REQ% %FIO_READONLY% id='FIO' value='%FIO%'>
            <div class='input-group-append'>
              <button id='show_fio' type='button' class='btn btn-default' tabindex='-1'>
                <i class='fa fa-bars'></i>
              </button>
            </div>
          </div>
        </div>
      </div>

      <div id='full_fio' style='display:none'>
        <div class='form-group row'>
          <label class='col-form-label text-md-right col-md-4' for='FIO1'>_{FIO1}_:</label>
          <div class='col-sm-8 col-md-8'>
            <div class='input-group'>
              <input name='FIO1' class='form-control' id='FIO1' value='%FIO1%'>
              <div class='input-group-append'>
                <button id='hide_fio' type='button' class='btn btn-default' tabindex='-1'>
                  <i class='fa fa-reply'></i>
                </button>
              </div>
            </div>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-form-label text-md-right col-md-4' for='FIO2'>_{FIO2}_:</label>
          <div class='col-sm-8 col-md-8'>
            <div class='input-group'>
              <input name='FIO2' class='form-control' id='FIO2' value='%FIO2%'>
            </div>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-form-label text-md-right col-md-4' for='FIO3'>_{FIO3}_:</label>
          <div class='col-sm-8 col-md-8'>
            <div class='input-group'>
              <input name='FIO3' class='form-control' id='FIO3' value='%FIO3%'>
            </div>
          </div>
        </div>
      </div>
    </div>

    %CONTACTS%
    %ADDRESS_TPL%

    <div class='card card-outline card-big-form collapsed-card mb-0 border-top'>
      <div class='card-header with-border'>
        <h3 class='card-title'>_{PASPORT}_</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'>
            <i class='fa fa-plus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>
        <div class='form-group row'>
          <label class='col-sm-3 col-md-2 control-label' for='PASPORT_NUM'>_{NUM}_:</label>
          <div class='col-sm-9 col-md-4'>
            <div class='input-group'>
              <input id='PASPORT_NUM' name='PASPORT_NUM' value='%PASPORT_NUM%'
                placeholder='%PASPORT_NUM%'
                class='form-control' type='text'>
            </div>
          </div>
          <label class='col-sm-3 col-md-2 control-label' for='PASPORT_DATE'>_{DATE}_:</label>
          <div class='col-sm-9 col-md-4'>
            <div class='input-group'>
              <input id='PASPORT_DATE' type='text' name='PASPORT_DATE' value='%PASPORT_DATE%'
                class='datepicker form-control'>
            </div>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-3 col-md-2 control-label' for='PASPORT_GRANT'>_{GRANT}_:</label>
          <div class='col-sm-9 col-md-10'>
            <div class='input-group'>
              <textarea class='form-control' id='PASPORT_GRANT' name='PASPORT_GRANT' rows='2'>%PASPORT_GRANT%</textarea>
            </div>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-sm-3 col-md-2 control-label' for='BIRTH_DATE'>_{BIRTH_DATE}_:</label>
          <div class='col-sm-9 col-md-4'>
            <div class='input-group'>
              <input class='form-control datepicker' id='BIRTH_DATE' name='BIRTH_DATE'
                type='text' value='%BIRTH_DATE%'>
            </div>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-sm-3 col-md-2 control-label' for='REG_ADDRESS'>_{REG_ADDRESS}_:</label>
          <div class='col-sm-9 col-md-10'>
            <div class='input-group'>
              <textarea class='form-control' id='REG_ADDRESS' name='REG_ADDRESS' rows='2'>%REG_ADDRESS%</textarea>
            </div>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-sm-3 col-md-2 control-label' for='TAX_NUMBER'>_{TAX_NUMBER}_:</label>
          <div class='col-sm-9 col-md-10'>
            <div class='input-group'>
              <input id='TAX_NUMBER' name='TAX_NUMBER' value='%TAX_NUMBER%'
                     placeholder='%TAX_NUMBER%'
                     class='form-control' type='text'>
            </div>
          </div>
        </div>
      </div>
    </div>

    %DOCS_TEMPLATE%

    <!-- Other panel  -->
    <div class='card card-outline card-big-form collapsed-card mb-0 border-top'>
      <div class='card-header with-border'>
        <h3 class='card-title'>_{EXTRA_ABBR}_. _{FIELDS}_</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>
        %INFO_FIELDS%
      </div>
    </div>

    <div class='form-group row mt-3 mr-3 ml-3'>
      <div class='input-group'>
        <textarea class='form-control' id='COMMENTS' placeholder='_{COMMENTS}_' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
      </div>
    </div>

    <div class='card-footer'>
      <input type=submit class='btn btn-primary double_click_check hidden_empty_required_filed_check' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>

</form>

<script type='text/javascript'>
  jQuery('#show_fio').click(function() {
    jQuery('#simple_fio').addClass('d-none');
    jQuery('#full_fio').css('display', 'block');
  });

  jQuery('#hide_fio').click(function() {
    jQuery('#simple_fio').removeClass('d-none');
    jQuery('#full_fio').css('display', 'none');
  });
</script>
