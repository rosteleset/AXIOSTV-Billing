<style>
.paysys-chooser{
    background-color: white;
}

input:checked + .paysys-chooser-box  {
    transform: scale(1.01,1.01);
    box-shadow: 10px 10px 5px #AAAAAA;
    z-index: 100;
}

input:checked + .paysys-chooser-box > .box-footer{
    background-color: lightblue;
}

.paysys-chooser:hover{
    transform: scale(1.05,1.05);
    box-shadow: 10px 10px 5px #AAAAAA;
    z-index: 101;
}
</style>

<div class='card box-primary'>
    <div class='card-header with-border'><h4 class='card-title'>_{CHOOSE_SYSTEM}_</h4></div>
  <div class='card-body'>
    
        <form name='PAYSYS_SETTINGS' id='form_PAYSYS_SETTINGS' method='post' class='form form-horizontal'>
        <input type='hidden' name='index' value='%index%' />

      <div class='form-group'>
        %PAY_SYSTEM_SEL%
      </div>
    </form>

  </div>
  <div class='card-footer'>
      <input type='submit' form='form_PAYSYS_SETTINGS' class='btn btn-primary' name='action' value='_{SELECT}_'>
  </div>
</div>

            