<form id=pay name=pay method='POST' action='$SELF_URL'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='sid' value='$sid'>
<input type='hidden' name='IP' value='$ENV{REMOTE_ADDR}'>
<input type='hidden' name='OPERATION_ID' value='$FORM{OPERATION_ID}'>
<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>
<input type='hidden' name='REQUEST_ID' value='%REQUEST_ID%'>
%TEST_MODE%
<table width=400 class=form>
<tr><th colspan='2' class='form_title'>Yandex Money</th></tr>
<tr><td>ID:</td><td>$FORM{OPERATION_ID}</td></tr>
    <tr>
        <td>_{SUM}_:</td>
        <td>$FORM{SUM}</td>
    </tr>
    <tr>
        <td>_{DESCRIBE}_:</td>
        <td>%DESCRIBE%
    <tr>
        <th colspan='2' class='even'><input type=submit name='CONFIRM_PAYMENT' value='_{CONFIRM_PAYMENT}_'></th>
    </tr>
</table>

</form>