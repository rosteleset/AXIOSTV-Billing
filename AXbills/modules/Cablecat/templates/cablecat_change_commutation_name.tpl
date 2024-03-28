<script>
  jQuery(function () {
    let COMMUTATION_ID = '%COMMUTATION_ID%';
    let SAVE_INDEX = '%SAVE_INDEX%';

    let saveNameBtn = jQuery('#SAVE_NAME');
    let changeNameBtn = jQuery('#CHANGE_NAME_BTN');
    let inputName = jQuery('#NAME');

    saveNameBtn.on('click', function () {
      inputName.attr('readonly', '1');

      const url = '/admin/index.cgi';
      const data = {
        COMMUTATION_ID: COMMUTATION_ID,
        header        : 2,
        JSON_RESULT   : 1,
        qindex        : SAVE_INDEX,
        NAME          : jQuery('#NAME').val()
      };

      jQuery.post(url, data, function(data) {
        try {
          changeNameBtn.removeClass('d-none');
          saveNameBtn.addClass('d-none');
          const result = JSON.parse(data)
          if (result['ERROR_MESSAGE']) {
            jQuery('#INVALID_NAME_FEEDBACK').html(result['ERROR_MESSAGE']);
            jQuery('#NAME').removeClass('is-valid').addClass('is-invalid');
          }
          else {
            jQuery('#NAME').removeClass('is-invalid').addClass('is-valid');
          }
        } catch(e) {
          changeNameBtn.removeClass('d-none');
          saveNameBtn.addClass('d-none');
          jQuery('#NAME').removeClass('is-valid').addClass('is-invalid');
        }
      })
    });

    changeNameBtn.on('click', function () {
      saveNameBtn.removeClass('d-none');
      changeNameBtn.addClass('d-none');
      inputName.removeAttr('readonly');
      jQuery('#NAME').removeClass('is-valid').removeClass('is-invalid');
    });
  });
</script>