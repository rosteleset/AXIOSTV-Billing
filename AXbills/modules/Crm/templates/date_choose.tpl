<form >
<input type='hidden' name='index' value='$index'>
  <div class='box box-theme box-form form-horizontal'>
    <div class='box-body'>

      <div class='form-group'>
        <label class='control-label col-md-3'>_{MONTH}_</label>
        <div class='col-md-9'>
        %MONTH%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3'>_{YEAR}_</label>
        <div class='col-md-9'>
        %YEAR%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3'>_{POSITION}_</label>
        <div class='col-md-9'>
          %POSITIONS%
        </div>
      </div>

    </div>
    <div class='box-footer'>
      <input type='submit' name='FILTER' value='_{SHOW}_' class='btn btn-primary'>
    </div>
  </div>
</form>

%TABLE%


<script type="text/javascript">
  jQuery(function () {
    jQuery( "tr" ).off("click");
    jQuery('#CRM_SALARY').removeClass('table-hover');
    jQuery("i.tree-button").on("click", function(){
      var spantd = jQuery(this).closest('tr').find("td");
      if(jQuery(spantd).children('div').css('display') == 'none') {
        jQuery(spantd).children('div').show();
        jQuery(spantd).children('span').hide();
        jQuery(this).css('color', 'red');
        jQuery(this).removeClass('fa-plus-circle');
        jQuery(this).addClass('fa-minus-circle');
      }
      else {
        console.log("TEST");
        jQuery(spantd).children('div').hide();
        jQuery(spantd).children('span').show();
        jQuery(this).css('color', 'green');
        jQuery(this).removeClass('fa-minus-circle');
        jQuery(this).addClass('fa-plus-circle');
      }
    });

    jQuery("i.tree-button").hover(function() {
      jQuery(this).css('cursor','pointer');
    }, function() {
      jQuery(this).css('cursor','auto');
    });
  });

</script>