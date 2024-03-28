<form action='$SELF_URL' METHOD='GET' name='form_search' id='form_search' class='pb-4 pt-4'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='search_form' value='1'>
  %HIDDEN_FIELDS%
  <fieldset>

    <button class='btn btn-primary btn-block' type='submit' name='search' value=1>
      <i class='fa fa-search'></i> _{SEARCH}_
    </button>
    <br/>
    <div class='row'>
      %ADDRESS_FORM%

      %SEARCH_FORM%
    </div>
    <button class='btn btn-primary btn-block' type='submit' name='search' value=1>
      <i class='fa fa-search'></i> _{SEARCH}_
    </button>

  </fieldset>
</form>
