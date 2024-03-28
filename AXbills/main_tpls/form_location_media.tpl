<form action='$SELF_URL' class='form-horizontal' METHOD='post' enctype='multipart/form-data' name=add_district>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='chg' value='$FORM{chg}'/>
<input type='hidden' name='BUILDS' value='$FORM{BUILDS}'/>
<input type='hidden' name='media' value='1'/>

<div class='card card-primary card-outline container col-md-6'>
  <div class="card-header with-border">
    <h3 class="card-title">Media</h3>
  </div>
  <div class='card-body'>
    <div class="form-group">
      <div class="row">
        <label class='control-label col-md-12' for='COMMENTS'>_{COMMENTS}_</label>
        <div class="input-group">
          <input id='COMMENTS' name='COMMENTS' value='%COMMENTS%' placeholder='%COMMENTS%' class='form-control' type='text'>
        </div>
      </div>
    </div>

    <div class="form-group">
      <div class="row">
        <label class='control-label col-md-12' for='FILE'>_{FILE}_</label>
        <div class="input-group">
          <div class="custom-file">
            <input id='FILE' name='FILE' value='%FILE%' placeholder='%FILE%' type="file" class="custom-file-input">
            <label class="custom-file-label" for="exampleInputFile">Choose file</label>
          </div>
          <div class="input-group-append">
            <span class="input-group-text">Upload</span>
          </div>
        </div>
      </div>
    </div>
    <input type='submit' class='btn btn-primary' name='add' value='_{ADD}_'>
  </div>
</div>

</form>
