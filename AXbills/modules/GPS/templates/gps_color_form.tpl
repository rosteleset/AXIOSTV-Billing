
<form action=$SELF_URL method=post>
    <input type='hidden' name='index' value=$index>
    <input type='hidden' name='AID' value=%AID%>

    <div class='card card-primary card-outline box-form'>
        <div class="card-header"><h4>_{ROUTE_COLOR}_</h4></div>

        <div class='card-body'>
            <div class='form-group'>
                <label class='control-label col-md-3 required' for='COLOR'>_{COLOR}_</label>
                <div class='col-md-9'>
                    <input class='form-control' type='color' name='COLOR' id='COLOR' value='%COLOR%'/>
                </div>
            </div>
        </div>

        <div class='card-footer'>
            <button class='btn btn-primary' type='submit' name="change" value="change">
                _{CHANGE}_
            </button>
        </div>
    </div>

</form>