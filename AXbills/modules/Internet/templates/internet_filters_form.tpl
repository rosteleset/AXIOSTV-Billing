<form name='filter' id='form_filter' method='GET' class='form'>
    <input type='hidden' name='index' value='$index'/>
    <input type='hidden' name='ID' value='%ID%'/>

    <div class='card card-primary card-outline container-md'>
        <div class='card-header with-border'>
            <h4 class='card-title'>_{FILTERS_LOG}_</h4>
        </div>
        <div class='card-body'>
            <div class='form-group row'>
                <label class='col-md-4 col-form-label' for='FILTER'>_{NAME}_</label>
                <div class='col-md-8'>
                    <input type='text' class='form-control' name='FILTER' id='FILTER' value='%FILTER%'/>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-md-4 col-form-label' for='PARAMS'>_{PARAMS}_</label>
                <div class='col-md-8'>
                    <input type='text' class='form-control' name='PARAMS' id='PARAMS' value='%PARAMS%'/>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-md-4 col-form-label' for='DESCR'>_{DESCRIBE}_</label>
                <div class='col-md-8'>
                    <input type='text' class='form-control' name='DESCR' id='DESCR' value='%DESCR%'/>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-md-4 col-form-label' for='USER_PORTAL'>_{USER_PORTAL}_</label>
                <div class='col-md-8'>
                    <input type='checkbox' name='USER_PORTAL' id='USER_PORTAL' %USER_PORTAL%/>
                </div>
            </div>

        </div>
        <div class='card-footer'>
            <input type='submit' form='form_filter' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%'>
        </div>
    </div>

</form>