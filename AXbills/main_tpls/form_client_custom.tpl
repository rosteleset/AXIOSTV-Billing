
<div class='row'>
%NEWS%
</div>

<div class='row'>
    <!-- Left col -->
    <section class='col-lg-8 connectedSortable'>
        <!-- small box -->
        <div class='small-box bg-red'>
            <div class='inner'>
                <h4>_{YOUR_DEPOSIT}_: %MAIN_INFO_DEPOSIT% %MONEY_UNIT_NAME%</h4>
                <p>_{RECOMMENDED_PAYMENT}_ %RECOMENDED_PAY% %MONEY_UNIT_NAME%</p>
                <p>_{PAYMENT_NUMBER}_ UID: %MAIN_INFO_UID%</p>
                <p>_{LAST_PAYMENT_FEE}_: &nbsp; %PAYMENTS_DATETIME% &nbsp; %PAYMENTS_SUM% %MONEY_UNIT_NAME% &nbsp; %PAYMENTS_DSC%</p>
                <a href='$SELF_URL?get_index=paysys_payment&SUM=%RECOMENDED_PAY%' class='btn btn-primary text-white'>_{MAKE_PAYMENT}_!</a>
            </div>
            <div class='icon'>
                <i class='fas fa-chart-pie'></i>
            </div>
            <a href='/index.cgi?index=10' class='small-box-footer'>_{INFO}_ <i class='fa fa-arrow-circle-right'></i></a>
        </div>

        %BIG_BOX%
        <!-- /.box -->

    </section>
    <!-- /.Left col -->
    <!-- right col (We are only adding the ID to make the widgets sortable)-->
    <section class='col-lg-4 connectedSortable'>
        <!-- /.box-header -->

        %SMALL_BOX%

        <div class='callout callout-info'>
            <p>_{WANT_TO_REGISTER_CURRENT_MAC}_ ?</p>

            <label>
                <input type='checkbox'> _{CONFIRM}_
            </label>
            <button type='submit' class='btn btn-primary'>_{YES}_!</button>
        </div>

        <div class='callout callout-warning'>
            <h4></h4>

            <p>_{CANCEL_SUSPENSION}_?</p>
            <label>
                <input type='checkbox'> _{CONFIRM}_
            </label>
            <a href='$SELF_URL?get_index=dv_user_info&del=1' class='btn btn-primary text-white'>_{YES}_!</a>

        </div>

        <!-- /.box-body -->

    </section>
    <!-- right col -->
</div>

