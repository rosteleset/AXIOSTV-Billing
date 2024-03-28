<FORM action='$SELF_URL' method='get' class='form-inline'>
  <input type='hidden' name='index' value='$index'>
  <div class='well well-sm'>
    <div class='pull-right'>
      <div class='form-group text-left'>
        <div class="checkbox">
          <label for="PLANNED">
            %PLANNED_CHECKBOX%
            <strong>_{PLANNED}_</strong>
          </label>
        </div>
      </div>
      <div class='form-group text-left'>
        %TYPE_SELECT%
      </div>
      <input type=submit name=show value='_{SHOW}_' class='btn btn-primary'>
    </div>
    <div class='clearfix'></div>
  </div>
</form>
