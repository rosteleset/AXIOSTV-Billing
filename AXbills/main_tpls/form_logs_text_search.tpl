<form action='$SELF_URL' METHOD='POST' name='form_search' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name="file" value='%FILE_DIR%'>
  <input type='hidden' name="name" value='%FILE_NAME%'>
  <div class='card card-primary card-outline box-big-form'>
    <div class='card-header with-border' style="border-bottom: none; ">
      <div class='row'>
       <div class='col-md-3'><button class='btn btn-primary btn-block' type='submit' name='search' value=1 style="margin-bottom: 10px;">
        <i class='fa fa-search'></i> _{SEARCH}_
      </button>
    </div>

    <div class='col-md-9'> <input  name='grep' class='form-control' type='text'>
 </div></div>
</div>
<div class="card-body">
  %LOG_FILE%
</div>
</div>
</div>

</form>



