<form action='$SELF_URL' method='post' class='form form-horizontal'>
  <input type=hidden name=index value=$index>
  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class="card-title table-caption">_{FILTERS}_</h4>
      <div class="card-tools float-right">
        <button type="button" class="btn btn-secondary btn-xs" data-card-widget="collapse">
          <i class="fa fa-minus"></i></button>
      </div>
    </div>

    <div class='card-body'>
      <div class="row align-items-center">
        <div class='form-group'>
          <label class='col-md-3 control-label'>FB likes </label>
          <input type='textarea' name='post_url' value='' size=30%>
        </div>

      </div>
      <div class='card-footer'>
        <input type=submit class='btn btn-primary btn-block' name=''>
      </div>
    </div>
</form>


