<form action=$SELF_URL METHOD=POST class='form-horizontal'>
<input type='hidden' name='module' value='Employees'>
<input type='hidden' name='FIO' value=%FIO%>
<input type='hidden' name='DATE' value=%DATE%>
<input type='hidden' name='MAIL' value=%MAIL%>
<input type='hidden' name='PHONE' value=%PHONE%>
<input type='hidden' name='POSITION' value=%POSITION%>

	<div class='card box-primary '>
		<!-- head -->
	  <div class='card-header big-box with-border'><h3 class='card-title'>_{EMPLOYEE_PROFILE}_</h3></div>
	  <!-- body -->
	  <div class='card-body'>
%LIST_OF_QUESTION%
	  <!-- footer -->
	  <div class='card-footer'>

	  	<p class='text-center'><input type='submit' class='btn btn-primary pull-center' name='add_data' value='_{NEXT}_'></p>

	</div>

</form>
