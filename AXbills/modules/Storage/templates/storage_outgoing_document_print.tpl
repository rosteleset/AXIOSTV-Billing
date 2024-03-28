<script type="text/javascript">
  window.print();
</script>


<table width="100%" border="0" cellspacing="0">

  <tr>
    <td width="50%" style="border:solid; border-width: 1px;">
      <p><b>Постачальник:</b> %SUPPLIER_NAME%</p>
      <p><b>Адреса:</b></p>
      <p><b>Р/рахунок:</b> %SUPPLIER_ACCOUNT%</p>
      <p><b>в</b> %SUPPLIER_BANK_NAME%</p>
      <p><b>МФО:</b>%SUPPLIER_MFO%</p>
      <p><b>ЄДРПОУ:</b>%SUPPLIER_OKPO%</p>
      <p><b>Тел./ф.:</b> %SUPPLIER_PHONE%</p>
    </td>
    <td></td>
    <td align="center" valign="top" width="50%">
      <p>
      <h2>Видаткова Накладна</h2></p>
      <p>
      <h2>N _________________</h2></p>
      <p><b>від "%DAY%" %MONTH% %YEAR% р.</b></p>
    </td>
  </tr>
</table>

<br><br>


<table width="100%">
  <tr>
    <td width="15%"><b>Одержувач</b></td>
    <td width="85%"></td>
  </tr>
  <tr>
    <td width="15%"></td>
    <td style="border-top: 1px solid #000000" colspan=45 align="center" valign=middle bgcolor="#FFFFFF">
      <font face="Arial Narrow">назва, адреса, банківські реквізити</font>
    </td>
  </tr>

  <tr>
    <td width="15%"><b>Платник</b></td>
    <td width="85%"></td>
  </tr>
  <tr>
    <td width="15%"></td>
    <td style="border-top: 1px solid #000000" colspan=45 align="center" valign=middle bgcolor="#FFFFFF">
      <font face="Arial Narrow">назва, адреса, банківські реквізити</font>
    </td>
  </tr>

  <tr>
    <td width="15%"><b>Підстава</b></td>
    <td width="85%"></td>
  </tr>
  <tr>
    <td width="15%"></td>
    <td style="border-top: 1px solid #000000" colspan=45 align="center" valign=middle bgcolor="#FFFFFF">
      <font face="Arial Narrow">№ договору, наряду тощо</font>
    </td>
  </tr>

  <tr>
    <td width="15%"><b>Через кого</b></td>
    <td width="85%"></td>
  </tr>
  <tr>
    <td width="15%"></td>
    <td style="border-top: 1px solid #000000" colspan=45 align="center" valign=middle bgcolor="#FFFFFF">
      <font face="Arial Narrow">ініціали, прізвище, № та дата видачі довіреності</font>
    </td>
  </tr>
</table>

<br><br>
<table width="100%" border="1" cellspacing="0">
  <tr>
    <th>#</th>
    <th>Найменування товару</th>
    <th>Одиниця виміру</th>
    <th>Кількість</th>
    <th>Ціна</th>
    <th>Сума</th>
  </tr>

  <tr>
    <td>1</td>
    <td>%ARTICLE_TYPE% %ARTICLE_NAME%</td>
    <td>%MEASURE_NAME%</td>
    <td>%TOTAL%</td>
    <td>%SELL_PRICE%</td>
    <td>%TOTAL_SUM%</td>
  </tr>

  <tr>
    <td colspan="3"><b>Всього з ПДВ(прописом)</b></td>
    <td colspan="2"><b>Разом</b></td>
    <td></td>
  </tr>
  <tr>
    <td colspan="3"><b></b></td>
    <td colspan="2"><b>ПДВ 20%</b></td>
    <td></td>
  </tr>
  <tr>
    <td colspan="3"><b></b></td>
    <td colspan="2"><b>Всього з ПДВ</b></td>
    <td></td>
  </tr>
</table>

<br><br>

<table width="100%">
  <tr>
    <td width="50%"><b>Відвантажив(ла):</b> _______________________</td>
    <td width="50%"><b>Отримав(ла):</b> ___________________________</td>
  </tr>
</table>