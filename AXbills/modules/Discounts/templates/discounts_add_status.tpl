<form action='$SELF_URL' METHOD='post' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{DISCOUNT_STATUS}_</h4></div>
    <div class='card-body'>

      <div class="form-group">
        <label class='control-label required'>_{NUM}_:</label>
          <div class="input-group">
            <input id='ID' name='ID' value='%ID%' placeholder='%ID%' class='form-control' type='text' required>
        </div>
      </div>

      <div class="form-group">
        <label class='control-label required'>_{NAME}_:</label>
          <div class="input-group">
            <input id='STAT_TITLE' name='STAT_TITLE' value='%STAT_TITLE%' placeholder='%STAT_TITLE%' class='form-control' type='text' required>
        </div>
      </div>

      <div class="form-group">
        <label class='control-label'>_{COLOR}_</label>
          <div class="input-group">
            <input class='form-control' type='color' name='COLOR' id='COLOR' value='%COLOR%' />
        </div>
      </div>

      <div class="form-group">
        <label class='control-label'>_{DESCRIPTION}_:</label>
          <div class="input-group">
            <input class='form-control' type='text' name='STAT_DESC' id='STAT_DESC' value='%STAT_DESC%'/>
        </div>
      </div>

	<div>
  <input type='submit' class='btn btn-primary' name=%ACTION% value='%ACTION_LANG%'>
		</div>
	</div>
  </div>
</form>
