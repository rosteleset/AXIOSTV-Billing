%DASHBOARD%
<div class='row'>
  <section id='left-column' class='ui-sortable-forms col-md-12 col-lg-6' style="min-height: 500px">
    %LEFT_PANEL%
  </section>
  <section id='right-column' class='ui-sortable-forms col-md-12 col-lg-6 ' style="min-height: 500px">
    %RIGHT_PANEL%
  </section>
  <div class='col-md-12 col-lg-12'>
    %SERVICE_INFO_3%
  </div>
</div>
<script>
  jQuery( function() {
    jQuery( ".ui-sortable-forms" ).sortable({
      connectWith: ".ui-sortable-forms",
      handle: ".card-header",
      cursor: "move",
      placeholder: "portlet-placeholder ui-corner-all"
    });
    jQuery(".card-header").hover(function() {
      jQuery(this).css('cursor','pointer');
    }, function() {
      jQuery(this).css('cursor','auto');
    });


    //  Left schema save to DB
    jQuery('#left-column').on("sortupdate", function (event, ui) {
      saveSchema();
    });

    //Right schema save to DB
    jQuery('#right-column').on("sortupdate", function (data) {
      saveSchema();
    });
  } );

  function saveSchema() {
    var formData  = '';
    var formData1 = '';
    var formData2 = '';

    // save left schema
    jQuery("#left-column").find("div.for_sort").each(function(){
      formData1 += ',' + this.id ;
    });
    if (formData1 === '') {
      formData1 = 'empty';
    }
    //  save right schema
    jQuery("#right-column").find("div.for_sort").each(function(){
      formData2 += ',' + this.id ;
    });
    if (formData2 === '') {
      formData2 = 'empty';
    }

    /* Send Data */
    formData = '?get_index=set_admin_params&header=2&LSCHEMA=1&VALUE_LEFT=' + formData1 + '&RSCHEMA=1&VALUE_RIGHT=' + formData2;
    jQuery.post('/admin/index.cgi', formData, function () {
    });
  }
</script>
