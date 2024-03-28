<div class='d-print-none'>
<a name='TP_FORM'></a> 
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='%TP_ID%'>
<input type=hidden name='TI_ID' value='%TI_ID%'>

<table border='0'>
  <tr><th colspan=3 class=form_title>%LNG_ACTION% _{TARIF_PLAN}_</th></tr>
<!--  <tr><th>#</th><td><input type='text' name='CHG_TP_ID' value='%TP_ID%'></td></tr> -->

  <tr><td>_{NAME}_:</td><td colspan=2><input type=text name=NAME value='%NAME%' size=30></td></tr>
  <tr><td>_{PRICE}_:</td><td colspan=2><input type=text name=PRICE value='%PRICE%' size=30></td></tr>
  <tr><td>_{GUEST_ACCOUNT}_:</td><td colspan=2><input type=checkbox name=PAYMENT_TYPE value='2' %PAYMENT_TYPE%></td></tr>

  <tr><td colspan=3 class=small bgcolor=$_COLORS[9]></td></tr> 
  <!-- <tr><td>_{PAYMENT_TYPE}_:</td><td colspan=2>%PAYMENT_TYPE_SEL%</td></tr> -->
  
<!--  
  <tr><td>_{MAX_SESSION_DURATION}_ (sec.):</td><td colspan=2><input type=text name=MAX_SESSION_DURATION value='%MAX_SESSION_DURATION%'></td></tr>
  <tr><td>_{FILTERS}_:</td><td colspan=2><input type=text name=FILTER_ID value='%FILTER_ID%'></td></tr>
-->
  <tr><td>_{AGE}_ (_{DAYS}_, 0=_{UNLIMITED}_):</td><td colspan=2><input type=text name=AGE value='%AGE=0%' size=10></td></tr>


<!--  <tr><td>_{UPLIMIT}_:</td><td colspan=2><input type=text name=ALERT value='%ALERT%'></td></tr>
  <tr><th colspan=3 bgcolor=$_COLORS[0]>_{ABON}_</th></tr>
  <tr><td>_{DAY_FEE}_:</td><td colspan=2><input type=text name=DAY_FEE value='%DAY_FEE%'></td></tr>
  <tr><td>_{POSTPAID}_:</td><td colspan=2><input type=checkbox name=POSTPAID_DAY_FEE value=1 %POSTPAID_DAY_FEE%></td></tr>

  <tr bgcolor=$_COLORS[2]><td>_{MONTH_FEE}_:</td><td colspan=2><input type=text name=MONTH_FEE value='%MONTH_FEE%'></td></tr>
  <tr bgcolor=$_COLORS[2]><td>_{POSTPAID}_:</td><td colspan=2><input type=checkbox name=POSTPAID_MONTH_FEE value=1 %POSTPAID_MONTH_FEE%></td></tr>
-->

 
  <tr><th colspan=3 bgcolor=$_COLORS[0]>_{TIME_LIMIT}_</th></tr>
  <tr><td>_{TOTAL}_</td><td colspan=2>
  <input type=radio name=TOTAL_TIME_TYPE value='0' %PERIOD_30M=checked%> _{MINUTES}_: <input type=text name=MINUTES value='%MINUTES=30%' size=6><br>
  <input type=radio name=TOTAL_TIME_TYPE value='1' %PERIOD_1H%> _{HOURS}_: <input type=text name=HOURS value='%HOURS=1%' size=6><br>
  <input type=radio name=TOTAL_TIME_TYPE value='2' %PERIOD_1D%> _{DAYS}_: <input type=text name=DAYS value='%DAYS=1%' size=6><br>
  </td></tr>
<!--
  <tr><td>_{DAY}_</td><td colspan=2><input type=text name=DAY_TIME_LIMIT value='%DAY_TIME_LIMIT%'></td></tr>
  <tr><td>_{WEEK}_</td><td colspan=2><input type=text name=WEEK_TIME_LIMIT value='%WEEK_TIME_LIMIT%'></td></tr>
  <tr><td>_{TOTAL}_</td><td colspan=2>
  
  <input type=radio name=MONTH_TIME_LIMIT value='900'>  15 _{MIN}_<br>
  <input type=radio name=MONTH_TIME_LIMIT value='1800'> 30 _{MIN}_<br>
  <input type=radio name=MONTH_TIME_LIMIT value='3600'> 60 _{MIN}_<br>
  <input type=radio name=MONTH_TIME_LIMIT value='7200'>120 _{MIN}_<br>
  <input type=text name=MONTH_TIME_LIMIT value='%MONTH_TIME_LIMIT%'> _{SEC}_</td></tr>

  <tr><td>_{HOUR_TARIF}_ (0.00)</td><td colspan=2><input type=text name=TI_TARIF value='%TI_TARIF%'></td></tr>
-->

  <tr><th colspan=3 bgcolor=$_COLORS[0]>_{TRAF_LIMIT}_ (Mb)</th></tr>
  <tr><td>_{DAY}_ (0=_{UNLIMITED}_)):</td><td colspan=2><input type=text name=DAY_TRAF_LIMIT value='%DAY_TRAF_LIMIT%' size=10></td></tr>
<!--  <tr><td>_{WEEK}_</td><td colspan=2><input type=text name=WEEK_TRAF_LIMIT value='%WEEK_TRAF_LIMIT%'></td></tr>
      <tr><td>_{MONTH}_</td><td colspan=2><input type=text name=MONTH_TRAF_LIMIT value='%MONTH_TRAF_LIMIT%'></td></tr>
-->  
  <tr><td>_{TOTAL}_ (0=_{UNLIMITED}_)):</td><td colspan=2><input type=text name=TOTAL_TRAF_LIMIT value='%TOTAL_TRAF_LIMIT%' size=10></td></tr>
  <tr><td>_{OCTETS_DIRECTION}_</td colspan=2><td>%SEL_OCTETS_DIRECTION%</td></tr>

<!--
  <tr><td rowspan=2>_{TRAFIC_TARIFS}_ (1 Mb):</td><td>IN</td><td><input size=12 type=text name='TT_PRICE_IN' value='%TT_PRICE_IN%'></td></tr>
  <tr><td>OUT:</td><td><input type=text size=12 name='TT_PRICE_OUT' value='%TT_PRICE_OUT%'></td></tr>
-->
<!--  <tr><td colspan=2>_{PREPAID}_ (Mb):</td><td><input type=text size=12 name='TT_PREPAID' value='%TT_PREPAID%'></td></tr> -->

  <tr><td rowspan=2>_{SPEED}_ (Kbits):</td><td colspan=2>IN: <input type=text size=12 name='TT_SPEED_IN' value='%TT_SPEED_IN=512%'></td></tr>
  <tr><td  colspan=2>OUT: <input type=text size=12 name='TT_SPEED_OUT' value='%TT_SPEED_OUT=256%'></td></tr>





</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>
