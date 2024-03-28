<form action='$SELF_URL'>
<input type='hidden' name='index' value='$index'>
<div class='card card-primary card-outline box-form form-horizontal'>
    <div class='card-header'>
      <h4>SNMP Информация</h4>
    </div>
    
    <div class='card-body'>
      
      <div class='form-group'>
        <label class='control-label col-md-4' for='SNMP_HOST'>SNMP Host</label>
        <div class='col-md-8'>
         <input class='form-control' type='text' name='SNMP_HOST' value='%SNMP_HOST%'>
        </div>
      </div>
        
      <div class='form-group'>
        <label class='control-label col-md-4' for='SNMP_COMMUNITY'>SNMP Community</label>
        <div class='col-md-8'>
     <input class='form-control' type='text' name='SNMP_COMMUNITY' value='%SNMP_COMMUNITY%'>
        </div>
       </div>


      <div class='form-group'>
        <label class='control-label col-md-4'>_{NAS}_</label>
        <div class='col-md-8'>%NAS_SEL%</div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-4' for='SNMP_OID'>SNMP OID</label>
        <div class='col-md-8'>
         <input class='form-control' type='text' name='SNMP_OID' value='%SNMP_OID%'>
        </div>
      </div> 
        
      <div class='form-group'>
        <label class='control-label col-md-4'>_{TYPE}_</label>
        <div class='col-md-8'>%TYPE_SEL%</div>
      </div>             
        
      <div class='form-group'>
        <label class='control-label col-md-4'>MIBS</label>
        <div class='col-md-8'>%MIBS%</div>
      </div>             
        
      <div class='form-group'>
        <label class='control-label col-md-4'>DEBUG</label>
        <div class='col-md-8'>%DEBUG_SEL%</div>
      </div>
        
    </div>
                
    <div class='card-footer'>
    <input class='btn btn-primary' type='submit' name='SHOW' value='_{SHOW}_'>
    </div>
</div>
</form>
  