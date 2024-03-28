<form action='$SELF_URL' METHOD='POST'>
    <input type='hidden' name='module' value='Employees'>
    <div class='card container-md'>
        <div class='card-header with-border'>
            <h4 class='card-title'>_{EMPLOYEE_PROFILE}_</h4>
        </div>
        <div class='card-body'>
            <div class="form-group row">
                <label class="col-sm-4 col-md-4" for='FIO'>_{FIO}_:</label>
                <div class="col-sm-8 col-md-8">
                    <div class='input-group'>
                        <input required type='text' class='form-control' name='FIO' title='_{SYMBOLS_REG}_a-Z 0-9' placeholder="_{FIO}_" value='%FIO%'>
                    </div>
                </div>
            </div>

            <div class="form-group row">
                <label class="col-sm-4 col-md-4">_{BIRTHDAY}_:</label>
                <div class="col-sm-8 col-md-8">
                    <div class='input-group'>
                        %DATE%
                    </div>
                </div>
            </div>

            <div class="form-group row">
                <label class="col-sm-4 col-md-4" for="PHONE">_{PHONE}_:</label>
                <div class="col-sm-8 col-md-8">
                    <div class='input-group'>
                        <input required type='text' class='form-control' name='PHONE' placeholder="_{PHONE}_" value='%PHONE%'>
                    </div>
                </div>
            </div>

            <div class="form-group row">
                <label class="col-sm-4 col-md-4" for="MAIL">_{MAIL_BOX}_:</label>
                <div class="col-sm-8 col-md-8">
                    <div class='input-group'>
                        <input required type='email' class='form-control' placeholder="_{MAIL_BOX}_" name='MAIL' value='%MAIL%'>
                    </div>
                </div>
            </div>

            <div class="form-group row">
                <label class="col-sm-4 col-md-4">_{POSITION}_:</label>
                <div class="col-sm-8 col-md-8">
                    <div class='input-group'>
                        %POSITIONS%
                    </div>
                </div>
            </div>
        </div>
        <div class='card-footer'>
            <input type='submit' class='btn btn-primary' name='NEXT_BUTTON'
                value='_{NEXT}_'>
        </div>
    </div>
</form>
