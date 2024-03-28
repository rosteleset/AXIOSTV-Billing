<form action='$SELF_URL' name='company_profile' METHOD='POST' ENCTYPE='multipart/form-data'>
  <input type='hidden' name='ID' value='$FORM{COMPANY_ID}'/>

  %DASHBOARD%
  <div class='row'>
    <section id='left-column' class='ui-sortable-forms col-md-12 col-lg-6' style="min-height: 500px">
      %LEFT_PANEL%
    </section>
    <section id='right-column' class='ui-sortable-forms col-md-12 col-lg-6 ' style="min-height: 500px">
      %RIGHT_PANEL%
    </section>
  </div>

</form>