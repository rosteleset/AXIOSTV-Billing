<!--START KTK-39 -->

<form class='form-horizontal'>
<input type='hidden' name='index' value='$index'>
  
    <div class='card card-primary card-outline box-form'>
      <div class='card-header with-border'><h3 class='card-title'>%TITLE%</h3>
        <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>  
        <div class='form-group' %DATE_FIELD%>
          <label class='control-label' for='FROM_DATE'>_{FROM}_ :</label>
          <div>
            <input class='form-control' data-provide='datepicker' data-date-format='yyyy-mm-dd' value='%FROM_DATE%' name='FROM_DATE'>
          </div>
          <label class='control-label' for='TO_DATE'>_{TO}_ :</label>
          <div>
            <input class='form-control' data-provide='datepicker' data-date-format='yyyy-mm-dd' value='%TO_DATE%' name='TO_DATE'>
          </div>
        </div>
      
        <div class='form-group' %IP_FIELD%>
          <label class='control-label' for='IP_NUM'>IP :</label>
          <div>
            <input name='IP_NUM' value='%IP_NUM%' class='form-control' type='text'>
          </div>
        </div>
        
        <div class='form-group' %IP_FIELD%>
          <label class='control-label' for='CID'>CID :</label>
          <div>
            <input name='CID' value='%CID%' class='form-control' type='text'>
          </div>
        </div>
      
        <div class='form-group'>
          <label class='control-label' for='LOGIN'>_{LOGIN}_ :</label>
          <div>
            <input name='LOGIN' value='%LOGIN%' class='form-control' type='text'>
          </div>
        </div>
      
        <div class='form-group'>
          <label class='control-label' for='FIO'>_{FIO}_ :</label>
          <div>
            <input name='FIO' value='%FIO%' class='form-control' type='text'>
          </div>
        </div>
      
        <div class='form-group'>
          <label class='control-label' for='COMPANY_NAME'>_{COMPANY}_ :</label>
          <div>
            <input name='COMPANY_NAME' value='%COMPANY_NAME%' class='form-control' type='text'>
          </div>
        </div>
      
        <div class='form-group'>
          <label class='control-label' for='ADDRESS_FULL'>_{ADDRESS}_ :</label>
          <div>
            <input name='ADDRESS_FULL' value='%ADDRESS_FULL%' class='form-control' type='text'>
          </div>
        </div>
      </div>
      <div class='card-footer'>
        <input type=submit name=search value='_{SEARCH}_' class='btn btn-primary'>
      </div>  
    </div>
</form>

<!--END KTK-39 -->
