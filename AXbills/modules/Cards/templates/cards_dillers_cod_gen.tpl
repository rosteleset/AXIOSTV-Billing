<script language="JavaScript" type="text/javascript">
    <!--
    function make_unique() {
        var pwchars = "abcdefhjmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWYXZ.,:";
        var passwordlength = 8;    // do we want that to be dynamic?  no, keep it simple :)
        var passwd = document.getElementById('OP_SID');
        var sum = document.getElementById('SUM');
        var sum_new = document.getElementById('SUM_NEW');

        passwd.value = '';

        for (i = 0; i < passwordlength; i++) {
            passwd.value += pwchars.charAt(Math.floor(Math.random() * pwchars.length))
        }

        sum.value = sum_new.value;
        sum_new.value = '0.00';

        return passwd.value;
    }

    -->
</script>

<form action='%SELF_URL%' METHOD='POST' TARGET=New>
    <input type='hidden' name='qindex' value='$index'>
    <input type='hidden' name='UID' value='$FORM{UID}'>
    <input type='hidden' name='OP_SID' value='%OP_SID%' ID=OP_SID>
    <input type='hidden' name='sid' value='$sid'>
    <input type='hidden' name='SUM' value='' ID='SUM'>
    <div class='card box-form box-primary form-horizontal'>
        <div class='card-header with-border'>
            <h4 class='card-title'>
                _{ICARDS}_
            </h4>
        </div>
        <div class='card-body'>
            <div class='form-group row'>
                <label class='col-md-4 col-sm-3 control-label' for='COUNT'>_{COUNT}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input class='form-control' type='text' id='COUNT' name='COUNT' value='%COUNT%'>
                </div>
            </div>
            <div class='form-group row'>
                <label class='col-md-4 col-sm-3 control-label' for='SUM_NEW'>_{SUM}_:</label>
                <div class='col-md-8 col-sm-9'>
                    <input class='form-control' type='text' name='SUM_NEW' value='0.00' ID=SUM_NEW>
                </div>
            </div>
        </div>
        <div class='card-footer'>
            <input class='btn btn-primary center-block' type='submit' name='add' value='_{ADD}_' onclick=\"make_unique(this.form)\">
        </div>
    </div>
</form>

