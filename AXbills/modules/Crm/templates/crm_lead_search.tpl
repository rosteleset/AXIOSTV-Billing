<form name='CRM_LEAD_SEARCH' id='form_CRM_LEAD_SEARCH' method='post' class='%AJAX_SUBMIT_FORM%'>
  <input type='hidden' name='index' value='%INDEX%'/>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>
  <input type='hidden' name='ID' value='%LEAD_ID%'/>
  <input type='hidden' name='TP_ID_INPUT' id='TP_ID_INPUT' value='%TP_ID%'/>

  <div class='row'>
    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'><h4 class='card-title'>_{LEADS}_</h4></div>
        <div class='card-body'>
          <div class='form-group row' %HIDE_ID%>
            <label class='col-form-label text-md-right col-md-4' for='LEAD_ID_ID'>ID:</label>
            <div class='col-md-8'>
              <div class='input-group'>
                <input type='text' %DISABLE_ID% class='form-control' value='%LEAD_ID%' name='LEAD_ID' id='LEAD_ID_ID'/>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-form-label text-md-right col-md-4' for='FIO_ID'>_{FIO}_:</label>
            <div class='col-md-8'>
              <div class='input-group'>
                <input type='text' class='form-control' value='%FIO%' name='FIO' id='FIO_ID'/>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-form-label text-md-right col-md-4' for='PHONE_ID'>_{PHONE}_:</label>
            <div class='col-md-8'>
              <div class='input-group'>
                <input type='text' class='form-control' value='%PHONE%' name='PHONE' id='PHONE_ID'/>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-form-label text-md-right col-md-4' for='EMAIL_ID'>E-Mail:</label>
            <div class='col-md-8'>
              <div class='input-group'>
                <input type='text' class='form-control' value='%EMAIL%' name='EMAIL' id='EMAIL_ID'/>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-form-label text-md-right col-md-4' for='COMMENTS_ID'>_{COMMENTS}_:</label>
            <div class='col-md-8'>
              <div class='input-group'>
                  <textarea class='form-control col-md-12' rows='5' name='COMMENTS'
                            id='COMMENTS_ID'>%COMMENTS%</textarea>
              </div>
            </div>
          </div>

        </div>
        <div class='card-footer '>
          <input type='submit' form='form_CRM_LEAD_SEARCH' class='btn btn-primary' name='submit'
                 value='%SUBMIT_BTN_NAME%'>
        </div>
      </div>
    </div>
    <div class='col-md-6'>
      <div class='row'>

        <div class='col-md-12'>
          <div class='card card-primary card-outline collapsed-card'>
            <div class='card-header with-border'>
              <h3 class='card-title'>_{ADDRESS}_</h3>
              <div class='card-tools float-right'>
                <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                  <i class='fa fa-plus'></i>
                </button>
              </div>
            </div>
            <div class='card-body'>
              %ADDRESS_FORM%
            </div>
          </div>
        </div>

        <div class='col-md-12'>
          <div class='card card-primary card-outline collapsed-card'>
            <div class='card-header with-border'>
              <h4 class='card-title'>_{OTHER}_</h4>
              <div class='card-tools float-right'>
                <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                  <i class='fa fa-plus'></i>
                </button>
              </div>
            </div>
            <div class='card-body'>

              <div class='form-group row'>
                <label class='col-form-label text-md-right col-md-4'>_{COMPETITOR}_:</label>
                <div class='col-md-8'>
                  %COMPETITORS_SEL%
                </div>
              </div>

              <div class='form-group row hidden' id='tps-row'>
                <label class='col-form-label text-md-right col-md-4'>_{TARIF_PLAN}_:</label>
                <div class='col-md-8' id='tps-container'>
                  %TPS_SEL%
                </div>
              </div>

              <div class='form-group row hidden' id='assessment-row'>
                <label class='col-form-label text-md-right col-md-4'>_{CRM_ASSESSMENT}_:</label>
                <div class='col-md-8'>
                  %ASSESSMENTS_SEL%
                </div>
              </div>

              <div class='form-group row %HIDE_ID%'>
                <label class='control-label col-md-4'>_{STEP}_:</label>
                <div class='col-md-8'>
                  %CURRENT_STEP_SELECT%
                </div>
              </div>

              <div class='form-group row'>
                <label class='col-form-label text-md-right col-md-4' for='COMPANY_ID'>_{COMPANY}_:</label>
                <div class='col-md-8'>
                  <div class='input-group'>
                    <input type='text' class='form-control' value='%COMPANY%' name='COMPANY' id='COMPANY_ID'/>
                  </div>
                </div>
              </div>

              <div class='form-group row'>
                <label class='col-form-label text-md-right col-md-4'>_{SOURCE}_:</label>
                <div class='col-md-8'>
                  %LEAD_SOURCE%
                </div>
              </div>

              <div class='form-group row'>
                <label class='col-form-label text-md-right col-md-4'>_{HOLDUP_TO}_:</label>
                <div class='col-md-8'>
                  <div class='input-group'>
                    <div class='input-group-prepend'>
                      <span class='input-group-text'>
                        <input type='checkbox' id='HOLDUP_DATE_CHECKBOX' name='HOLDUP_DATE_CHECKBOX' class='form-control-static'
                               data-input-enables='HOLDUP_DATE_RANGE'/>
                      </span>
                    </div>
                    %HOLDUP_DATE%
                  </div>
                </div>
              </div>

            </div>
          </div>
        </div>

        <div class='col-md-12'>
          <div class='card card-primary card-outline collapsed-card'>
            <div class='card-header with-border'>
              <h3 class='card-title'>_{INFO_FIELDS}_</h3>
              <div class='card-tools float-right'>
                <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                  <i class='fa fa-plus'></i>
                </button>
              </div>
            </div>
            <div class='card-body'>
              %INFO_FIELDS%
            </div>
          </div>
        </div>

        <div class='col-md-12'>
          <div class='card card-primary card-outline collapsed-card'>
            <div class='card-header with-border'>
              <h4 class='card-title'>_{CRM_TECH}_</h4>
              <div class='card-tools float-right'>
                <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                  <i class='fa fa-plus'></i>
                </button>
              </div>
            </div>
            <div class='card-body'>


              <div class='form-group row'>
                <label class='col-form-label text-md-right col-md-4'>_{RESPOSIBLE}_:</label>
                <div class='col-md-8'>
                  <div class='input-group'>
                    %RESPONSIBLE_ADMIN%
                  </div>
                </div>
              </div>

              <div class='form-group row'>
                <label class='col-form-label text-md-right col-md-4'>_{PRIORITY}_:</label>
                <div class='col-md-8'>
                  <div class='input-group'>
                    %PRIORITY_SEL%
                  </div>
                </div>
              </div>

              <div class='form-group row'>
                <label class='col-form-label text-md-right col-md-4'>_{DATE}_:</label>
                <div class='col-md-8'>
                  <div class='input-group'>
                    <div class='input-group-prepend'>
                      <span class='input-group-text'>
                        <input type='checkbox' id='DATE_CHECKBOX' name='DATE_CHECKBOX' class='form-control-static'
                               data-input-enables='PERIOD'/>
                      </span>
                    </div>
                    %DATE%
                  </div>
                </div>
              </div>

            </div>
          </div>
        </div>

      </div>

    </div>
  </div>

