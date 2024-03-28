<div class='card card-primary card-outline collapsed-box %PARAMS%' form='internet_users_list'>
 <div class='card-header with-border'>
   <h4 class='card-title'>_{MULTIUSER_OP}_</h4>
   <div class='card-tools float-right'>
     <button type='button' id='mu_status_box_btn' class='btn btn-secondary btn-xs' data-card-widget='collapse'><i class='fa fa-plus'></i>
     </button>
   </div>
 </div>

 <div class=' box-body' id='daasd' style="height: 380px">

   <div class='form-group'>
    <div class='row'>
     <div class='col-md-4'>
      %MU_STATUS_CHECKBOX%
      _{STATUS}_
    </div>
    <div class='col-md-8'>
      %MU_STATUS_SELECT%
    </div>
  </div>
</div>

<div class='form-group'>
  <div class='row'>
   <div class='col-md-4'>
    %MU_TP_CHECKBOX%
    _{TARIF_PLAN}_
  </div>
  <div class='col-md-8'>
    %MU_TP_SELECT%
  </div>
</div>
</div>

<div class='form-group'>
  <div class='row'>
   <div class='col-md-4'>
    %MU_DATE_CHECKBOX%
    _{EXPIRE}_
  </div>
  <div class='col-md-8'>
    %MU_DATE%
  </div>
</div>
</div>
<input name="DV_MULTIUSER" form='internet_users_list' value="_{ACCEPT}_" class="btn btn-primary" type="submit">
</div>
</div>
</form>