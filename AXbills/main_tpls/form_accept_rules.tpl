<form action=$SELF_URL method='post'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='sid' value='$sid'>

  <div class='row'>
    <div class='col-md-12'>
      <div class='modal-content'>
        <div class='modal-header'><h4>_{RULES}_</h4></div>
        <div class='modal-body'>
          <br>Уважаемый, <b>%FIO%</b>.
          <p>Вы соглашаетесь с правилам пользования нашими услугами.</p>
          <p>Здесь пишите правила.</p>
          <div class='checkbox'>
            <label class='control-label'>
              <input type='checkbox' name='ACCEPT' value=1 %CHECKBOX% %HIDDEN%> _{ACCEPT_RULES}_
            </label>
          </div>
        </div>
        <div class='modal-footer'>
          <input type=submit class='btn btn-primary' name='accept' value='_{ACCEPT}_' %HIDDEN%>
          <input type=submit class='btn btn-primary' name='cancel' value='_{CANCEL}_' %HIDDEN%>
        </div>
      </div>
    </div>
  </div>

</form>