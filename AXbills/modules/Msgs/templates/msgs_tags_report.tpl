%TABLE%


<script type="text/javascript">
  jQuery(function () {
    jQuery( "tr" ).off("click");
    jQuery('#MSGS_TAGS_REPORTS_').removeClass('table-hover');
    jQuery("i.tree-button").on("click", function(){
      var spantd = jQuery(this).closest('tr').find("td:eq(1)");
      if(jQuery(spantd).children('div').css('display') == 'none') {
        jQuery(spantd).children('div').show();
        jQuery(spantd).children('span').hide();
        jQuery(this).css('color', 'red');
        jQuery(this).removeClass('fa-plus-circle');
        jQuery(this).addClass('fa-minus-circle');
      }
      else {
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