<div class='well well-sm'>
    <form method='post' name='GPS_REPORTS_FORM' class='form form-inline'>
        <input type='hidden' name='index' value='$index'/>

        <label for='AID'>_{ADMIN}_</label>
        %ADMIN_SELECT%

        <label for='DATE_START'>_{DATE}_</label>
        <input type='text' class='form-control datepicker' name='DATE_START' id='DATE_START' value='%DATE_START%'/>

        <label for='DATE_END'>-</label>
        <input type='text' class='form-control datepicker' name='DATE_END' id='DATE_END' value='%DATE_END%'/>

        <input type='submit' class='btn btn-primary' value='_{SHOW}_'/>
    </form>
</div>

<div class='card box-primary'>
    <div class='card-header with-border'>
        <div class='card-title'>GPS _{REPORTS}_</div>
    </div>
    %REPORT_TABLE%

    <div class='card-title bg-info'><h3>_{PERIOD}_<span class='text-lowercase'> _{AVG}_ </span></h3></div>
    %REPORT_AVG_TABLE%

</div>

%REPORT_COMPARE_CHART%