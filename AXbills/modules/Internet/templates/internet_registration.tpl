<link href='/styles/default/css/client.css' rel='stylesheet'>

<FORM action='%SELF_URL%' METHOD='POST' ID='REGISTRATION'>
    <input type=hidden name='index' value='%index%'>
    <input type=hidden name='DOMAIN_ID' value='$FORM{DOMAIN_ID}'>
    <input type=hidden name='module' value='Internet'>
    <input type=hidden name='_FACEBOOK' value='%USER_ID%'>
    <input type=hidden name='REFERRER' value='%REFERRER%'>

    <div class='card center-block container-md'>

        <div class='card-header with-border'>
            <h4 class='card-title'>_{REGISTRATION}_</h4>
        </div>
        <div class='card-body'>
            %CHECKED_ADDRESS_MESSAGE%

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4 col-form-label text-md-right' for='LOGIN'>_{LOGIN}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        <input id='LOGIN' name='LOGIN' value='%LOGIN%' %LOGIN_READONLY% required placeholder='_{LOGIN}_'
                               title='_{SYMBOLS_REG}_a-Z 0-9' class='form-control' type='text'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4 col-form-label text-md-right' for='FIO'>_{FIO}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        <input id='FIO' name='FIO' value='%FIO%' required placeholder='_{FIO}_' class='form-control'
                               type='text'>
                    </div>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4 col-form-label text-md-right'
                       for='PHONE_PATTERN_FIELD'>_{PHONE}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <input id='PHONE' name='PHONE' value='%PHONE%' class='form-control' type='hidden'>
                    <input id='PHONE_PATTERN_FIELD' name='PHONE_PATTERN_FIELD' value='%PHONE%' required
                           placeholder='_{PHONE}_' class='form-control' data-phone-field='PHONE'
                           data-check-phone-pattern='%PHONE_NUMBER_PATTERN%' type='text'>
                </div>
            </div>

            <div class='form-group row'>
                <label class='col-sm-4 col-md-4 col-form-label text-md-right' for='EMAIL'>E-MAIL:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='E-mail' required
                               class='form-control'
                               type='text'>
                    </div>
                </div>
            </div>

            <div class='form-group row %HIDE_TP%'>
                <label class='col-sm-4 col-md-4 col-form-label text-md-right'>_{TARIF_PLAN}_:</label>
                <div class='col-sm-8 col-md-8'>
                    <div class='input-group'>
                        %TP_SEL%
                    </div>
                </div>
            </div>

            %USER_IP_FORM%
<!--
            <div class='form-group row'>
                <label class='col-md-4 col-form-label text-md-right' for='REGISTRATION_TAG'>_{TAGS}_:</label>
                <div class='col-md-8'>
                    <div class='form-check'>
                        <input type='checkbox' class='form-check-input' id='REGISTRATION_TAG' name='REGISTRATION_TAG'
                               %TAGS% value='1'>
                    </div>
                </div>
            </div>
-->
            %ADDRESS_TPL%

            %PAYMENTS%

            %USER_PASSWORD_FIELD%

            <div class='form-group text-center'>
                <label class='control-element col-md-12 ' for='TP_ID'>_{RULES}_</label>
                <div class='col-md-12'>
                    <textarea id='TP_ID' cols='60' rows='8' class='form-control' readonly> %_RULES_% </textarea>
                </div>
            </div>

            <div class='form-group text-center'>
                <div class='custom-control custom-checkbox'>
                    <input class='custom-control-input' type='checkbox' id='ACCEPT_RULES' required name='ACCEPT_RULES'
                           value='1'>
                    <label for='ACCEPT_RULES' class='custom-control-label'>_{ACCEPT}_</label>
                </div>
            </div>

            %CAPTCHA%
        </div>

        <div class='card-footer'>
            %FB_INFO%
            <input type='submit' name='reg' value='_{REGISTRATION}_' class='btn btn-primary'>
        </div>

    </div>
</FORM>


%MAPS%

## Генератор логинов, 8 цифр
############################

#<script>
#jQuery(function(){
#  var randomDigits = Math.floor(10000000 + Math.random() * 90000000);
#  jQuery('input#LOGIN').val(randomDigits);
#})
#</script>

############################

## Генератор логинов согласно выбранной группе цифры "1:", "2:".... ID нужной группы

############################

#<script>
#function genLogin() {
#    var prefixes = {
#        1: "staff",
#        2: "jur",
#        3: "jazz",
#        4: "a", //Физлица ,
#        6: "iz",
#        7: 'ol',
#        8: "wfx",
#        11: "gold"
#    };
#    var gid = jQuery("#GID").val();
#    if (!gid) {
#        alert('Выберите группу клиента');
#        return false;
#    }
#    var randomDigits = Math.floor(10000000 + Math.random() * 90000000);
#    jQuery('input#LOGIN').val(prefixes[gid] + randomDigits);
#};
#
#jQuery(document).on("change", "#GID", genLogin);
#</script>

### Генератор логина с подстановкой кредита и номера договора - равным логину


#<script>
#jQuery(function(){
#
#  // Генератор логина
#  var randomDigits = Math.floor(10000000 + Math.random() * 90000000);
#  jQuery('input#LOGIN').val(randomDigits);
#  jQuery('input#CONTRACT_ID').val(randomDigits);
#
#  // Задаем значение CREDIT равным 150
#  jQuery('input#CREDIT').val(150);
#
#  // Форматирование текущей даты в строку формата 'YYYY-MM-DD'
#  var currentDate = new Date();
#  var currentDateString = currentDate.getFullYear() + '-' +
#                          ('0' + (currentDate.getMonth() + 1)).slice(-2) + '-' +
#                          ('0' + currentDate.getDate()).slice(-2);
#
#  jQuery('input#CONTRACT_DATE').val(currentDateString);
#
#  // Вычисляем дату через 3 дня после сегодня
#  var threeDaysLater = new Date(currentDate);
#  threeDaysLater.setDate(threeDaysLater.getDate() + 3);
#  var threeDaysLaterString = threeDaysLater.getFullYear() + '-' +
#                             ('0' + (threeDaysLater.getMonth() + 1)).slice(-2) + '-' +
#                             ('0' + threeDaysLater.getDate()).slice(-2);
#
#  jQuery('input#CREDIT_DATE').val(threeDaysLaterString);
#})
#</script>

