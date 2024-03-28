<script src='/styles/default/js/modules/poll.js'></script>
<form action=$SELF_URL METHOD=POST class='form-horizontal' id='POLL_ANSWER_FORM'>

<input type='hidden' name='index' value="%INDEX%">
<input type='hidden' name='action' value=%ACTION%>
<input type='hidden' name='id' value='%ID%'>
%JSON%

<div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{POLL}_</h4></div>

<div class='card-body'>
  <div class='form-group'>
      <label class='col-md-3 control-label required'>_{SUBJECT}_</label>
  	<div class='col-md-9'>
        <input class='form-control' type='text' name='SUBJECT' value='%SUBJECT%' placeholder='_{POLL_SUBJECT}_'
               %DISABLE% required='required'  >
  	</div>
  </div>
  <div class='form-group'>
      <label class='col-md-3 control-label'>_{DESCRIPTION}_</label>
  	<div class='col-md-9'>
        <textarea class='form-control' type='text' name='DESCRIPTION' placeholder='_{POLL_DESCRIPTION}_'
                  %DISABLE%  maxlength='200' >%DESCRIPTION%</textarea>
  	</div>
  </div>
  <div class='form-group'>
      <label class='col-md-3 control-label'>_{STATUS}_</label>
  	<div class='col-md-9'>
  		%STATUS%
  	</div>
  </div>
  <div class='form-group'>
      <label class='col-md-3 control-label'><span id='answerLabel'>_{ANSWER}_</span> 1</label>
  	<div class='col-md-9'>
        <input class='form-control' type='text' name='ANSWER' value='%ANSWER_1%' placeholder='_{ANSWER}_' %DISABLE%
               required='required'>
  	</div>
  </div>
  <div class='form-group'>
      <label class='col-md-3 control-label'>_{ANSWER}_ 2</label>
  	<div class='col-md-9'>
        <input class='form-control' type='text' name='ANSWER' value='%ANSWER_2%' placeholder='_{ANSWER}_' %DISABLE%
               required='required'>
  	</div>
  </div>
  <div id='extraAnswerWrapper'></div>
  <div class='form-group'>
     <label class='col-md-3 control-label'>_{EXPIRATION_DATE}_</label>
     <div class='col-md-9'>
       <input id='EXPIRATION_DATE' name='EXPIRATION_DATE' value='%EXPIRATION_DATE%' placeholder='%EXPIRATION_DATE%' class='form-control datepicker' %DISABLE% type='text'/>
     </div>
  </div>
 </form>

  <div class='form-group %HIDDEN%' id='extraAnswerControls' style='margin-right: 15px;'>
      <div class='text-right'>
          <div class='btn-group btn-group-xs'>
              <button class='btn btn-xs btn-danger' id='removeAnswerBtn'
                      data-tooltip='_{DEL_POLL_ANSWER}_'
                      data-tooltip-position='bottom'>
                  <span class='fa fa-times'></span>
              </button>
              <button class='btn btn-xs btn-success' id='addAnswerBtn'
                      data-tooltip='_{ADD_POLL_ANSWER}_'>
                  <span class='fa fa-plus'></span>
              </button>
          </div>
      </div>
  </div>
</div>

<div class='card-footer'>
  <button  form='POLL_ANSWER_FORM' type='submit' class='btn btn-primary'>%BUTTON%</button>
</div>

</div>

