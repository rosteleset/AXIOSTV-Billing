<div class='col-xs-12 col-md-6'>
  <div class='card card-primary card-outline box-big-form'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{MESSAGES}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4' for='MSG_ID'>ID:</label>
        <div class='col-md-4'>
          <input id='MSG_ID' name='MSG_ID' value='%MSG_ID%' placeholder='%MSG_ID%' class='form-control'
                 type='text'>
        </div>

        <label class='col-form-label text-md-right col-md-3' for='INNER_MSG'>_{PRIVATE}_:</label>
        <div class='col-md-1'>
          <input type=checkbox id='INNER_MSG' name='INNER_MSG' value=1 %INNER_MSG%>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4' for='CHAPTER_ID'>_{CHAPTERS}_:</label>
        <div class='col-md-8'>
          %CHAPTER_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4' for='SUBJECT'>_{SUBJECT}_:</label>
        <div class='col-md-8'>
          <input id='SUBJECT' name='SUBJECT' value='%SUBJECT%' placeholder='%SUBJECT%' class='form-control'
                 type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4' for='SEARCH_MSGS_BY_WORD'>_{MESSAGE}_:</label>
        <div class='col-md-8'>
          <input id='SEARCH_MSGS_BY_WORD' name='SEARCH_MSGS_BY_WORD' value='%SEARCH_MSGS_BY_WORD%'
                 placeholder='%SEARCH_MSGS_BY_WORD%' class='form-control'
                 type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4' for='STATE'>_{STATE}_:</label>
        <div class='col-md-8'>
          %STATE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4' for='PRIORITY'>_{PRIORITY}_:</label>
        <div class='col-md-8'>
          %PRIORITY_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>_{CLOSED}_ _{PERIOD}_:</label>
        <div class='col-md-3'>
          <input id='CLOSED_FROM_DATE' name='CLOSED_FROM_DATE' value='%CLOSED_FROM_DATE%'
                 placeholder='%CLOSED_FROM_DATE%' class='form-control datepicker' type='text'>
        </div>
        <label class='col-form-label text-md-center col-md-2'>-</label>
        <div class='col-md-3'>
          <input id='CLOSED_TO_DATE' name='CLOSED_TO_DATE' value='%CLOSED_TO_DATE%'
                 placeholder='%CLOSED_TO_DATE%' class='form-control datepicker' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4' for='MSGS_TAGS'>_{MSGS_TAGS}_:</label>
        <div class='col-md-6'>
          %MSGS_TAGS_SEL%
        </div>
        <div class='col-md-2'>
          %MSGS_TAGS_STATEMENT%
        </div>
      </div>


      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>_{EXECUTION}_:</label>
        <div class='col-md-3'>
          <input id='PLAN_FROM_DATE' name='PLAN_FROM_DATE' value='%PLAN_FROM_DATE%'
                 placeholder='%PLAN_FROM_DATE%' class='form-control datepicker' type='text'>
        </div>
        <label class='col-form-label text-md-center col-md-2'>-</label>
        <div class='col-md-3'>
          <input id='PLAN_TO_DATE' name='PLAN_TO_DATE' value='%PLAN_TO_DATE%' placeholder='%PLAN_TO_DATE%'
                 class='form-control datepicker' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4' for='RESPOSIBLE'>_{RESPOSIBLE}_:</label>
        <div class='col-md-8'>
          %RESPOSIBLE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4' for='ADMIN'>_{ADMIN}_:</label>
        <div class='col-md-8'>
          %ADMIN_SEL%
        </div>
      </div>
    </div>
  </div>
</div>

