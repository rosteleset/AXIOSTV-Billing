<form action=$FORM{Action} method='post'>

	<input type=hidden name=action value='create_payment'>
	<input type=hidden name=index value='$index'>
    <input type=hidden name=PAYMENT_SYSTEM value='109'>
	<input type=hidden name=server_callback_url value=%Server_callback_url%>
	<input type=hidden name=response_url value=%Response_url%>
	<input type=hidden name=order_id value=%Order_id%>
	<input type=hidden name=order_desc value=%Order_desc%>
	<input type=hidden name=currency value=%Currency%>
	<input type=hidden name=amount value=%Amount%>
	<input type=hidden name=signature value=%Signature%>
	<input type=hidden name=merchant_id value=%Merchant_id%>
	<input type=hidden name=merchant_data value=%Merchant_data%>
	<input type=hidden name=required_rectoken value=%Required_rectoken%>
	
<div class='box box-primary'>
    <div class='box-header with-border text-center'>_{BALANCE_RECHARCHE}_</div>

<div class='box-body'>
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'>_{ORDER}_:</label>
        <label class='col-md-6 control-label'>%Order_id%</label>
    </div>
    
    <div class='form-group'>
        <label class='col-md-6 control-label text-center'> _{PAY_SYSTEM}_:</label>
        <label class='col-md-6 control-label'>FONDY</label>
    </div>
    
    <div class='form-group'>
        <label class='control-label col-md-6 text-center'>_{SUM}_:</label>
        <label class='control-label col-md-6'> %Sum% </label>
    </div>
	%Checkbox%
</div>
    <div class='box-footer'>
        <input class='btn btn-primary' type=submit value=$FORM{Confirm}>
    </div>
</div>    
</form>