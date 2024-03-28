/**
 * Created by Anykey on 23.10.2015.
 * Parses, renders and shows Metro UI tiles with information
 *
 * Each panel arguments
 *   NAME             - Title
 *   SIZE             - 1 or 2, default 1 ( tile sizes )
 *   PROPORTION       - left and right part proportions
 *   COLOR            - hex color (default: random Material)
 *   HEADER           - header HTML
 *   CONTENT          - hash_ref of displayed table
 *   |SLIDES          - array_ref of CONTENT
 *   FOOTER           - footer HTML (optional)
 *
 *
 */

var AInfoPanels = (function () {
  
  var INFO_PANEL_CONTENT_LEFT_CLASSES  = "text-1 no-border";
  var INFO_PANEL_CONTENT_RIGHT_CLASSES = "text-2 no-border";
  
  //Intensity of Background color
  var BACKGROUND_OPACITY = 0.7;
  
  
  function getSize(size) {
    if (size === 2) {
      return ' col-xs-12 col-sm-8 col-md-8 col-lg-6';
    }
    return ' col-xs-6 col-sm-4 col-md-4 col-lg-4';
  }
  
  function getMaxRowSize() {
    var width = $('#main-content').width();
    
    if (width < 768) {        //xs
      return 1;
    }
    else if (width <= 992) {  //sm
      return 3;
    }
    else if (width <= 1200) { //md
      return 3;
    }
    else {                    //lg
      return 3;
    }
  }
  
  //Colors
  var colors = new AColorPalette();
  
  // Raw json
  var InfoPanelsArray = [];
  
  // Json with params we care + default params
  var parsedTiles = [];
  
  // Objects that present tile content and meta information we need for calculating size and position
  var renderedTiles = [];
  
  // html rows
  var rows = [];
  
  var clearPanel = {
    "NAME"   : null,
    "HEADER" : null,
    "COLOR"  : null,
    "SIZE"   : null,
    "CONTENT": {},
    "FOOTER" : null
  };
  
  //bindEvents
  Events.on('infoPanels_renewed', renew);
  
  function parse() {
    $.each(InfoPanelsArray, function (index, panel) {
      console.log(panel);
      var newPanel = Object.create(clearPanel);
      
      // Meta information
      newPanel.id    = 'InfoPanel_' + panel.NAME;
      newPanel.size  = Number(panel.SIZE) || 1;  //small by default
      newPanel.color = panel.COLOR || colors.getNextColorRGBA(BACKGROUND_OPACITY);
      
      // Content
      newPanel.HEADER = panel.HEADER || '';
      if (panel.CONTENT) {
        newPanel.BODY = parseContent(panel.CONTENT, panel.PROPORTION);
      }
      else if (panel.SLIDES) {
        newPanel.BODY = parseSlides(panel.SLIDES, panel.PROPORTION, newPanel.id + '_SLIDER');
      }
      newPanel.FOOTER = panel.FOOTER || '';
      
      // Save result
      parsedTiles.push(newPanel);
    });
    
    function parseContent(contentObject, proportion) {
      var prop = 2;
      if (isFinite(proportion)) prop = proportion;
      var leftSize  = (6 / Math.abs(prop)) * 2;
      var rightSize = (12 - leftSize);
      
      if (prop < 0) { //swap sizes
        // http://stackoverflow.com/questions/16151682/swap-two-objects-in-javascript
        function swap(x) {
          return x;
        }
        
        rightSize = swap(leftSize, leftSize = rightSize);
      }
      
      var contentRows = '';
      for (var key in contentObject) {
        if (!contentObject.hasOwnProperty(key)) continue;
        contentRows += '<div class="col-md-12 form-group row">'
            + '<div class="' + INFO_PANEL_CONTENT_LEFT_CLASSES + ' col-md-' + leftSize + '">' + key + ':</div>'
            + '<div class="' + INFO_PANEL_CONTENT_RIGHT_CLASSES + ' col-md-' + rightSize + '">' + contentObject[key] + '</div>'
            + '</div>';
      }
      return contentRows;
    }
    
    function parseSlides(slidesArray, proportion, id) {
      var slideWrapper = '';
      //var slideIndicators = getSlideIndicators(id, slidesArray.length);
      if (slidesArray.length > 0) {
        var SLIDE_CONTROLS = '<a class="left carousel-control" href="#' + id + '" role="button" data-slide="prev">'
            + '<span class="fa fa-chevron-left" aria-hidden="true"></span>'
            + '<span class="sr-only">Previous</span>'
            + '</a>'
            + '<a class="right carousel-control" href="#' + id + '" role="button" data-slide="next">'
            + '<span class="fa fa-chevron-right" aria-hidden="true"></span>'
            + '<span class="sr-only">Next</span>'
            + '</a>';
        
        slideWrapper = '<div id="' + id + '" class="carousel slide" data-ride="carousel">';
        //slideWrapper = slideIndicators;
        slideWrapper += '<div class="carousel-inner">';
        $.each(slidesArray, function (i, slide) {
          
          var item = '<div class="item">';
          if (i == 0) item = '<div class="item active">';
          
          item += parseContent(slide, proportion);
          item += '</div>';
          
          slideWrapper += item;
        });
        slideWrapper += '</div>'
            + SLIDE_CONTROLS
            + '</div>';
      }
      return slideWrapper;
      
      
    }
    
    function getSlideIndicators(id, slideArrayLength) {
      var wrapper = '<ol class="carousel-indicators">';
      var count   = 0;
      
      wrapper += '<li data-target="#' + id + '" data-slide-to="' + count + '" class="active"></li>';
      count++;
      while (count < slideArrayLength) {
        wrapper += '<li data-target="#' + id + '" data-slide-to="' + count + '"></li>';
        count++;
      }
      wrapper += '</ol>';
      
      return wrapper;
    }
  }
  
  //Creates HTML from parsed panels Array
  function render() {
    //clear
    renderedTiles = [];
    
    $.each(parsedTiles, function (index, rawTile) {
      var tile = renderTile(rawTile, index);
      
      renderedTiles.push(tile);
      
      function renderTile(panel, index) {
        var panelElement = '<div class="' + getSize(panel.size) + ' tileSize' + panel.size + '">';
        
        panelElement += '<div id="tile' + index + '" class="tile">';
        if (panel.HEADER)
          panelElement += '<div class="text-center InfoPanelHeader">' + panel.HEADER + '</div>';
        
        //append content
        panelElement += '<div class="row InfoPanelContent">' + panel.BODY + '</div>';
        if (panel.FOOTER)
          panelElement += '<div class="row InfoPanelFooterWrapper"><div class="text-center InfoPanelFooter">' + panel.FOOTER + '</div></div>';
        
        //end of content
        panelElement += '</div>';
        panelElement += '</div>';
        
        //apply styles
        var $panel = $(panelElement);
        $panel.css({
          "background-color": panel.color
        });
        
        return {
          "CONTENT": $panel,
          "META"   : {
            "NUMBER": index,
            "SIZE"  : panel.size
          }
        };
      }
    });
    
    makeRows();
    
    show();
    
    function makeRows() {
      //clear
      rows                    = [];
      //prepare
      var copyOfRenderedTiles = {};
      var largerTiles         = [];
      
      //saving from array to object with numeric values
      for (var i = 0; i < renderedTiles.length; i++) {
        copyOfRenderedTiles[i] = renderedTiles[i];
      }
      
      var maxSize = getMaxRowSize();
      
      var $row = createNewRow();
      
      var rowSize = 0;
      for (var j = 0; j < renderedTiles.length; j++) {
        //check largerTilesArray
        if (largerTiles.length > 0) {
          tryPush(largerTiles.pop(), $row);
        }
        var tile = copyOfRenderedTiles[j];
        tryPush(tile, $row);
        //check size
        if (rowSize >= maxSize) {//if size is over create new row
          $row = createNewRow($row);
        }
      }
      
      if (largerTiles.length > 0) {
        $.each(largerTiles, function (i, tile) {
          $row.append(tile.CONTENT);
        });
      }
      rows.push($row);
      
      function tryPush(tile, $row) {
        if (tile.META.SIZE <= maxSize - rowSize) {
          $row.append(tile.CONTENT);
          rowSize += tile.META.SIZE;
        }
        else {
          largerTiles.push(tile);
        }
      }
      
      function createNewRow(row) {
        if (row) {
          rows.push(row);
        }
        rowSize  = 0;
        return $('<div></div>', { 'class' : 'row' });
      }
    }
  
    AInfoPanels.makeSquareTiles();
  
  }
  
  function show() {
    var $panelsDiv = $('#infoPanelsDiv');
    $panelsDiv.empty();
    
    //push rows to $panelsDiv
    $.each(rows, function (index, row) {
      $panelsDiv.append(row);
    });
    
    makeSquareTiles();
  }
  
  function renew() {
    parse();
    render();
  }
  
  // make tiles square form
  function makeSquareTiles() {
    var $tile1     = $('.tileSize1');
    var $tile      = $(".tile");
    var tile1Width = $tile1.width();
    $tile.parent().height(tile1Width);
  }
  
  return {
    renew          : renew,
    render         : render,
    makeSquareTiles: makeSquareTiles,
    InfoPanelsArray: InfoPanelsArray
  }
})();

$(document).ready(function () {
  
  $(window).resize(function () {
    
    if (this.resizeTO) clearTimeout(this.resizeTO);
    this.resizeTO = setTimeout(function () {
      $(this).trigger('resizeEnd');
    }, 10);
    
  });
  
  $(window).bind('resizeEnd', AInfoPanels.render);
});