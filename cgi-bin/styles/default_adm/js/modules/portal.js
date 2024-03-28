/**
 * Created by Anykey on 17.03.2017.
 */

var textarea_id = 'news-text';

function fillPreview(e) {
  cancelEvent(e);
  
  var previewFrame = document.getElementById('preview');
  var preview      = previewFrame.contentDocument || previewFrame.contentWindow.document;
  
  preview.open();
  
  preview.write(
      '<!DOCTYPE html><html><head>' +
      '<link href="/styles/default_adm/css/bootstrap.min.css" rel="stylesheet">' +
      '<link href="/styles/default_adm/css/style.css" rel="stylesheet">' +
      '</head><body>' +
      '<div class=\'container\' id=\'preview_container\'>' +
      '</div></body></html>'
  );
  
  var script = document.createElement('script');
  script.src = '/styles/default_adm/js/jquery.min.js';
  preview.getElementsByTagName('head')[0].appendChild(script);
  
  var script2 = document.createElement('script');
  script2.src = '/styles/default_adm/js/bootstrap.min.js';
  preview.getElementsByTagName('head')[0].appendChild(script2);
  
  preview.addEventListener('DOMContentLoaded', function (event) {
    
    var html = jQuery('textarea#' + textarea_id).val();
  
    var replaced_html = html;
    
    replaced_html = replaced_html.replace(/\[([a-z]+)\](.*)\[\/\1\]/g, '<$1>$2</$1>');
    replaced_html = replaced_html.replace(/\n|\r\n/gm, '<br/>');
    
    preview.getElementById('preview_container').innerHTML = replaced_html;
  });
  
  preview.close();
}

function wrap_text(tag, text) {
  return '[' + tag + ']' + text + '[/' + tag + ']';
}

function replace_between(string, offset, length, new_text) {
  return string.substr(0, offset) + new_text + string.substr(length);
}

jQuery(function () {
  
  var textarea = jQuery('textarea#' + textarea_id);
  
  function get_selected() {
    var textarea_dom = document.getElementById(textarea_id);
    
    var start  = textarea_dom.selectionStart;
    var finish = textarea_dom.selectionEnd;
    
    return [textarea.val().substring(start, finish), start, finish];
  }
  
  function create_tag_wrap_handler(tag_name) {
    return function (e) {
      cancelEvent(e);
      var selection     = get_selected();
      var selected_text = selection[0];
      
      if (selected_text) {
        var wrapped_text = wrap_text(tag_name, selected_text);
        var full_text    = textarea.val();
        
        var replaced = replace_between(full_text, selection[1], selection[2], wrapped_text);
        textarea.val(replaced);
      }
      else {
        textarea.val(textarea.val() + wrap_text(tag_name, ''));
      }
      
      textarea.trigger('input');
    }
  }
  
  
  // Initialize all controls
  jQuery('div#editor-controls').find('button').each(function (i, btn) {
    var j_btn = jQuery(btn);
    var tag   = j_btn.data('tag');
    
    if (!tag) return;
    
    j_btn.on('click', create_tag_wrap_handler(tag));
  });
  
  fillPreview();
  textarea.on('input', fillPreview);
});
