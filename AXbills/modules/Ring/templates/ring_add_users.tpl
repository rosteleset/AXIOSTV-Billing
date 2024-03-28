<div class='card box-primary'>
    <div class='card-header with-border'><h4 class='card-title'>_{USERS}_</h4></div>
    <div class='card-body'>

    <form name='ring_uid_form' id='form_ring_uid_form' method='post' class='form form-horizontal'>
        <input type='hidden' name='index' value='$index' />
        <input type='hidden' name='rule' value='%RULE%' />

        %USER_TABLE%
    </form>

</div>
  <div class='card-footer'>
    <input type='submit' form='form_ring_uid_form' class='btn btn-primary' name='action' value='_{ADD}_'>

  </div>
</div>
