<div class='card card-danger collapsed-card'>
    <div class='card-header'>
        <h3 class='card-title'>_{NEG_DEPOSIT}_</h3>
        <div class='card-tools'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
            </button>
        </div>
    </div>
    <div class='card-body'>
        <div class='form-group text-center'>
            <label>_{NEGATIVE_DEPOSIT}_</label>
            <br>
            <label>_{ACTIVATE_NEXT_PERIOD}_: %TOTAL_DEBET% %MONEY_UNIT_NAME%</label>
        </div>
        <div class='form-group row'>
            <label for='neg_deposit' class='col-sm-4 col-md-4 col-form-label'>_{DEPOSIT}_</label>
            <div class='col-sm-8 col-md-8'>
                <input type='text' class='form-control' id='neg_deposit' placeholder='_{DEPOSIT}_' readonly value='%DEPOSIT% %MONEY_UNIT_NAME%'>
            </div>
        </div>
        <div class='form-group row'>
            <label for='neg_credit' class='col-sm-4 col-md-4 col-form-label'>_{CREDIT}_</label>
            <div class='col-sm-8 col-md-8'>
                <input type='text' class='form-control' id='neg_credit' placeholder='_{CREDIT}_' readonly value='%CREDIT% %MONEY_UNIT_NAME%'>
            </div>
        </div>
    </div>
    <div class='card-footer'>
       %PAYSYS_PAYMENTS% %CARDS_BUTTON% %DOCS_BUTTON%
    </div>
</div>