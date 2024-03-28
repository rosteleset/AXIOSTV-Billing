<div class='col-xs-12 col-md-6'>
  <div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{OBJECT}_</h4></div>
    <div class='card-body'>

      <form name='MAPS_OBJECT' id='form_MAPS_OBJECT' method='post' action='$SELF_URL' class='form form-horizontal'>
        <input type='hidden' name='index' value='$index'/>
        <input type='hidden' name='ID' value='%ID%'/>

        <div class='form-group'>
          <label class='control-label col-md-3' for='NAME_id'>_{NAME}_</label>
          <div class='col-md-9'>
            <input type='text' class='form-control' name='NAME' value='%NAME%' id='NAME_id'/>
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='TYPE_ID_SELECT'>_{TYPE}_</label>
          <div class='col-md-9'>
            %TYPE_ID_SELECT%
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='CREATED_id'>_{CREATED}_</label>
          <div class='col-md-9'>
            <input type='text' class='form-control datepicker' name='CREATED' value='%CREATED%' id='CREATED_id'/>
          </div>
        </div>

        <div class='checkbox'>
          <label for='PLANNED'>
            <input type='checkbox' name='PLANNED' id='PLANNED' value='1' data-checked='%PLANNED%'/>
            <strong>_{PLANNED}_</strong>
          </label>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='PARENT_ID_id'>_{PARENT_M}_ _{OBJECT}_</label>
          <div class='col-md-9'>
            %PARENT_ID_SELECT%
          </div>
        </div>

        <div class='form-group'>
          <label class='control-label col-md-3' for='COMMENTS_id'>_{COMMENTS}_</label>
          <div class='col-md-9'>
            <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS_id'>%COMMENTS%</textarea>
          </div>
        </div>

      </form>

    </div>
  </div>
</div>
