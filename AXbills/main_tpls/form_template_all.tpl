<form action='%SELF_URL%' METHOD='POST'>
  <input type='hidden' name='index' value='%index%'>

  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{TEMPLATES}_</h4>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i></button>
      </div>
    </div>

    <div class='card-body p-0'>
      %TEMPLATES_MODULES%
    </div>

  </div>
</form>