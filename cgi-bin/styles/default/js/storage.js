function selectArticles(self, empty_sel = false, required = false) {
  let empty_search = empty_sel ? "&EMPTY_SEL=1" : "";
  let required_type = required ? '&REQUIRED=1' : '';

  jQuery.post('/admin/index.cgi', 'header=2&get_index=storage_main&SHOW_SELECT=1&ARTICLE_TYPE_ID=' +
    jQuery(self).val() + empty_search + required_type, function (result) {
    jQuery("div.ARTICLES_S").empty();
    jQuery("div.ARTICLES_S").html(result);
    initChosen();
  });
}

$(function () {

  var initAddBuildMenu = function () {

    jQuery('a.BUTTON-ENABLE-ADD').click(function (e) {
      e.preventDefault();
      jQuery('.addInvoiceMenu').hide();
      jQuery('.changeInvoiceMenu').show();
    });
    jQuery('a.BUTTON-ENABLE-SEL').click(function (e) {
      e.preventDefault();
      jQuery('.addInvoiceMenu').show();
      jQuery('.changeInvoiceMenu').hide();
    });
  };

  initAddBuildMenu();

});