</form>

<script>
  let competitors_sel = jQuery('#COMPETITOR_ID');
  let tps_container = jQuery('#tps-container');

  loadTps();

  function loadTps() {
    jQuery('#tps-row').addClass('hidden');
    jQuery('#assessment-row').addClass('hidden');

    if (!competitors_sel.val()) {
      jQuery('#TP_ID').attr('disabled', 1);
      jQuery('#ASSESSMENTS').attr('disabled', 1);
      return;
    }

    fetch('$SELF_URL?header=2&get_index=crm_competitor_tps_select&COMPETITOR_ID=' +
      competitors_sel.val() + '&TP_ID=' + (jQuery('#TP_ID_INPUT').val() || ''))
      .then(response => {
        if (!response.ok) throw response;

        return response;
      })
      .then(function (response) {
        try {
          return response.text();
        } catch (e) {
          console.log(e);
        }
      })
      .then(result => {
        jQuery('#tps-row').removeClass('hidden');
        jQuery('#assessment-row').removeClass('hidden');
        jQuery('#ASSESSMENTS').removeAttr('disabled');
        tps_container.html(result);
        initChosen();
      })
      .catch(err => {
        jQuery('#tps-row').removeClass('hidden');
        jQuery('#assessment-row').removeClass('hidden');
        jQuery('#ASSESSMENTS').removeAttr('disabled');
        console.log(err);
      });
  }
</script>