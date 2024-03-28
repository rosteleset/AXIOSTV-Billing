<script src='/styles/default/js/modules/ureports/sender_contact_choose.js'></script>
<script>
  var LANG = {
    NO_CONTACTS_FOR_TYPE: '_{NO_CONTACTS_FOR_TYPE}_'
  };

  var contacts_list;
  try {
    contacts_list = JSON.parse('%UID_CONTACTS%');
  } catch (Error) {
    console.log(Error);
    alert('Error while parsing contacts. Please contact support system');
  }

</script>

%MENU%

<form action='$SELF_URL' method='post' class='form-horizontal'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='UID' value='$FORM{UID}'>

  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class='card-title'>
        _{NOTIFICATIONS}_
      </h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TP_ID'>_{TARIF_PLAN}_:</label>
        <div class='col-md-8'>
          %TP_ID%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TYPE'>_{TYPE}_:</label>
        <div class='col-md-8'>
          %TYPE_SEL%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DESTINATION'>_{DESTINATION}_:</label>
        <div class='col-md-8 col-sm-8'>
          <div class='card mb-0'>
            <div class='card-body pb-0' id='DESTINATION_SELECT_WRAPPER'>
              %DESTINATION_VIEW%
            </div>
          </div>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='STATUS'>_{STATUS}_:</label>
        <div class='col-md-8'>
          %STATUS_SEL%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{REGISTRATION}_:</label>
        <div class='col-md-8'>
          %REGISTRATION%
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input type=submit class='btn btn-primary' id='SUBMIT_UREPORTS_USER' name='%ACTION%' value='%LNG_ACTION%'>
      %HISTORY_BTN%
    </div>

  </div>

  <div>%REPORTS_LIST%</div>
</form>
<script>

  var current_destination;

  try {
    current_destination = JSON.parse('%DESTINATION%');
  } catch (Error) {
    console.log(Error);
    alert('Error while parsing destinations. Please contact support system');
  }

  var type_select = jQuery('select#TYPE');
  var result_wrapper = jQuery('div#DESTINATION_SELECT_WRAPPER');

  var chooser = new ContactChooser(true, contacts_list, type_select, result_wrapper);
  chooser.setValue(current_destination);

</script>

