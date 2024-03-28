<div class='col-md-6'>
  <div class='card card-primary card-outline form-horizontal'>
    <div class='card-body'>
      <div class="media">
        <div class="media-left media-middle">
          <a href="#">
            <img class="img-fluid img-thumbnail" src="%FILE_SRC%" alt="...">
          </a>
        </div>
      </div>
      <hr>
      <div class='form-group'>
        <label class='col-md-3 control-label'>URL</label>
        <div class='col-md-8'>
        <input type='text' name='%FILE_NAME%_URL' value='%FILE_NAME_URL%' class='form-control'>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-md-3 control-label'>_{DESCRIPTION}_</label>
        <div class='col-md-8'>
        <input type='text' name='%FILE_NAME%_DESCRIBE' value='%FILE_NAME_DESCRIBE%' class='form-control'>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <div class='checkbox'>
        <label>
          <input type='checkbox' %CHECKED% name=%FILE_NAME%> %FILE_NAME%
        </label>
      </div>
    </div>
  </div>
</div>
