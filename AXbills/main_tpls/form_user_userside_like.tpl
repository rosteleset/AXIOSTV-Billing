    <div class="row">
    	<div class="col-md-12">
            <div class="panel with-nav-tabs panel-default">
                <div class="panel-heading">
                        <ul class="nav nav-tabs">
                            <li class="active"><a href="#tab1default" data-toggle="tab">_{GENERAL}_</a></li>
                            <li><a href="#tab2default" data-toggle="tab">_{ACTIVITY}_</a></li>
                            <li><a href="#tab3default" data-toggle="tab">_{NOTES}_</a></li>
                        </ul>
                </div>
                <div class="panel-body">
                    <div class="tab-content">
                        <div class="tab-pane fade in active" id="tab1default">
							<div class='card col-md-12'>
							  <div class='card-header with-border'><h6 class='card-title'>%FIO%</h6></div>
							  <div class='card-body'>
									
								<!-- 	<div class="row col-md-12 text-left">
										<btn class="fa fa-wrench text-primary"> </btn> <a href="#">_{CREATE_TASK}_</a> <br>
									</div> -->

									<div class="col-md-6">

							      	<div class='row'>
							        <label class='col-md-6 text-right'>_{FIO}_:</label>
							        <div class='col-md-6 text-left'>
							            %FIO%
							        </div>
									</div>

							      	<div class='row'>
							        <label class='col-md-6 text-right'>_{LOGIN}_:</label>
							        <div class='col-md-6 text-left'>
							            	%LOGIN%
							        </div>
									</div>

							      	<div class='row'>
							        <label class='col-md-6 text-right'>_{CONTRACT}_:</label>
							        <div class='col-md-6 text-left'>
							            %CONTRACT_ID%%CONTRACT_SUFIX%%NO_CONTRACT_MSG%
							        </div>
									</div>		

							      	<div class='row'>
							        <label class='col-md-6 text-right'>_{NETWORK_ACTIVITY}_:</label>
							        <div class='col-md-6 text-left text-success'>
							            	%END%
							        </div>
									</div>	

									<div class='row'>
							        <label class='col-md-6 text-right'>_{DATE_CONNECTION}_:</label>
							        <div class='col-md-6 text-left'>
							            %ACTIVATE%
							        </div>
									</div>

									<div class='row'>
							        <label class='col-md-6 text-right'>_{STATUS}_</label>
							        <div class='col-md-6 text-left'>
							             %STATUS_USER%
							        </div>
									</div>			

									</div>

									<div class="col-md-6">
										
									<div class='row'>
							        <label class='col-md-6 text-right'>_{BALANCE}_:</label>
							        <div class='col-md-6 text-left text-success text-uppercase dl-horizontal'>
							            		%DEPOSIT%
							        </div>
									</div>	

									<div class='row'>
							        <label class='col-md-6 text-right'>_{PAYMENTS}_:</label>
							        <div class='col-md-6 text-left '>
							            		%PAYMENTS%
							        </div>
									</div>	

									<div class='row'>
							        <label class='col-md-6 text-right'>_{CREDIT}_:</label>
							        <div class='col-md-6 text-left '>
							            		%CREDIT%
							        </div>
									</div>	

									<div class='row'>
							        <label class='col-md-6 text-right'>_{REDUCTION}_:</label>
							        <div class='col-md-6 text-left '>
							            		%REDUCTION%
							        </div>
									</div>		

									<div class='row'>
							        <label class='col-md-6 text-right'>_{TARIF_PLAN}_:</label>
							        <div class='col-md-6 text-left'>
							            %TARIFF%
							        </div>
									</div>	

<!-- 									<div class='row'>
							        <label class='col-md-6 text-right'>_{INTERNET}_:</label>
							        <div class='col-md-6 text-left'>
							            </i>[%TP_NUM%] <b>%TP_NAME%</b>
							        </div>
									</div>		 -->

									

									</div>


							      
							  </div>
							</div>

							<div class='card col-md-12'>
							  <div class='card-header with-border'><h6 class='card-title'>IP/MAC-_{ADDRESS}_</h6></div>
							  <div class='card-body'>

							      	<div class='row'>
							        <div class='col-md-6 text-left'>
							           %IP_MAC%
							        </div>
									</div>				

							  </div>
							</div>

							<div class='card col-md-12'>
							  <div class='card-header with-border'><h6 class='card-title'>_{CONTACT_INFORMATION}_</h6></div>
							  <div class='card-body'>

								<div class="col-md-6">

							      	<div class='row'>
							        <label class='col-md-6 text-right'>_{ADDRESS}_:</label>
							        <div class='col-md-6 text-left'>
							            	%ADDRESS% 
							        </div>
									</div>

									 <form name='%FORM_NAME%' id='form_%FORM_NAME%' method='post' class='form form-horizontal'>
									 <input type='hidden' name='index' value='$index' />
									 <input type='hidden' name='UID' value='%UID%' />
							      	  <div class='form-group'>
							      	      <label class='control-label col-md-6 text-right' for='COMMENTS_ID'>_{NOTES}_</label>
							      	      <div class='col-md-6'>
							      	          <textarea class='form-control col-md-6 text-left'  rows='2'  name='COMMENTS' id='COMMENTS_ID'>%NOTES%</textarea>
							      	      </div>
							      	  </div>
							      	</form>

							    	<div class='row'>
							        <label class='col-md-6 text-right'></label>
							        <div class='col-md-6'>
							            <input type='submit' form='form_%FORM_NAME%' class='btn btn-primary btn-sm col-md-6 text-center' name='submit' value='Зберегти'>
							        </div>
									</div>



								</div>
								<div class="col-md-6">
							      	<div class='row'>
							        <label class='col-md-6 text-right'>_{PHONE}_:</label>
							        <div class='col-md-6 text-left'>
							            	%PHONE%
							        </div>
									</div>			

