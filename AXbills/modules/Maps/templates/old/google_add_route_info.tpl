<form action=$SELF_URL ID=mapForm name=adress class='form form-horizontal'>
    <input type=hidden name=index value=$index>
    <input type=hidden name=COORDX value=%COORDX%>
    <input type=hidden name=COORDY value=%COORDY%>

    <div class='card card-primary card-outline'>
        <div class='card-body'>
            <div class='form-group'>
                %ROUTE_ID%
            </div>
        </div>
        <div class='card-footer'>
            <input type='submit' name=add_route_info value=_{ADD}_ class='btn btn-secondary'>
        </div>
    </div>


</form>

