<form>
  <input type='hidden' name='index' value='%INDEX%'/>
  <input type='hidden' name='PAYSYSTEM_NAME' value='%PAYSYSTEM_NAME%'/>
  <input type='hidden' name='RECURRENT_ID' value='%RECURRENT_ID%'/>
  <div class='callout callout-info'>
    <h4>%PAYSYSTEM_NAME%</h4>
    <p>%MESSAGE%</p>

    <label>
      <input type='checkbox' name='RECURRENT_CANCEL'> ОТМЕНИТЬ?
    </label>
    <button type='submit' class='btn btn-primary'>ДА !</button>
  </div>
</form>