<script>
    jQuery(document).ready(function () {
      fetch('$SELF_URL?header=2&get_index=equipment_info&visual=4&NAS_ID=%NAS_ID%&unreg_btn_ajax=1&PON_TYPE=%PON_TYPE%')
        .then(function (response) {
          if (!response.ok)
            throw Error(response.statusText);

          return response;
        })
        .then(function (response) {
          return response.text();
        })
        .then(result => {
          jQuery('#unreg_btn').replaceWith(result);
        });
    })
</script>
