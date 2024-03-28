<div class='card card-primary card-outline box-form container-md'>
    <div class='card-header with-border text-center'><h5>_{SELECT_TARIFF}_</h5></div>
    <form name='ADD_FRIEND' id='form_ADD_FRIEND' method='get' class='form form-horizontal'>
        <div class='card-body'>

            <input type='hidden' name='index' value='$index'/>
            <input type='hidden' name='REFERRAL_REQUEST' value='%ID%'/>
            <input type='hidden' name='FIO' value='%FIO%'/>
            <input type='hidden' name='PHONE' value='%PHONE%'/>

            <div class='form-group row'>
                <label class='control-label col-md-4' for='ADDRESS'>_{TARIF_PLAN}_</label>
                <div class='col-md-8'>
                    %TARIF_SELECT%
                </div>
            </div>
        </div>
        <div class='card-footer'>
            %ACTION%
        </div>
    </form>
</div>

