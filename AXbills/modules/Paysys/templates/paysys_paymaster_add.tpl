<!--
2 = Моб. платежи WebMoney
23 = Київстар   
-->

<table>
  <tr>
    <th> <img src='https://easypay.ua/content/images/logo.png' style='width:100px;height:50px'>   </th>
	  
<form id=pay name=pay method='POST' action='%ACTION_URL%'>
<input type='hidden' name='LMI_RESULT_URL' value='$conf{PAYSYS_LMI_RESULT_URL}'>
<input type='hidden' name='LMI_SUCCESS_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1'>
<input type='hidden' name='LMI_SUCCESS_METHOD' value='0'>
<input type='hidden' name='LMI_FAIL_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?FALSE=1&LMI_PAYMENT_NO=%LMI_PAYMENT_NO%&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&index=$index'>
<input type='hidden' name='LMI_FAIL_METHOD' value='2'>
<input type='hidden' name='LMI_PAYMENT_NO' value='%LMI_PAYMENT_NO%'>
<input type='hidden' name='LMI_PAYMENT_SYSTEM' value='12'>
<input type='hidden' name='at' value='%AT%'>
<input type='hidden' name='LMI_MERCHANT_ID' value='$conf{PAYSYS_PAYMASTER_MERCHANT_ID}'>
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='IP' value='$ENV{REMOTE_ADDR}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>
<input type='hidden' name='LMI_PAYMENT_DESC' value='%LMI_PAYMENT_DESC%'>

	  <th> <br> Оплата по EasyPay <br>  При помощи PayMaster <br> %TEST_MODE% </th>
    <th> <input type='text' name='LMI_PAYMENT_AMOUNT' value='%LMI_PAYMENT_AMOUNT%' size=20/> </th>
	  <th> <input class='button' type='submit' name=pay value='Оплатить'> </th>
</form>
	  
  </tr>
  <tr>
    <th> <img src='https://bnk24.com.ua/Uploads/ServicePictures/Multimedia/Pictures/new_logo/Monexy2_logo.png' style='width:100px;height:100px'>   </th>
	  
  
<form id=pay name=pay method='POST' action='%ACTION_URL%'>
<input type='hidden' name='LMI_RESULT_URL' value='$conf{PAYSYS_LMI_RESULT_URL}'>
<input type='hidden' name='LMI_SUCCESS_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1'>
<input type='hidden' name='LMI_SUCCESS_METHOD' value='0'>
<input type='hidden' name='LMI_FAIL_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?FALSE=1&LMI_PAYMENT_NO=%LMI_PAYMENT_NO%&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&index=$index'>
<input type='hidden' name='LMI_FAIL_METHOD' value='2'>
<input type='hidden' name='LMI_PAYMENT_NO' value='%LMI_PAYMENT_NO%'>
<input type='hidden' name='LMI_PAYMENT_SYSTEM' value='6'>
<input type='hidden' name='at' value='%AT%'>
<input type='hidden' name='LMI_MERCHANT_ID' value='$conf{PAYSYS_PAYMASTER_MERCHANT_ID}'>
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='IP' value='$ENV{REMOTE_ADDR}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>
<input type='hidden' name='LMI_PAYMENT_DESC' value='%LMI_PAYMENT_DESC%'>

	  <th> <br> Оплата по MoneyXy <br>  При помощи PayMaster <br>%TEST_MODE%</th>
    <th> <input type='text' name='LMI_PAYMENT_AMOUNT' value='%LMI_PAYMENT_AMOUNT%' size=20/> </th>
	  <th> <input class='button' type='submit' name=pay value='Оплатить'> </th>
</form>
  </tr>
   <tr>
    <th> <img src='http://e-commerce.com.ua/wp-content/uploads/2011/10/logo-nsmep.png' style='width:100px;height:50px'>   </th>
    <form id=pay name=pay method='POST' action='%ACTION_URL%'>
<input type='hidden' name='LMI_RESULT_URL' value='$conf{PAYSYS_LMI_RESULT_URL}'>
<input type='hidden' name='LMI_SUCCESS_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1'>
<input type='hidden' name='LMI_SUCCESS_METHOD' value='0'>
<input type='hidden' name='LMI_FAIL_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?FALSE=1&LMI_PAYMENT_NO=%LMI_PAYMENT_NO%&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&index=$index'>
<input type='hidden' name='LMI_FAIL_METHOD' value='2'>
<input type='hidden' name='LMI_PAYMENT_NO' value='%LMI_PAYMENT_NO%'>
<input type='hidden' name='LMI_PAYMENT_SYSTEM' value='15'>
<input type='hidden' name='at' value='%AT%'>
<input type='hidden' name='LMI_MERCHANT_ID' value='$conf{PAYSYS_PAYMASTER_MERCHANT_ID}'>
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='IP' value='$ENV{REMOTE_ADDR}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>
<input type='hidden' name='LMI_PAYMENT_DESC' value='%LMI_PAYMENT_DESC%'>

	  <th> <br> Оплата по НСМЕП <br>  При помощи PayMaster <br> %TEST_MODE% </th>
    <th> <input type='text' name='LMI_PAYMENT_AMOUNT' value='%LMI_PAYMENT_AMOUNT%' size=20/> </th>
	  <th> <input class='button' type='submit' name=pay value='Оплатить'> </th>
