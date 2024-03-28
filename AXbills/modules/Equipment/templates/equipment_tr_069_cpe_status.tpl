    <div class='col-md-2' style='padding: 0; text-align: left;'> 
      <ul class="nav nav-stacked">
                <li class='active' id='device'><a href="#">Device information</a></li>
                <li id='wan'><a href="#">WAN information</span></a></li>
                <li id='wlan'><a href="#">WLAN information</a></li>
                <li id='voip'><a href="#">VoIP information</a></li>
                <li id='security'><a href="#">Security information</a></li>
                <li id='hosts'><a href="#">Hosts information</a></li>
                <li id='neighbor_ap'><a href="#">Neighbor AP information</a></li>
      </ul>
    </div>
    <div class="col-md-10" style='padding: 10px; text-align: left;' id=status_content>%HTML_CONTENT%</div>
    <script>
        jQuery(document).ready(function(){
            jQuery('ul.nav-stacked li').click(function(e){
                var clickedID = jQuery(this).attr( "id" );
                var em = jQuery(this);
                  jQuery.ajax({
                    type: 'POST',
                    url: 'index.cgi',
                    data: 'get_index=equipment_info&TR_069=1&onu_info=1&tr_069_id=%tr_069_id%&&header=2&menu=status&sub_menu='+clickedID,
                    success: function(html){
                        jQuery('#status_content').html(html);
                        jQuery('ul.nav-stacked li').removeClass('active');
                        em.addClass('active');
                    }
                });
                return false;
            });

        });
    </script>
