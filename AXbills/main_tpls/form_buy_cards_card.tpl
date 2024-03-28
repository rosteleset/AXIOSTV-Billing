<div class='col-md-4 col-lg-4 col-xs-12 col-sm-6'>
	<div class='card card-primary card-outline'>
		<div class='card-header with-border' style='text-align:center'>
			<h4 style='margin:0'>
			  <a href='$SELF_URL?BUY_CARDS=1&TP_ID=%TP_ID%&DOMAIN_ID=%DOMAIN_ID%'>_{CARDS}_ %TP_NAME%</a>
			</h4>
		</div>

		<div class='card-body'>
		  <div style='margin-left: 2%; margin-right: 2%'>
			<div class='row'>
			  <label class='col-md-8 col-xs-10'>
		        _{TIME_LIMIT}_ (_{HOURS}_):
		      </label>
		      <div class='col-md-2'>
		        %PREPAID_MINS%
		      </div>
		  	</div>
			<div class='row'>
			  <label class='col-md-8 col-xs-10'>
		        _{PREPAID}_ (Mb):
		      </label>
		      <div class='col-md-2'>
		        %PREPAID_TRAFFIC%
		      </div>
		  	</div>
			<div class='row'>
			  <label class='col-md-8 col-xs-10'>
		        <!-- _{SPEED}_ _{RECV}_: -->
				_{SPEED}_:
		    </label>
		    <div class='col-md-2'>
		      %SPEED_IN%/%SPEED_OUT%
		    </div>
		  	</div>
			<div class='row'>
			  <label class='col-md-8 col-xs-10'>
				_{AGE}_ (_{DAYS}_):
		      </label>
		      <div class='col-md-2 col-xs-2'>
		        %AGE%
		      </div>
		  	</div>
			<div class='row bg-success'>
			  <label class='col-md-8 col-xs-10'>
		        _{PRICE}_:
		      </label>
		      <div class='col-md-2'>
		        %PRICE%
		      </div>
		  	</div> 
			<div class='row' style='text-align: center'>
				<a class='btn btn-primary' href='$SELF_URL?BUY_CARDS=1&TP_ID=%TP_ID%&DOMAIN_ID=%DOMAIN_ID%%HOTSPOT_PARAMS%'>_{BUY}_</a>
			</div>
		  </div>
		</div>
	</div>
</div>




