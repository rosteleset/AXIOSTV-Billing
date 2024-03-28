/**
 * Created by Anykey on 13.10.2016.
 */
'use strict';
var results_list_id  = "#resultList";
var variants_list_id = '#variantsList';

var SORTABLE_OPTIONS = {
  revert: true,
  stop  : function () {
    $('#variantsTrash').removeClass('highlighted');
    Events.emit('cablecat.colorssorted')
  },
  start : function(){
    $('#variantsTrash').addClass('highlighted');
  }
  //placeholder: "ui-state-highlight"
};

var DRAGGABLE_OPTIONS = {
  connectToSortable: results_list_id,
  helper           : "clone",
  revert           : "invalid",
  start : function(){
    $('#resultList').addClass('highlighted');
  },
  stop : function(){
    $('#resultList').removeClass('highlighted');
  }
};

$(function () {
  var CABLECAT_COLORS = readColors('CABLECAT_COLORS');
  var RESULT_COLORS   = readColors('COLORS_id');
  
  AResult.init(RESULT_COLORS);
  AVariants.init(CABLECAT_COLORS);

  
  var $trash_icon = $('#variantsTrash');
  var $duplicate_all_btn = $('#duplicateWithMark');
  var $duplicate_through_one_btn = $('#duplicateWithMarkTroughOne');
  
  
  $trash_icon.on('click', function(){
    if (confirm('Clear colors?')){
      AResult.clear();
    }
  });
  
  $trash_icon.droppable({
    tolerance: "pointer",
    drop : function(event, ui){
      ui.draggable.remove();
    }
  });
  
  $duplicate_all_btn.on('click', AResult.duplicate);
  $duplicate_through_one_btn.on('click', AResult.duplicateThroughOne);
  
  $('form#form_CABLECAT_COLOR_SCHEME').on('submit', function (e) {
    var new_colors = AResult.getColors();
    $('#COLORS_id').val(new_colors);
  });
  
});


/**
 * Appends colors to container
 *
 * @param colors
 * @param $container
 * @param options
 * @returns {Array}
 */
function insertColors(colors, $container, options) {
  var $insertedDivs = [];
  if (typeof options === 'undefined') { options = {} }
  
  var skip_num = options['skip_num'];
  
  $container.disableSelection();
  $container.addClass('color-container');
  
  $.each(colors, function (index, color) {
    var next_color = getColorLiBlock({
      num  : (skip_num) ? '' : index + 1,
      color: color.color,
      mark : color.mark
    });
    
    $container.append(next_color);
    $insertedDivs[$insertedDivs.length] = next_color;
  });

  return $insertedDivs;
}

function getColorLiBlock(options) {
  var $colorDiv = $('<div></div>', {class: 'color-background text-left', style: 'background-color:' + options.color});
  
  if (options.num) {
    $colorDiv.append($('<span class="number">' + options.num + '</span>'));
  }
  
  if (options.mark) {
    $colorDiv.append($('<span class="mark">+</span>'));
  }

  $colorDiv.append($('<span class="color_name">' + COLORS_NAME[options.color] + '</span>'));
    
  var $li = $('<li></li>', {
    'data-hexcolor': options.color,
    'data-mark'    : options.mark,
    'class'        : 'colorBlock'
  });
  
  $li.append($colorDiv);
  
  return $li;
}

function readColors(inputID) {
  var colors_raw_string = $('#' + inputID).val();
  if (!colors_raw_string) return [];
  
  var colors_raw_array = colors_raw_string.split(',');
  return colors_raw_array.map(formatColor);
}

function formatColor(item) {
  var marked = item.indexOf('+');
  return {
    color: '#' + ((marked != -1) ? item.substr(0, marked) : item),
    mark : (marked != -1)
  };
}

function getColorObjectFromBlock(item) {
  var $item = $(item);
  return {
    color: $item.data('hexcolor'),
    mark : $item.data('mark')
  }
}

var AResult = (function () {
  var $container = null;
  var colors     = null;
  
  function init(currentColors) {
    $container = $('' + results_list_id);
    colors     = currentColors;
    $container.sortable(SORTABLE_OPTIONS);
    
    render();
    
    Events.on('cablecat.colorssorted', renew)
  }
  
  function render() {
    insertColors(colors, $container, {});
  }
  
  function clear() {
    $container.empty();
  }
  
  function duplicate(){
    // Extend array with marked copy
    colors.push.apply(colors, colors.map(function(item){
      return {
        color: item.color,
        mark : true
      }
    }));
    
    // Clear DOM
    clear();
    
    // Apply and draw new colors
    render();
  }
  
  function duplicateThroughOne(){
    var new_colors = [];
    
    colors.forEach(function(item){
      new_colors[new_colors.length] = {
        color : item.color,
        mark : false
      };
      new_colors[new_colors.length] = {
        color : item.color,
        mark : true
      }
    });
    
    colors = new_colors;
    
    clear();
    render();
  }
  
  function getColors(){
    var result = [];
    colors.map(function(item){
      var color_without_hash = item.color.substr(1, item.color.length);
      result[result.length] = (item.mark) ? color_without_hash + '+' : color_without_hash
    });
    
    return result.join(',');
  }
  
  function renew() {
    var $lis       = $container.find('li');
    var new_colors = [];
    $.each($lis, function (i, item) {
      new_colors[new_colors.length] = getColorObjectFromBlock(item);
    });
    
    colors = new_colors;
    
    clear();
    render();
  }
  
  function append($item){
    $container.append($item);
    renew();
  }
  
  return {
    init : init,
    clear: clear,
    renew: renew,
    getColors : getColors,
    duplicate : duplicate,
    duplicateThroughOne : duplicateThroughOne,
    append : append
  }
})();

var AVariants = (function () {
  
  var variants   = [];
  var $container = null;
  
  function init(colors) {
    $container = $('' + variants_list_id);
    variants   = colors;
    
    render();
  }
  
  function render() {
    var $divs = insertColors(variants, $container, {skip_num: 1});
    $divs.map(function ($item) {
      $item.draggable(DRAGGABLE_OPTIONS);
      
      $item.on('dblclick', function(){AResult.append($(this).clone())});
    })
  }
  
  return {
    init: init
  }
})();
