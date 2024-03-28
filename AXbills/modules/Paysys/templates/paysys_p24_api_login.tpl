<form method='POST' action='$SELF_URL' class='form form-horizontal'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='SESSION_ID' value='%SESSION_ID%'>

    <div class='card box-primary'>

        <div class='card-header with-border text-center'><h4 class='card-title'>_{LOGIN}_</h4></div>
        <div class='card-body'>

            <div class='form-group'>
                <label class='col-md-3 control-label required'>_{LOGIN}_:</label>
                <div class='col-md-9'><input class='form-control' type='text'name='LOGIN' autofocus>
                </div>
            </div>
            <div class='form-group'>
                <label class='col-md-3 control-label required'>_{PASSWD}_:</label>
                <div class='col-md-9'><input class='form-control' type='password'name='PASSWORD' >
                </div>
            </div>

        </div>

        <div class='card-footer'><input class='btn btn-primary' type='submit' name='send' value='_{SEND}_'></div>
    </div>


</form>