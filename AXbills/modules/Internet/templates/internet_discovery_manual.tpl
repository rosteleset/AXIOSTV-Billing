<form action=%SELF_URL%>
    <input type=hidden name=index value=%index%>
    <input type=hidden name=sid value=$sid>
    <input type=hidden name=DISCOVERY_MAC value='1'>

    <div class='card box-warning box-solid'>
        <div class='card-header  bg-yellow'>
            <h4 class='card-title'>_{CHANGE}_ MAC:</h4>
        </div>

        <div class='card-body'>

            <div class='form-group row'>
                <label class='col-md-3' for='CID'>MAC:</label>
                <div class='col-md-9'>
                    <input type=text id='CID' name='CID' value='%CID%' class='form-control'
                           pattern='[0-9a-fA-F:]{17}'
                           placeholder='xx:xx:xx:xx:xx:xx'>
                </div>
            </div>

        </div>
        <div class='card-footer'>
            <input type=submit name=discovery value='_{REGISTRATION}_' class='btn btn-success'>
        </div>
    </div>

</form>