<!-- 									<div class='row'>
							        <label class='col-md-6 text-right'>Надсилати SMS:</label>
							        <div class='col-md-6 text-left'>
							            	Так
							        </div>
									</div>	 -->	

									<div class='row'>
							        <label class='col-md-6 text-right'>E-mail:</label>
							        <div class='col-md-6 text-left'>
							            		%EMAIL%
							        </div>
									</div>	

								</div>



							  </div>
							</div>

							<div class='card col-md-12'>
							  <div class='card-header with-border'><h6 class='card-title'>_{ADDITIONAL_DATA}_</h6></div>
							  <div class='card-body'>

								<div class="col-md-6">
							      	<div class='row'>
							        <label class='col-md-6 text-right'>_{MEMO}_:</label>
							        <div class='col-md-6 text-left'>
							            %MEMO%
							        </div>
									</div>
								</div>	

								<div class="col-md-6">
							      	<div class='row'>
							        <label class='col-md-6 text-right'>_{MEMO}_ (PDF):</label>
							        <div class='col-md-6 text-left'>
							            %MEMO_PDF%
							        </div>
									</div>
								</div>	
								
								<div class="col-md-6">
							      	<div class='row'>
							        <label class='col-md-6 text-right'>_{CONTRACT}_:</label>
							        <div class='col-md-6 text-left'>
							            %CONTRACT%
							        </div>
									</div>	
								

							     <div class='row'>
							        <label class='col-md-6 text-right'>_{STATMENT_OF_ACCOUNT}_:</label>
							        <div class='col-md-6 text-left'>
							             %STATEMENT_OF_ACCOUNT%
							        </div>
								</div>

							      	<!-- <div class='row'>
							        <label class='col-md-6 text-right'>_{DRESS_FOR_WORK}_:</label>
							        <div class='col-md-6 text-left'>
							            <span class="fa fa-list-alt text-primary">
							        </div>
									</div> -->
								</div>

							  </div>
							</div>

							<div class='card col-md-12'>
							  <div class='card-header with-border'><h6 class='card-title'>_{TECHNICAL_DATA}_</h6></div>
							  <div class='card-body'>

								<div class="col-md-6">

							      	<div class='row'>
							        <label class='col-md-6 text-right'>_{SPEED}_(kb):</label>
							        <div class='col-md-6 text-left'>
							            %SPEED_U%
							        </div>
									</div>

<!-- 							      	<div class='row'>
							        <label class='col-md-6 text-right'>Метраж кабелю:</label>
							        <div class='col-md-6 text-left'>
							            54
							        </div>
									</div>	 -->	

									<div class='row'>
							        <label class='col-md-6 text-right'>_{GROUPS}_:</label>
							        <div class='col-md-6 text-left'>
							            %GROUP_BTN%
							        </div>
									</div>
<!-- 
							      	<div class='row'>
							        <label class='col-md-6 text-right'>ID:</label>
							        <div class='col-md-6 text-left'>
							            	%UID%
							        </div>
									</div> -->

							      	<div class='row'>
							        <label class='col-md-6 text-right'>_{REGISTRATION}_:</label>
							        <div class='col-md-6 text-left'>
							            	%REGISTRATION%
							        </div>
									</div>

								</div>

								<div class="col-md-6">

<!-- 							      	<div class='row'>
							        <label class='col-md-6 text-right'>Дата входу до персонального кабінету:</label>
							        <div class='col-md-6 text-left'>
							            	н.д.
							        </div>
									</div>		 -->

									<div class='row'>
							        <label class='col-md-6 text-right'>_{PASSWD}_:</label>
							        <div class='col-md-6 text-left'>
							            	%PASSWD_BTN%
							        </div>
									</div>		

								</div>

								<div class="row col-md-12 text-left">
<!-- 									<br><btn class="fa fa-pencil-alt text-primary"> </btn> <a href="#">_{EDIT}_</a>
									<br><btn class="fa fa-wrench text-primary"> </btn> <a href="#">Відмітки на абоненті</a> 
									<br><btn class="fa fa-bullhorn text-primary"> </btn> <a href="#">Рекламні кампанії</a>  -->
								</div>

							  </div>
							</div>
                    	</div>
                       	<div class="tab-pane fade" id="tab2default">
                       		%TABLE%
                       	</div>
                        <div class="tab-pane fade" id="tab3default">
                        	%INFO_COMMENTS_SHOW%
                        </div>
                    </div>
                </div>
            </div>
        </div>
