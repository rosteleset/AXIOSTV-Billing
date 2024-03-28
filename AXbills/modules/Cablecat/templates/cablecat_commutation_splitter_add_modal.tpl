<div class='card card-primary card-outline'>
  <div class='card-header with-border'><h5 class='card-title'>_{SPLITTERS}_</h5></div>
  <div class='card-body'>
    <form name='CABLECAT_COMMUTATION_ADD_MODAL' id='form_CABLECAT_COMMUTATION_ADD_MODAL' method='post'
          class='form form-horizontal ajax-submit-form'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='operation' value='ADD'/>
      <input type='hidden' name='entity' value='SPLITTER'/>
      <input type='hidden' name='ID' value='%COMMUTATION_ID%'/>
      <input type='hidden' name='COMMUTATION_ID' value='%COMMUTATION_ID%'/>
      <input type='hidden' name='CONNECTER_ID' value='%CONNECTER_ID%'/>

      <div class='form-group row'>
        <label for='SPLITTER_ID' class='control-label col-md-3'>_{SPLITTER}_:</label>
        <div class='col-md-9' id='SPLITTER_ID'>
          %SPLITTERS_SELECT%
        </div>
      </div>

    </form>

    <div id='splitter_form_wrapper'></div>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_CABLECAT_COMMUTATION_ADD_MODAL' id='CABLECAT_SPLITTER_ADD_BTN'
           class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

<script>
  jQuery(function () {
    Events.off('AJAX_SUBMIT.form_CABLECAT_COMMUTATION_ADD_MODAL');
    Events.on('AJAX_SUBMIT.form_CABLECAT_COMMUTATION_ADD_MODAL', function () {
      location.reload();
    });

    var select = jQuery('div#SPLITTER_ID').find('select');
    var splitter_form_wrapper = jQuery('#splitter_form_wrapper');
    var submit_add_form_btn = jQuery('input#CABLECAT_SPLITTER_ADD_BTN');

    var option_add = jQuery('<option></option>', {'value': 'add'}).text('_{CREATE}_');

    select.append(option_add);
    updateChosen();

    select.on('change', function () {
      if (jQuery(this).val() === 'add') {

        splitter_form_wrapper.load('?get_index=cablecat_splitters&header=2&add_form=1' +
          '&WELL_ID=%WELL_ID%&COMMUTATION_ID=%COMMUTATION_ID%' + '&TEMPLATE_ONLY=1', null, function () {
          // Element was replaced, so need update reference
          splitter_form_wrapper = jQuery('#splitter_form_wrapper');

          submit_add_form_btn.prop('disabled', true);
          submit_add_form_btn.addClass('disabled');

          // Change button text
          splitter_form_wrapper.find('input[type="submit"]').val('_{CREATE}_');

          // Send form in AJAX
          jQuery('#form_CABLECAT_SPLITTER').submit(ajaxFormSubmit);

          // When form sent, refresh page
          Events.off('AJAX_SUBMIT.form_CABLECAT_SPLITTER');
          Events.on('AJAX_SUBMIT.form_CABLECAT_SPLITTER', function (result) {
            if (result.MESSAGE && result.MESSAGE.message_type === 'info') {
              var new_splitter_type_select = splitter_form_wrapper.find('#TYPE_ID');

              var type_id = new_splitter_type_select.val();
              var type_name = new_splitter_type_select.find('option[value="' + type_id + '"]').text();

              select.append(
                jQuery('<option></option>', {'value': result.MESSAGE.INSERT_ID})
                  .text(type_name + '_#' + result.MESSAGE.INSERT_ID)
              );

              renewChosenValue(select, result.MESSAGE.INSERT_ID);
              splitter_form_wrapper.empty();

              submit_add_form_btn.prop('disabled', false);
              submit_add_form_btn.removeClass('disabled');

            }
          });
          initChosen();
        });

      } else {
        splitter_form_wrapper.empty();
      }


    })

  });
</script>