</form>

  </tr>
   <tr>
    <th> <img src='http://www.clearent.com/blog-fi/files/2011/08/VisaMasterCard-Logos.jpg' style='width:100px;height:100px'>   </th>
	  
	  
<form id=pay name=pay method='POST' action='%ACTION_URL%'>
<input type='hidden' name='LMI_RESULT_URL' value='$conf{PAYSYS_LMI_RESULT_URL}'>
<input type='hidden' name='LMI_SUCCESS_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1'>
<input type='hidden' name='LMI_SUCCESS_METHOD' value='0'>
<input type='hidden' name='LMI_FAIL_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?FALSE=1&LMI_PAYMENT_NO=%LMI_PAYMENT_NO%&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&index=$index'>
<input type='hidden' name='LMI_FAIL_METHOD' value='2'>
<input type='hidden' name='LMI_PAYMENT_NO' value='%LMI_PAYMENT_NO%'>
<input type='hidden' name='LMI_PAYMENT_SYSTEM' value='21'>
<input type='hidden' name='at' value='%AT%'>
<input type='hidden' name='LMI_MERCHANT_ID' value='$conf{PAYSYS_PAYMASTER_MERCHANT_ID}'>
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='IP' value='$ENV{REMOTE_ADDR}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>
<input type='hidden' name='LMI_PAYMENT_DESC' value='%LMI_PAYMENT_DESC%'>

	   <th> <br> Оплата по VISA/MasterCard <br>  При помощи PayMaster <br>%TEST_MODE%</th>
    <th> <input type='text' name='LMI_PAYMENT_AMOUNT' value='%LMI_PAYMENT_AMOUNT%' size=20/> </th>
	  <th> <input class='button' type='submit' name=pay value='Оплатить'> </th>
</form>
  </tr>
   <tr>
    <th> <img src='http://i65.beon.ru/48/13/41348/1/1102201/logo.png' style='width:100px;height:50px'>   </th>
	  
<form id=pay name=pay method='POST' action='%ACTION_URL%'>
<input type='hidden' name='LMI_RESULT_URL' value='$conf{PAYSYS_LMI_RESULT_URL}'>
<input type='hidden' name='LMI_SUCCESS_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1'>
<input type='hidden' name='LMI_SUCCESS_METHOD' value='0'>
<input type='hidden' name='LMI_FAIL_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?FALSE=1&LMI_PAYMENT_NO=%LMI_PAYMENT_NO%&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&index=$index'>
<input type='hidden' name='LMI_FAIL_METHOD' value='2'>
<input type='hidden' name='LMI_PAYMENT_NO' value='%LMI_PAYMENT_NO%'>
<input type='hidden' name='LMI_PAYMENT_SYSTEM' value='1'>
<input type='hidden' name='at' value='%AT%'>
<input type='hidden' name='LMI_MERCHANT_ID' value='$conf{PAYSYS_PAYMASTER_MERCHANT_ID}'>
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='IP' value='$ENV{REMOTE_ADDR}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>
<input type='hidden' name='LMI_PAYMENT_DESC' value='%LMI_PAYMENT_DESC%'>

	  <th> <br> Оплата по Webmoney <br>  При помощи PayMaster <br>%TEST_MODE% </th>
    <th> <input type='text' name='LMI_PAYMENT_AMOUNT' value='%LMI_PAYMENT_AMOUNT%' size=20/> </th>
	  <th> <input class='button' type='submit' name=pay value='Оплатить'> </th>
</form> 
</tr>
   <tr>
    <th> <img src='http://cs322828.vk.me/v322828943/8107/rYHQgZj76nw.jpg' style='width:60px;height:100px'>   </th>
	  
  
