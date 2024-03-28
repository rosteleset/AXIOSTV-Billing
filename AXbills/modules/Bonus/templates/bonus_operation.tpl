<script language=\"JavaScript\" type=\"text/javascript\">
<!--
function postthread(param) {
       param = document.getElementById(param);
//       var id = setTimeout(param.disabled=true,10);
       param.value='_{IN_PROGRESS}_...';
       param.style.backgroundColor='#dddddd';
}
-->



</script>

<div class='d-print-none'>
    <form action='$SELF_URL' METHOD='POST' name='bonus_payment' onsubmit='postthread(\"submitbutton\");'>
        <input type=hidden name=index value=$index>
        <input type=hidden name=OP_SID value=%OP_SID%>
        <input type=hidden name=UID value=$FORM{UID}>
        <input type=hidden name=BILL_ID value=%BILL_ID%>

        <div class='card box-primary'>
            <div class='card-header with-border'>
                _{PAYMENTS}_ / _{FEES}_
            </div>
            <div class='card-body'>

                <div class='form-group'>
                    <label class='control-label col-md-3'>_{SUM}_:</label>

                    <div class='col-md-9'>
                        <input type=text name=SUM value='$FORM{SUM}'>
                    </div>
                </div>
                <div class='form-group'>
                    <label class='control-label col-md-3'>_{ACTION}_:</label>

                    <div class='col-md-9'>
                        %ACTION_TYPES%
                    </div>
                </div>
                <div class='form-group'>
                    <label class='control-label col-md-3'>_{DESCRIBE}_:</label>
                    <label class='control-label col-md-3'>_{USER}_:</label>

                    <div class='col-md-9'>
                        <input type=text name=DESCRIBE value='%DESCRIBE%' size=40>
                    </div>
                </div>
                <div class='form-group'>
                    <label class='control-label col-md-3'>_{INNER}_:</label>

                    <div class='col-md-9'>
                        <input type=text name=INNER_DESCRIBE size=40>
                    </div>
                </div>
                <div class='form-group'>
                    <label class='control-label col-md-3'>_{EXPIRE}_:</label>

                    <div class='col-md-9'>
                        <input type=text name='EXPIRE' value='%EXPIRE%' size=12 ID='EXPIRE'>
                    </div>

                </div>
                <div class='form-group'>
                    <label class='control-label col-md-3'>_{PAYMENT_METHOD}_:</label>

                    <div class='col-md-9'>
                        %SEL_METHOD%
                    </div>
                </div>
                <div class='form-group'>
                    <label class='control-label col-md-3'>EXT ID:</label>

                    <div class='col-md-9'>
                        <input type=text name='EXT_ID' value='%EXT_ID%'>
                    </div>
                </div>
                %DATE%
                <div class='form-group'>
                    <input type=submit class='btn-btn-primary' name=add value='_{EXECUTE}_' ID='submitbutton'>
                </div>
            </div>
        </div>

    </form>
</div>
