<form action='$SELF_URL' method='post' name='add_message' class='form form-horizontal'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='ID' value='%ID%'/>
    <input type='hidden' name='AID' value='%AID%'/>

    <div class='card card-primary card-outline box-form'>
        <div class="card-header"><h4>_{GPS_MAPS_SETTINGS}_</h4></div>

        <div class='card-body'>
            <div class='row'>
                <div class='col-md-12'>
                    <ul class='list-group'>
                        %AIDS%
                    </ul>
                </div>
            </div>
        </div>

        <div class='card-footer'>
            <input type=submit name='change' value='_{CHANGE}_' class='btn btn-primary'>
        </div>
    </div>

</form>

<script>
  initDatepickers();

  jQuery('.list-checkbox').each(function () {
    if (jQuery(this).is(":checked")) {
      jQuery(this).parent().addClass('list-group-item-success');
    }
  });

  jQuery('.list-checkbox').change(function () {
    if (jQuery(this).is(':checked')) {
      jQuery(this).parent().addClass('list-group-item-success');
    } else {
      jQuery(this).parent().removeClass('list-group-item-success');
    }
  });
</script>
