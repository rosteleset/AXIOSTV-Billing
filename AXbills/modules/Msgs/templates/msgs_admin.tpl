<form action=$SELF_URL METHOD=post class='form-horizontal'>
  <input type=hidden name=index value=$index>
  <input type=hidden name=AID value=$FORM{chg}>

  <div class='card card-primary card-outline'>
    <div class='card-body'>

      %CHAPTERS%

      <input type='submit' name='change' value=_{CHANGE}_ class='btn btn-primary'>
    </div>
  </div>
</form>
