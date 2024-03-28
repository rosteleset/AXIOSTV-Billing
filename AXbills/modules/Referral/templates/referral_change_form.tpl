<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border text-center'><h5>_{ADD_FRIEND}_</h5></div>
  <form name='ADD_FRIEND' id='form_ADD_FRIEND' method='post' class='form form-horizontal'>
    <div class='card-body'>

      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='%ID%'/>



      <div class='form-group row'>
        <label class='control-label col-md-4' for='PHONE'>_{PHONE}_</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='PHONE' value='%PHONE%'
                 id='PHONE'/>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      %ACTION%
    </div>
  </form>
</div>