<form id=pay name=pay method='POST' action='%ACTION_URL%'>
<input type='hidden' name='LMI_RESULT_URL' value='$conf{PAYSYS_LMI_RESULT_URL}'>
<input type='hidden' name='LMI_SUCCESS_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1'>
<input type='hidden' name='LMI_SUCCESS_METHOD' value='0'>
<input type='hidden' name='LMI_FAIL_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?FALSE=1&LMI_PAYMENT_NO=%LMI_PAYMENT_NO%&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&index=$index'>
<input type='hidden' name='LMI_FAIL_METHOD' value='2'>
<input type='hidden' name='LMI_PAYMENT_NO' value='%LMI_PAYMENT_NO%'>
<input type='hidden' name='LMI_PAYMENT_SYSTEM' value='17'>
<input type='hidden' name='at' value='%AT%'>
<input type='hidden' name='LMI_MERCHANT_ID' value='$conf{PAYSYS_PAYMASTER_MERCHANT_ID}'>
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='IP' value='$ENV{REMOTE_ADDR}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>
<input type='hidden' name='LMI_PAYMENT_DESC' value='%LMI_PAYMENT_DESC%'>

	  <th> <br> Оплата по Терминалах Украины <br>  При помощи PayMaster <br>%TEST_MODE%</th>
    <th> <input type='text' name='LMI_PAYMENT_AMOUNT' value='%LMI_PAYMENT_AMOUNT%' size=20/> </th>
	  <th> <input class='button' type='submit' name=pay value='Оплатить'> </th>
</form>
  </tr>
  <tr>
    <th> <img src='http://www.userlogos.org/files/logos/Serega1/privat24-4.png' style='width:100px;height:75px'>   </th>
	  
  
<form id=pay name=pay method='POST' action='%ACTION_URL%'>
<input type='hidden' name='LMI_RESULT_URL' value='$conf{PAYSYS_LMI_RESULT_URL}'>
<input type='hidden' name='LMI_SUCCESS_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1'>
<input type='hidden' name='LMI_SUCCESS_METHOD' value='0'>
<input type='hidden' name='LMI_FAIL_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?FALSE=1&LMI_PAYMENT_NO=%LMI_PAYMENT_NO%&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&index=$index'>
<input type='hidden' name='LMI_FAIL_METHOD' value='2'>
<input type='hidden' name='LMI_PAYMENT_NO' value='%LMI_PAYMENT_NO%'>
<input type='hidden' name='LMI_PAYMENT_SYSTEM' value='20'>
<input type='hidden' name='at' value='%AT%'>
<input type='hidden' name='LMI_MERCHANT_ID' value='$conf{PAYSYS_PAYMASTER_MERCHANT_ID}'>
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='IP' value='$ENV{REMOTE_ADDR}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>
<input type='hidden' name='LMI_PAYMENT_DESC' value='%LMI_PAYMENT_DESC%'>

	  <th> <br> Оплата по Privat24 <br>  При помощи PayMaster <br>%TEST_MODE%</th>
    <th> <input type='text' name='LMI_PAYMENT_AMOUNT' value='%LMI_PAYMENT_AMOUNT%' size=20/> </th>
	  <th> <input class='button' type='submit' name=pay value='Оплатить'> </th>
</form>

  </tr>
   <tr>
    <th> <img src='http://e-commerce.com.ua/wp-content/uploads/2009/12/logo-liqpay.png' style='width:100px;height:100px'>   </th>
	  
  
<form id=pay name=pay method='POST' action='%ACTION_URL%'>
<input type='hidden' name='LMI_RESULT_URL' value='$conf{PAYSYS_LMI_RESULT_URL}'>
<input type='hidden' name='LMI_SUCCESS_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1'>
<input type='hidden' name='LMI_SUCCESS_METHOD' value='0'>
<input type='hidden' name='LMI_FAIL_URL' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?FALSE=1&LMI_PAYMENT_NO=%LMI_PAYMENT_NO%&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&index=$index'>
<input type='hidden' name='LMI_FAIL_METHOD' value='2'>
<input type='hidden' name='LMI_PAYMENT_NO' value='%LMI_PAYMENT_NO%'>
<input type='hidden' name='LMI_PAYMENT_SYSTEM' value='19'>
<input type='hidden' name='at' value='%AT%'>
<input type='hidden' name='LMI_MERCHANT_ID' value='$conf{PAYSYS_PAYMASTER_MERCHANT_ID}'>
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='IP' value='$ENV{REMOTE_ADDR}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>
<input type='hidden' name='LMI_PAYMENT_DESC' value='%LMI_PAYMENT_DESC%'>
 	  <th> <br> Оплата по Liqpay <br>  При помощи PayMaster <br>%TEST_MODE% </th>
    <th> <input type='text' name='LMI_PAYMENT_AMOUNT' value='%LMI_PAYMENT_AMOUNT%' size=20/> </th>
	  <th> <input class='button' type='submit' name=pay value='Оплатить'> </th>
</form>

  </tr>
</table>