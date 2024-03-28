<script language='JavaScript'>
	function autoReload()	{ 	
        document.storage_logs.submit();
	}	
</script>
<form action=$SELF_URL?index=$index\&add_order=1  name='storage_logs' method=POST >
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<input type=hidden name=INCOMING_ID value=%INCOMING_ID%>
<input type=hidden name='type' value='prihod2'>
<input type=hidden name='add_order' value='1'>
%CHG%
<table border='0' >
  <tr><h1>storage_orders.tpl</h1>
    <td>_{TYPE}_:</td>
    <td>%ARTICLE_TYPES%</td>
  </tr>
  <tr>
    <td>_{NAME}_:</td>
    <td>%ARTICLE_ID%</td>
  </tr>
   <tr>
    <td>���-�� ������:</td>
    <td><input name='COUNT' type='text' value='%COUNT%' %DISABLED% /></td>
  </tr>
    <tr>
    <td>_{COMMENTS}_</td>
    <td><textarea name='COMMENTS'>%COMMENTS%</textarea></td>
  </tr>
</table>
<br />
<input type=submit name=%ACTION% value=%ACTION_LNG%>
</form>