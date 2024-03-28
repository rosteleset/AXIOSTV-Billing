<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>%SUBMIT_BTN_ACTION% _{PLANNED_WORK}_</h4></div>
  <div class='card-body'>
        <form name='%SUBMIT_BTN_ACTION%' id='form_%SUBMIT_BTN_ACTION%' method='post' class='form form-horizontal' value='1'>
        <input type='hidden' name='index' value='$index' />
        <input type='hidden' name='ACTION' value='%ACTION%' />
        <input type='hidden' name='CREATOR' value='%CREATOR%' />
        <input type='hidden' name='DATE_OF_CREATION' value='%DATE_OF_CREATION%' />
        <input type='hidden' name='ID' value='%ID%' />
        <input type='hidden' name='MSGS_ID' value='%MSGS_ID%' />
      
      <div class='form-group'>
        <label class='control-label col-md-3' for='DATE_OF_EXECUTION_ID'>_{DATE_OF_EXECUTION}_</label>
        <div class='col-md-9'>
            %DATE_OF_EXECUTION%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='AID'>_{RESPONSIBLE}_</label>
        <div class='col-md-9'>
            %RESPONSIBLE_SELECT%
        </div>
      </div>

      <div class='form-group'>
          <label class='control-label col-md-3' for='DESCRIPTION_ID'>_{DESCRIPTION}_</label>
          <div class='col-md-9'>
              <textarea class='form-control col-md-9'  rows='5'  name='DESCRIPTION' id='DESCRIPTION_ID'>%DESCRIPTION%</textarea>
          </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='STATUS'>_{STATUS}_</label>
          <div class='col-md-9'>
            %STATUS_SELECT%
          </div>  
      </div>

<!--       <div class='form-group'>
        <label class='control-label col-md-3' for='STATUS'>_{STATUS}_</label>
        <div class='col-md-9'>
          <select class='form-control' name='STATUS'>
            %STATUS_OPTION%
          </select>
        </div>
      </div> -->

      <div class='form-group'>
        <label class='control-label col-md-3' for='BUDGET_ID'>_{BUDGET}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' value='%BUDGET%'  name='BUDGET'  id='BUDGET_ID'  />
        </div>
      </div>

      <div class='form-group'>
          <label class='control-label col-md-3' for='COMMENT_ID'>_{COMMENT}_</label>
          <div class='col-md-9'>
              <textarea class='form-control col-md-9'  rows='2'  name='COMMENT' id='COMMENT_ID'>%COMMENT%</textarea>
          </div>
      </div>

      <div class='card-footer'>

<!--         <div class='form-group'>
          <label class='control-label col-md-2' for='SUBSCRIBER'>_{SUBSCRIBER}_</label>
          <div class='col-md-10'>
                  %SUBSCRIBER_SELECT%
          </div>
        </div> -->

<!--         <div class='form-group'>
          <label class='control-label col-md-2' for='SUBSCRIBER'>_{SUBSCRIBER}_</label>
          <div class='col-md-8'>
            %SUBSCRIBER_SELECT%
          </div>
          <div class='col-md-2'>
            %WORKPLANNING_INSTALLATION_SEARCH%
          </div>
        </div> -->

        <div class='form-group'>
                <label class='col-md-3 control-label' for='USER_LOGIN'>_{SUBSCRIBER}_:</label>
                <div class='col-md-9'>
                  <input type='hidden' name='UID' id='UID_HIDDEN' value="%UID%">
                  <div class='col-md-10'>
                    <input type='text' class='form-control' id='USER_LOGIN' value="%SUBSCRIBER%" readonly='readonly'>
                  </div>
                  <div class='col-md-2'>
                    %WORKPLANNING_INSTALLATION_SEARCH% 
                  </div>
                </div>
        </div>

      %BUILDS%
      </div>

    </form>

  </div>
  <div class='card-footer'>
      <input type='submit' form='form_%SUBMIT_BTN_ACTION%' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_ACTION%'>
  </div>
</div>

<script>

  function storage_setup_search_form() {

    var search_form = jQuery('form#form-search');

    var hidden_login = search_form.find('input#LOGIN_id');
    search_form.find('select#LOGIN_SEARCH_id').on('change', function () {
      hidden_login.val(jQuery(this).val());
    });


    // Set up inner window logic
    var search_button = jQuery('button#search');
    var have_results   = jQuery('.clickSearchResult').length > 0;

    if (search_button.length) {
      search_button.on('click', function () {
        getDataURL(formURL, function () {
          defineSearchResultLogic()
        });
      });
    }

    if (have_results) {
      defineSearchResultLogic()
    }

    if (typeof (should_open_results_tab) !== 'undefined' && should_open_results_tab === '1') {
      enableResultPill();
    }
    console.log('setuop');
  }


  function defineSearchResultLogic() {
    var searchResult = jQuery('.search-result');

searchResult.off('click')
    searchResult.on('click', function () {
      aModal.hide();

    var hiddenInput = jQuery('#UID_HIDDEN');
    var loginInput  = jQuery('#USER_LOGIN');

      var login = jQuery(this).text();
      var uid   = jQuery(this).attr('data-uid');

      hiddenInput.val(uid);
      loginInput.val(login);

      aModal.destroy();
    });
  }

  jQuery(function () {
    pageInit(jQuery('form#form-search'));
    storage_setup_search_form();
  })
</script>

