jQuery(function () {
  var chat_index = jQuery('#chat_open').attr('fn_index');
  var uid_chat = jQuery('#id_for_chat').attr('uid');
  setInterval(update_chat, 5000);
  jQuery("#chat_open").click(function () {
    jQuery.post('/index.cgi', 'header=2&qindex=' + chat_index + '&US_MS_LIST=' + uid_chat, function (data_list) {
      jQuery('#chats_list').html(data_list);
    });
  });
});

function update_chat() {
  var chat_index = jQuery('#chat_open').attr('fn_index');
  var uid_chat = jQuery('#id_for_chat').attr('uid');
  jQuery.post('/index.cgi', 'header=2&INFO=1&qindex=' + chat_index + '&UID=' + uid_chat, function (count_messages) {
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