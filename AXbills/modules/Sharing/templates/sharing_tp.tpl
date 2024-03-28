<div class='d-print-none'>
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='%TP_ID%'>
<table border='0'>
  <tr><th>#</th><td><input type='text' name='CHG_TP_ID' value='%TP_ID%'></td></tr>
    <tr>
        <td>_{NAME}_:</td>
        <td><input type=text name=NAME value='%NAME%'></td>
    </tr>

    <tr>
        <td>_{GROUP}_:</td>
        <td>%GROUPS_SEL%</td>
    </tr>

    <tr>
        <td>_{UPLIMIT}_:</td>
        <td><input type=text name=ALERT value='%ALERT%'></td>
    </tr>
    <tr>
        <td>_{SIMULTANEOUSLY}_:</td>
        <td><input type=text name=SIMULTANEOUSLY value='%SIMULTANEOUSLY%'></td>
    </tr>
    <tr>
        <th colspan=2 bgcolor=$_COLORS[0]>_{ABON}_</th>
    </tr>
    <tr>
        <td>_{DAY_FEE}_:</td>
        <td><input type=text name=DAY_FEE value='%DAY_FEE%'></td>
    </tr>
    <tr>
        <td>_{MONTH_FEE}_:</td>
        <td><input type=text name=MONTH_FEE value='%MONTH_FEE%'></td>
    </tr>

    <tr>
        <td>_{REDUCTION}_:</td>
        <td><input type=checkbox name=REDUCTION_FEE value=1 %REDUCTION_FEE%></td>
    </tr>
    <tr>
        <td>_{POSTPAID}_:</td>
        <td><input type=checkbox name=POSTPAID_FEE value=1 %POSTPAID_FEE%></td>
    </tr>
    <tr>
        <th colspan=2 bgcolor=$_COLORS[0]>_{TRAF_LIMIT}_ (Mb)</th>
    </tr>
    <tr>
        <td>_{DAY}_</td>
        <td><input type=text name=DAY_TRAF_LIMIT value='%DAY_TRAF_LIMIT%'></td>
    </tr>
    <tr>
        <td>_{WEEK}_</td>
        <td><input type=text name=WEEK_TRAF_LIMIT value='%WEEK_TRAF_LIMIT%'></td>
    </tr>
    <tr>
        <td>_{MONTH}_</td>
        <td><input type=text name=MONTH_TRAF_LIMIT value='%MONTH_TRAF_LIMIT%'></td>
    </tr>
    <tr>
        <td>_{OCTETS_DIRECTION}_</td>
        <td>%SEL_OCTETS_DIRECTION%</td>
    </tr>
    <tr>
        <th colspan=2 bgcolor=$_COLORS[0]>_{OTHER}_</th>
    </tr>
    <tr>
        <td>_{ACTIVATE}_:</td>
        <td><input type=text name=ACTIV_PRICE value='%ACTIV_PRICE%'></td>
    </tr>
    <tr>
        <td>_{CHANGE}_:</td>
        <td><input type=text name=CHANGE_PRICE value='%CHANGE_PRICE%'></td>
    </tr>
    <tr>
        <td>_{CREDIT_TRESSHOLD}_:</td>
        <td><input type=text name=CREDIT_TRESSHOLD value='%CREDIT_TRESSHOLD%'></td>
    </tr>
    <tr>
        <td>_{MAX_SESSION_DURATION}_ (sec.):</td>
        <td><input type=text name=MAX_SESSION_DURATION value='%MAX_SESSION_DURATION%'></td>
    </tr>
    <tr>
        <td>_{FILTERS}_:</td>
        <td><input type=text name=FILTER_ID value='%FILTER_ID%'></td>
    </tr>
    <tr>
        <td>_{AGE}_ (_{DAYS}_):</td>
        <td><input type=text name=AGE value='%AGE%'></td>
    </tr>
    <tr>
        <td>_{PAYMENT_TYPE}_:</td>
        <td>%PAYMENT_TYPE_SEL%</td>
    </tr>
    <tr>
        <td>_{MIN_SESSION_COST}_:</td>
        <td><input type=text name=MIN_SESSION_COST value='%MIN_SESSION_COST%'></td>
    </tr>

    <tr>
        <td>_{TRAFFIC_TRANSFER_PERIOD}_:</td>
        <td><input type=text name=TRAFFIC_TRANSFER_PERIOD value='%TRAFFIC_TRANSFER_PERIOD%'></td>
    </tr>
    <tr>
        <td>_{NEG_DEPOSIT_FILTER_ID}_:</td>
        <td><input type=text name=NEG_DEPOSIT_FILTER_ID value='%NEG_DEPOSIT_FILTER_ID%'></td>
    </tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>
