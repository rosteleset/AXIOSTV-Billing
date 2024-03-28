jQuery(function () {
  var chat_index = jQuery('#chat_open').attr('fn_index');
  var aid_chat = jQuery('#id_for_chat').attr('aid');
  setInterval(update_chat, 5000);
  jQuery("#chat_open").click(function () {
    jQuery.post('/admin/index.cgi', 'header=2&qindex=' + chat_index + '&SH_MS_LIST=' + aid_chat, function (data_list) {
      jQuery('#chats_list').html(data_list);
    });
  });
});

function update_chat() {
  var chat_index = jQuery('#chat_open').attr('fn_index');
  var aid_chat = jQuery('#id_for_chat').attr('aid');
  jQuery.post('/admin/index.cgi', 'header=2&qindex=' + chat_index + '&AID=' + aid_chat, function (count_messages) {
    jQuery('span#chat2').text(count_messages);
    if (jQuery('span#chat2').text() == 0) {
      jQuery('span#chat2').addClass("hidden");
      jQuery('#chats_list').addClass("hidden");
    }
    else {
      jQuery('span#chat2').removeClass("hidden");
      jQuery('#chats_list').removeClass("hidden");
    }
  });
}