<form class='form-horizontal' action='$SELF_URL' name='users_pi' METHOD='POST' ENCTYPE='multipart/form-data'>

  <input type='hidden' name='index' value='$index'>
  %MAIN_USER_TPL%
  <input type=hidden name=UID value='%UID%'>

  <!-- General panel -->
  <div id='form_2' class='card card-big-form card-primary card-outline for_sort'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{INFO}_</h3>
      <div class='card-tools float-right'>
        %EDIT_BUTTON%
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>
      <div class='row'>
        <div class='col-sm-12 col-md-12'>
          <div class='form-group row'>
            <label class='col-sm-2 col-md-4 col-form-label'>_{FIO}_</label>
            <div class='col-sm-10 col-md-8'>
              <div class='input-group'>
                <input class='form-control' type='text' readonly value='%FIO%' placeholder='_{FIO}_'>
                <div class='input-group-append'>
                  <div class='input-group-text'>
                    <span class='fa fa-user'></span>
                  </div>
                </div>
                <div class='input-group-append'>
                  <a href='$SELF_URL?UID=$FORM{UID}&get_index=msgs_admin&add_form=1&SEND_TYPE=1&header=1&full=1'
                     class='btn input-group-button'>
                    <i class='fa fa-envelope'></i>
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='row'>
        <div class='col-sm-12 col-md-12'>
          <div class='form-group row'>
            <label class='col-sm-2 col-md-4 col-form-label'>_{ADDRESS}_</label>
            <div class='col-sm-10 col-md-8'>
              <div class='input-group'>
                <input class='form-control' type='text' readonly value='%ADDRESS_STR%' placeholder='_{ADDRESS}_'>
                <div class='input-group-append'>
                  <!-- TODO: RECHECK PLEASE -->
                  %MAP_BTN%
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='row'>
        <div class='col-sm-12 col-md-12'>
          <div class='form-group row'>
            <label class='col-sm-2 col-md-4 col-form-label'>_{PHONE}_</label>
            <div class='col-sm-10 col-md-8'>
              <div class='input-group'>
                <input class='form-control' type='text' readonly value='%PHONE%' placeholder='_{PHONE}_'>
                <div class='input-group-append'>
                  <div class='input-group-text'>
                    <span class='fa fa-phone'></span>
                  </div>
                </div>
                <div class='input-group-append'>
                  <a href='%CALLTO_HREF%' class='btn input-group-button'>
                    <i class='fa fa-list'></i>
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='row'>
        <div class='col-sm-12 col-md-12'>
          <div class='form-group row'>
            <label class='col-sm-2 col-md-4 col-form-label'>_{COMMENTS}_</label>
            <div class='col-sm-10 col-md-8'>
              <div class='input-group'>
                <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='2' readonly>%COMMENTS%</textarea>
                <div class='input-group-append'>
                  <div class='input-group-text'>
                    <span class='align-middle fa fa-user'></span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Pasport panel -->
    <div class='card collapsed-card mb-0 border-top card-outline'>
      <div class='card-header with-border'>
        <h3 class='card-title'>_{PASPORT}_</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>
        <div class='form-group row'>
          <label class='col-sm-2 col-form-label' for='PASPORT_NUM'>_{NUM}_</label>
          <div class='col-sm-10'>
            <div class='input-group'>
              <input id='PASPORT_NUM' name='PASPORT_NUM' value='%PASPORT_NUM%'
                     placeholder='%PASPORT_NUM%'
                     class='form-control' type='text' readonly>
            </div>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-sm-2 col-form-label' for='PASPORT_DATE'>_{DATE}_</label>
          <div class='col-sm-10'>
            <div class='input-group'>
              <input id='PASPORT_DATE' type='text' name='PASPORT_DATE' value='%PASPORT_DATE%'
                     class='datepicker form-control' disabled>
            </div>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-sm-2 col-form-label' for='PASPORT_GRANT'>_{GRANT}_</label>
          <div class='col-sm-10'>
            <div class='input-group'>
                <textarea class='form-control' id='PASPORT_GRANT' name='PASPORT_GRANT'
                          rows='2' readonly>%PASPORT_GRANT%</textarea>
            </div>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-sm-2 col-form-label' for='BIRTH_DATE'>_{BIRTH_DATE}_</label>
          <div class='col-sm-10'>
            <div class='input-group'>
              <input class='form-control datepicker' id='BIRTH_DATE' name='BIRTH_DATE'
                     type='text' value='%BIRTH_DATE%' disabled>
            </div>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-sm-2 col-form-label' for='TAX_NUMBER'>_{TAX_NUMBER}_</label>
          <div class='col-sm-10'>
            <div class='input-group'>
              <input id='TAX_NUMBER' name='TAX_NUMBER' value='%TAX_NUMBER%'
                     placeholder='%TAX_NUMBER%'
                     class='form-control' type='text' readonly>
            </div>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-2 col-form-label' for='REG_ADDRESS'>_{REG_ADDRESS}_</label>
          <div class='col-sm-10'>
            <div class='input-group'>
                <textarea class='form-control' id='REG_ADDRESS' name='REG_ADDRESS'
                          rows='2' readonly>%REG_ADDRESS%</textarea>
            </div>
          </div>
        </div>
      </div>
    </div>

    %DOCS_TEMPLATE%

    <div class='card collapsed-card mb-0 border-top card-outline'>
      <div class='card-header with-border'>
        <h3 class='card-title'>_{EXTRA_ABBR}_. _{FIELDS}_</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>
        <fieldset id='info_fields'>
          %INFO_FIELDS%
        </fieldset>
      </div>
    </div>
  </div>
</form>

<script>
  'use strict';
  jQuery(function () {
    jQuery('#info_fields').find('select').prop('disabled', true).trigger('chosen:updated');
  })
</script>
<style>
	#info_fields div.chosen-disabled {
		opacity: 1 !important;
	}

	#info_fields .chosen-disabled a.chosen-single {
		cursor: not-allowed;
	}
</style>
