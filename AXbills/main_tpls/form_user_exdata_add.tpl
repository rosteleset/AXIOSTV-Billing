<div class='form-group row'>
  <label class='col-form-label text-right col-4 col-md-2' for='LOGIN'>_{LOGIN}_:</label>
  <div class='col-8 col-md-4'>
    <input id='LOGIN' name='LOGIN' value='%LOGIN%' data-check-for-pattern='%LOGIN_PATTERN%' class='form-control' type='text'>
    <div class='invalid-feedback'>
      _{USER_EXIST}_
    </div>
  </div>
  %CREATE_COMPANY%
</div>

<div class='form-group row'>
  <label class='col-form-label text-right col-4 col-md-2 %GROUP_REQ%' for='GID'>_{GROUPS}_:</label>
  <div class='col-8 col-md-4'>
    %GID%
  </div>
</div>

<div class='form-group row'>
  <label class='col-form-label text-right col-4 col-md-2' for='CREATE_BILL'>_{BILL}_:</label>
  <div class='col-8 col-md-4'>
    <div class='form-check'>
      <input type='checkbox' class='form-check-input' id='CREATE_BILL' name='CREATE_BILL' value='%CREATE_BILL%' %CREATE_BILL%> _{CREATE}_
    </div>
  </div>
</div>

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
#  // Форматирование текущей даты в строку формата "YYYY-MM-DD"
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

