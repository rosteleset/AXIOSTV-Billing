<form action='$SELF_URL' METHOD='GET' enctype='multipart/form-data' name='MsgSearchForm' id='MsgSearchForm'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='sid' value='$sid'/>

  <div class='card card-primary card-outline'>
    <div class='card-body'>
      <div class='row'>
        <div class='col-md-12'>
          <div class='input-group'>
            <div class='input-group-prepend'>
              <button name='search_msgs' class='btn btn-primary' type='submit' value='_{SEARCH}_'>
                <i class='fa fa-search'></i>
              </button>
            </div>
            <input class='form-control' ID='SEARCH_MSG_TEXT' name='SEARCH_MSG_TEXT' type='text'>
          </div>
        </div>
      </div>
    </div>
  </div>
</form>