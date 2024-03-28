$(function () {
  
  Events.on('AJAX_SUBMIT.SYSINFO_SERVER_SERVICES', function(){
  
    $('#p_SYSINFO_SERVICES').load('?index=' + INDEX + ' #p_SYSINFO_SERVICES', function(){
      aModal.hide();
    })
  });
  
  Events.on('AJAX_SUBMIT.SYSINFO_SERVICE_SERVERS', function(){
  
    $('#p_SYSINFO_SERVERS').load('?index=' + INDEX + ' #p_SYSINFO_SERVERS', function(){
      aModal.hide();
    })
  });
  
  
});