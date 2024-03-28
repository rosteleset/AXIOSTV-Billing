<script src='/styles/default/js/modules/ureports/sender_contact_choose.js'></script>
<script>
  var LANG = {
    NO_CONTACTS_FOR_TYPE: '_{NO_CONTACTS_FOR_TYPE}_'
  };

  var contacts_list;
  var current_destination;
  try {
    contacts_list = JSON.parse('%UID_CONTACTS%');
    current_destination = JSON.parse('%DESTINATION%');
  } catch (Error) {
    console.log(Error);
    alert('Error while parsing contacts. Please contact support system');
  }

  jQuery(function () {
    var type_select = jQuery('select#TYPE');
    var result_wrapper = jQuery('div#DESTINATION_SELECT_WRAPPER');

    var chooser = new ContactChooser(true, contacts_list, type_select, result_wrapper);
    chooser.setValue(current_destination);
  })

</script>

%MENU%

<form action='$SELF_URL' method='post' class='form-horizontal'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='UID' value='$FORM{UID}'>
  <input type=hidden name='step' value='$FORM{step}'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{USER_INFO}_</h4>
    </div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-2 col-sm-3' for='TP_ID'>_{TARIF_PLAN}_</label>
        <div class='col-md-9 col-sm-8' id='TARIF_PLAN_WRAPPER'>
          %TP_ID% %TP_NAME%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-2 col-sm-3' for='TYPE'>_{TYPE}_</label>
        <div class='col-md-9 col-sm-8' id='TYPE_WRAPPER'>
          %TYPE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-2 col-sm-3' for='DESTINATION'>_{DESTINATION}_</label>
        <div class='col-md-9 col-sm-8'>
          <div class='card mb-0'>
            <div class='card-body pb-0' id='DESTINATION_SELECT_WRAPPER'>
              %DESTINATION_VIEW%
            </div>
          </div>
        </div>

        <div class='col-md-1 d-flex'>
          <button class='btn btn-default' id='MANUAL_EDIT_CONTACT_BTN'>
            <span class='fa fa-pencil-alt'></span>
          </button>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-2 col-sm-3' for='STATUS'>_{STATUS}_</label>
        <div class='col-md-9 col-sm-8'>
          %STATUS_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-2 col-sm-3'>_{REGISTRATION}_</label>
        <div class='col-md-9 col-sm-8'>
          <p class='form-control-static'>%REGISTRATION%</p>
        </div>
      </div>

    </div>


    <div class='card-footer'>
      <input type=submit class='btn btn-primary' id='SUBMIT_UREPORTS_USER' name='%ACTION%' value='%LNG_ACTION%'>
      %HISTORY_BTN%
    </div>

  </div>

  <div>%REPORTS_LIST%</div>

  %SERVICES_LIST%
</form>
