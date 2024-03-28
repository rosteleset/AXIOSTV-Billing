<div class='row text-center' style='margin-bottom: 20px'>
    <div class='row'>
        <div class='col-md-12'>
            <p>%HEADER_TEXT%</p>
        </div>
    </div>
</div>

<div class='card card-primary card-outline box-form' style='margin-left:auto; margin-right:auto; width:auto; max-width:500px;'>
    <div class='card-header with-border text-center'>
        <h4 class='card-title'>_{CARDS}_ _{INFO}_</h4>
    </div>

    <div class='card-body form form-horizontal'>

        <div class='form-group'>
            <label class='col-md-6 col-xs-6 control-label'>_{LOGIN}_:</label>

            <div class='col-md-6 col-xs-6 form-control-static'> %LOGIN%</div>
        </div>

        <div class='form-group'>
            <label class='col-md-6 col-xs-6 control-label'>_{PASSWD}_: </label>

            <div class='col-md-6 col-xs-6 form-control-static'> %PASSWORD%</div>
        </div>


        <div class='form-group'>
            <label class='col-md-6 col-xs-6 control-label'>_{TARIF_PLAN}_: </label>

            <div class='col-md-6 col-xs-6 form-control-static'> %TP_NAME%</div>
        </div>

        <div class='form-group'>
            <label class='col-md-6 col-xs-6 control-label'>_{AGE}_ (_{DAYS}_): </label>

            <div class='col-md-6 col-xs-6 form-control-static'> %AGE%</div>
        </div>

        <div class='form-group'>
            <label class='col-md-6 col-xs-6 control-label'>_{TIME_LIMIT}_: </label>

            <div class='col-md-6 col-xs-6 form-control-static'> %TIME_LIMIT%</div>
        </div>

        <div class='form-group'>
            <label class='col-md-6 col-xs-6 control-label'>_{TRAF_LIMIT}_: </label>

            <div class='col-md-6 col-xs-6 form-control-static'> %TRAF_LIMIT%</div>
        </div>

        <!--
        <div class='form-group'>
            <label class='col-md-6 col-xs-6 control-label'>_{SPEED}_:  </label>
            <div class='col-md-6 col-xs-6'> %SPEED_IN% %SPEED_OUT% </div>
        </div>
        -->

        <div class='form-group'>
            <label class='col-md-6 col-xs-6 control-label'>_{INFO}_: </label>

            <div class='col-md-6 col-xs-6 form-control-static'> %SERIAL%%NUMBER%</div>
        </div>

    </div>

    <div class='card-footer'>
        %FOOTER_TEXT%
    </div>

</div>


