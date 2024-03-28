
 
	var latlng      = new google.maps.LatLng(%MAP_Y%, %MAP_X% );
	var online      = '%USERS_ONLINE%';
	var offline     = '%USER_OFFLINE%';
	var sub_online  = '%SUB_ONLINE%';
	var Mcolor;
	var thOnline;
	var showOnline  = '';
	var showOffline = '';
	var thAll       = '';
	
	if (online == '' ) {
		Mcolor = 'build_off';
		if(sub_online == 1) {
		  Mcolor = 'build_on';
		}  
		thOnline ='';
	}
	else {
		Mcolor = 'build_on';
		thOnline = '<tr><th class=\"table_title\">_{USER}_:</th><th class=\"table_title\">IP:</th></tr>';
		showOnline = '<strong><font color=green>_{USERS}_ online(%USER_COUNT_ONLINE%)</font></strong><br /><table border=1 cellspacing=0 cellpadding=0 width=400>'+ thOnline +' %USERS_ONLINE% </table>';
	}	
	
	if (offline == '' ) {
		thAll = '';
	} 
	else {
	  showOffline = '<strong><font color=red>_{USERS}_(%USER_COUNT_OFFLINE%):</font></strong><br />';
	  showOffline = showOffline + '<table border=1 cellspacing=0 cellpadding=0 width=300>'+ thAll +'  %USER_OFFLINE% </table>';
		thAll = '<tr><th class=\"table_title\">_{USER}_:</th><th class=\"table_title\">_{DEPOSIT}_:</th><th class=\"table_title\">_{FLAT}_:</th></tr>';
	}
	
	createMarker(latlng, '<strong>_{STREET}_: </strong>%STREET_ID%<br /><strong>_{BUILD}_: </strong>%NUMBER%<br /><div id=\"infoWindowSize\">' + showOnline + ' ' + showOffline + '</div>  ', Mcolor , '%STREET_ID% %NUMBER%', %BUILD_ID%);
	    