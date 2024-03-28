    <div class='col-md-2' style='padding: 0; text-align: left;'> 
      <ul class="nav nav-stacked">
        %SUB_MENU_CONTENT%
      </ul>
    </div>
    <div class="col-md-10" style='padding: 10px; text-align: left;' id=content>
      %HTML_CONTENT%
    </div>
    <script>
        jQuery(document).ready(function(){
            jQuery('ul.nav-stacked li').click(function(e){
                var clickedID = jQuery(this).attr( "id" );
                var em = jQuery(this);
                  jQuery.ajax({
                    type: 'POST',
                    url: 'index.cgi',
                    data: 'get_index=equipment_info&TR_069=1&info_pon_onu=%info_pon_onu%&onu_info=1&tr_069_id=%tr_069_id%&header=2&menu=%MENU%&sub_menu='+clickedID,
                    success: function(html){
                        jQuery('#content').html(html);
                        jQuery('ul.nav-stacked li').removeClass('active');
                        em.addClass('active');
                    }
                });
                return false;
            });

        });
    </script>
