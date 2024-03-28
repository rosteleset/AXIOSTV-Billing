/**
 * Created by Anykey on 01.02.2017.
 */
'use strict';

function addLinkInfo(element_type, element_id, fiber_num, direction) {
  
  var $div = $('<div></div>', {
    id : 'cablecat_choose_connection'
  })[0].outerHTML;
  
  new AModal()
      .setId('linkInfoTypeChooseModal')
      .setBody($div)
      .addButton(LANG['CHOOSE'], 'cablecat_choose_connection', 'primary')
      .show(function (modal) {
        
        var modalChooser = new ModalSelectChooser('#cablecat_choose_connection', {
          event   : 'Cablecat.connection_type_chosen',
          url     : '?get_index=cablecat_link_info&request=1&AJAX=1&json=1&header=2'
          + '&ELEMENT_TYPE=' + element_type
          + '&ELEMENT_ID=' + element_id,
          select  : {
            label  : LANG['TYPE'],
            id     : 'TYPE',
            name   : 'TYPE',
            next   : {load: 1},
            options: JSON.parse(document['LINK_TYPE_OPTIONS'])
          },
          onFinish: function (values) {
            modal.hide();
            sendLinkInfo(element_type, element_id, fiber_num, direction, values);
          }
        });
        
        $('button#cablecat_choose_connection').on('click', modalChooser.finish);
      });
}

function clearLinkInfo(element_type, element_id, fiber_num, direction){
  var params = {
    get_index: 'cablecat_link_info',
    AJAX     : 1,
    json     : 1,
    del      : 1,
    header   : 2,
    ELEMENT_TYPE : element_type,
    ELEMENT_ID : element_id,
    FIBER_NUM: fiber_num,
    DIRECTION: direction
  };
  
  $.post('?', params, function (data) {
    displayJSONTooltip(data);
    renewLinkTableCell(element_type, element_id, fiber_num, direction);
    location.reload(true);
  });
}

function sendLinkInfo(element_type, element_id, fiber_num, direction, type_values) {
  
  var params = {
    get_index: 'cablecat_link_info',
    AJAX     : 1,
    json     : 1,
    add      : 1,
    header   : 2,
    ELEMENT_TYPE : element_type,
    ELEMENT_ID : element_id,
    FIBER_NUM: fiber_num,
    DIRECTION: direction
  };
  
  $.extend(params, type_values);
  
  $.post('?', params, function(data){
    displayJSONTooltip(data);
    renewLinkTableCell(element_type, element_id, fiber_num, direction);
    location.reload(true);
  });
  
}

function renewLinkTableCell(element_type, element_id, fiber_num, direction){
  
  var params = {
    get_index: 'cablecat_link_info',
    AJAX     : 1,
    renew    : 1,
    header   : 2,
    ELEMENT_TYPE : element_type,
    ELEMENT_ID : element_id,
    FIBER_NUM: fiber_num,
    DIRECTION: direction
  };
  
  $.get('?', params, function(data){
    var $cell = findLinkTableCell(element_type, element_id, fiber_num, direction);
    
    // Update content
    $cell.html(data);
  });
}

function findLinkTableCell(element_type, element_id, fiber_num, direction){
  var $table = $('#CABLECAT_CABLE_LINKS_ID_');
  
  var position = (direction !== 0) ? 1 : 2;
  
  // Find row for this fiber
  var $row = $table.find('tbody tr:nth-child('+ fiber_num +')');
  
  // Find td for this direction
  return $($row.find('td')[position]);
}