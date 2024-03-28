/**
 * Too many times I've seen or written stuff like this that drives me mad:
 *
 * this.ox = this.type == 'rect' ? this.attr('x') : this.attr('cx');
 * this.oy = this.type == 'rect' ? this.attr('y') : this.attr('cy');
 *
 * {...10,000 words of rant skipped here...}
 *
 * The last one simplifies it to:
 * this.o();    // and better, it supports chaining
 *
 * @copyright   Terry Young <terryyounghk [at] gmail.com>
 * @license     WTFPL Version 2 ( http://en.wikipedia.org/wiki/WTFPL )
 */
Raphael.el.is = function (type) { return this.type == (''+type).toLowerCase(); };
Raphael.el.x = function () { return this.is('circle') ? this.attr('cx') : this.attr('x'); };
Raphael.el.y = function () { return this.is('circle') ? this.attr('cy') : this.attr('y'); };
Raphael.el.o = function () { this.ox = this.x(); this.oy = this.y(); return this; };


/**
 * Another one of my core extensions.
 * Raphael has getBBox(), I guess the "B" stands for Basic,
 * because I'd say the "A" in getABox() here stands for Advanced.
 *
 * It's just to free myself from calculating the same stuff over and over and over again.
 * {...10,000 words of rant skipped here...}
 *
 * @author      Terry Young <terryyounghk [at] gmail.com>
 * @license     WTFPL Version 2 ( http://en.wikipedia.org/wiki/WTFPL )
 */
Raphael.el.getABox = function ()
{
  var b = this.getBBox(); // thanks, I'll take it from here...
  
  var o =
      {
        // we'd still return what the original getBBox() provides us with
        x:              b.x,
        y:              b.y,
        width:          b.width,
        height:         b.height,
    
        // now we can actually pre-calculate the following into properties that are more readible for humans
        // x coordinates have three points: left edge, centered, and right edge
        xLeft:          b.x,
        xCenter:        b.x + b.width / 2,
        xRight:         b.x + b.width,
    
    
        // y coordinates have three points: top edge, middle, and bottom edge
        yTop:           b.y,
        yMiddle:        b.y + b.height / 2,
        yBottom:        b.y + b.height
      };
  
  
  // now we can produce a 3x3 combination of the above to derive 9 x,y coordinates
  
  // center
  o.center      = {x: o.xCenter,    y: o.yMiddle };
  
  // edges
  o.topLeft     = {x: o.xLeft,      y: o.yTop };
  o.topRight    = {x: o.xRight,     y: o.yTop };
  o.bottomLeft  = {x: o.xLeft,      y: o.yBottom };
  o.bottomRight = {x: o.xRight,     y: o.yBottom };
  
  // corners
  o.top         = {x: o.xCenter,    y: o.yTop };
  o.bottom      = {x: o.xCenter,    y: o.yBottom };
  o.left        = {x: o.xLeft,      y: o.yMiddle };
  o.right       = {x: o.xRight,     y: o.yMiddle };
  
  // shortcuts to get the offset of paper's canvas
  o.offset      = $(this.paper.canvas).parent().offset();
  
  return o;
};


/**
 * Routine drag-and-drop. Just el.draggable()
 *
 * So instead of defining move, start, end and calling this.drag(move, start, end)
 * over and over and over again {10,000 words of rant skipped here}...
 *
 * @author      Terry Young <terryyounghk [at] gmail.com>
 * @license     WTFPL Version 2 ( http://en.wikipedia.org/wiki/WTFPL )
 */
Raphael.el.draggable = function (options)
{
  $.extend(true, this, {
    margin: 0               // I might expand this in the future
  },options || {});
  
  var start = function () {
        this.o().toFront(); // store original pos, and zIndex to top
        if (options.startCb) options.startCb();
        this.isDragging = true;
        this.moved = false;
      },
      move = function (dx, dy, mx, my, ev) {
        var b = this.getABox(); // Raphael's getBBox() on steroids
        var px = mx - b.offset.left,
            py = my - b.offset.top,
            x = this.ox + dx,
            y = this.oy + dy,
            r = this.is('circle') ? b.width / 2 : 0;
    
        // nice touch that helps you keep draggable elements within the canvas area
        var x = Math.min(
                Math.max(0 + this.margin + (this.is('circle') ? r : 0), x),
                this.paper.width - (this.is('circle') ? r : b.width) - this.margin),
            y = Math.min(
                Math.max(0 + this.margin + (this.is('circle') ? r : 0), y),
                this.paper.height - (this.is('circle') ? r : b.height) - this.margin);
    
        // work-smart, applies to circles and non-circles
        var pos = { x: x, y: y, cx: x, cy: y };
        this.attr(pos);
        if (options.moveCb) options.moveCb(x,y);
        this.moved = true;
      },
      end = function () {
        
        if (this.isDragging && !this.moved){
          $(this.node).click();
          if (options.startCb) options.startCb(true);
          if (options.endCb) options.endCb(true);
          return
        }
        
        if (options.endCb) options.endCb();
        this.isDragging = false;
        
      };
  
  this.drag(move, start, end);
  
  return this; // chaining
};


/**
 * Makes Raphael.el.draggable applicable to Raphael Sets, and chainable
 *
 * @author      Terry Young <terryyounghk [at] gmail.com>
 * @license     WTFPL Version 2 ( http://en.wikipedia.org/wiki/WTFPL )
 */
Raphael.st.draggable = function (options) {
  for (var i in this.items) this.items[i].draggable(options);
  return this; // chaining
};

Raphael.el.expandOnHover = function(options){
  options = options || {};
  
  $.extend(true, this, {
    margin: 0               // I might expand this in the future
  },options || {});
  
  this.normal_stroke_width = this.attr('stroke-width');
  
  this.changeWidth = function(){
    this.animate({'stroke-width': this.new_stroke_width});
  };
  
  this.expand = function(){
    this.new_stroke_width = this.normal_stroke_width * 2;
    this.changeWidth();
    this.toFront();
  };
  
  this.shrink = function(){
    this.new_stroke_width = this.normal_stroke_width;
    this.changeWidth();
    this.toFront();
    if (options && options.callback) options.callback();
  };
  
  this.mouseover(this.expand.bind(this));
  this.mouseout(this.shrink.bind(this));
  
  return this;
};

Raphael.st.expandOnHover = function (options) {
  this.normal_stroke_width = this.items[0].attr('stroke-width');
  
  this.changeWidth = function(){
    for (var i=0; i < this.items.length; i++){
      this.items[i].animate({'stroke-width': this.new_stroke_width});
    }
  };
  
  this.expand = function(){
    this.new_stroke_width = this.normal_stroke_width * 2;
    this.changeWidth();
  };
  
  this.shrink = function(){
    this.new_stroke_width = this.normal_stroke_width;
    this.changeWidth();
    this.circlesToFront();
    if (options && options.callback) options.callback();
  };
  
  this.mouseover(this.expand.bind(this));
  this.mouseout(this.shrink.bind(this));
  
  return this; // chaining
};

Raphael.st.circlesToFront = function(){
  for (var i in this.items){
    if (!this.items.hasOwnProperty(i)) continue;
    if (this.items[i].is('circle')) this.items[i].toFront();
  }
};

//
// This is a modified version of the jQuery context menu plugin. Credits below.
//

// jQuery Context Menu Plugin
//
// Version 1.01
//
// Cory S.N. LaViska
// A Beautiful Site (http://abeautifulsite.net/)
//
// More info: http://abeautifulsite.net/2008/09/jquery-context-menu-plugin/
//
// Terms of Use
//
// This plugin is dual-licensed under the GNU General Public License
//   and the MIT License and is copyright A Beautiful Site, LLC.
//
(function($)
{
  $.extend($.fn,
      {
        contextMenu: function(options)
        {
          // Defaults
          var defaults =
              {
                fadeIn:        150,
                fadeOut:       75
              },
              o = $.extend(true, defaults, options || {}),
              d = document;
          
          // Loop each context menu
          $(this).each( function()
          {
            var el = $(this),
                offset = el.offset(),
                $m = $('#' + o.menu);
            
            // Add contextMenu class
            $m.addClass('contextMenu');
            
            // Simulate a true right click
            $(this).mousedown( function(e) {
              
              // e.stopPropagation(); // Terry: No, thank you
              $(this).mouseup( function(e) {
                // e.stopPropagation(); // Terry: No, thank you
                var target = $(this);
                
                $(this).unbind('mouseup');
                
                if( e.button == 2 ) {
                  // Hide context menus that may be showing
                  $(".contextMenu").hide();
                  // Get this context menu
                  
                  if( el.hasClass('disabled') ) return false;
                  
                  // show context menu on mouse coordinates or keep it within visible window area
                  var x = Math.min(e.pageX, $(document).width() - $m.width() - 5),
                      y = Math.min(e.pageY, $(document).height() - $m.height() - 5);
                  
                  // Show the menu
                  $(document).unbind('click');
                  $m
                      .css({ top: y, left: x })
                      .fadeIn(o.fadeIn)
                      .find('A')
                      .mouseover( function() {
                        $m.find('LI.hover').removeClass('hover');
                        $(this).parent().addClass('hover');
                      })
                      .mouseout( function() {
                        $m.find('LI.hover').removeClass('hover');
                      });
                  
                  if (o.onShow) o.onShow( this, {x: x - offset.left, y: y - offset.top, docX: x, docY: y} );
                  
                  // Keyboard
                  $(document).keypress( function(e) {
                    var $hover = $m.find('li.hover'),
                        $first = $m.find('li:first'),
                        $last  = $m.find('li:last');
                    
                    switch( e.keyCode ) {
                      case 38: // up
                        if( $hover.size() == 0 ) {
                          $last.addClass('hover');
                        } else {
                          $hover.removeClass('hover').prevAll('LI:not(.disabled)').eq(0).addClass('hover');
                          if( $hover.size() == 0 ) $last.addClass('hover');
                        }
                        break;
                      case 40: // down
                        if( $hover.size() == 0 ) {
                          $first.addClass('hover');
                        } else {
                          $hover.removeClass('hover').nextAll('LI:not(.disabled)').eq(0).addClass('hover');
                          if( $hover.size() == 0 ) $first.addClass('hover');
                        }
                        break;
                      case 13: // enter
                        $m.find('LI.hover A').trigger('click');
                        break;
                      case 27: // esc
                        $(document).trigger('click');
                        break
                    }
                  });
                  
                  // When items are selected
                  $m.find('A').unbind('click');
                  $m.find('LI:not(.disabled) A').click( function() {
                    var checked = $(this).attr('checked');
                    
                    switch ($(this).attr('type')) // custom attribute
                    {
                      case 'radio':
                        $(this).parent().parent().find('.checked').removeClass('checked').end().find('a[checked="checked"]').removeAttr('checked');
                        // break; // continue...
                      case 'checkbox':
                        if ($(this).attr('checked') || checked)
                        {
                          $(this).removeAttr('checked');
                          $(this).parent().removeClass('checked');
                        }
                        else
                        {
                          $(this).attr('checked', 'checked');
                          $(this).parent().addClass('checked');
                        }
                        
                        //if ($(this).attr('hidemenu'))
                      {
                        $(".contextMenu").hide();
                      }
                        break;
                      default:
                        $(document).unbind('click').unbind('keypress');
                        $(".contextMenu").hide();
                        break;
                    }
                    // Callback
                    if( o.onSelect )
                    {
                      o.onSelect( $(this), $(target), $(this).attr('href'), {x: x - offset.left, y: y - offset.top, docX: x, docY: y} );
                    }
                    return false;
                  });
                  
                  // Hide bindings
                  setTimeout( function() { // Delay for Mozilla
                    $(document).click( function() {
                      $(document).unbind('click').unbind('keypress');
                      $m.fadeOut(o.fadeOut);
                      return false;
                    });
                  }, 0);
                }
              });
            });
            
            // Disable text selection
            if( $.browser ) { // latest version of jQuery no longer supports $.browser()
              if( $.browser.mozilla ) {
                $m.each( function() { $(this).css({ 'MozUserSelect' : 'none' }); });
              } else if( $.browser.msie ) {
                $m.each( function() { $(this).bind('selectstart.disableTextSelect', function() { return false; }); });
              } else {
                $m.each(function() { $(this).bind('mousedown.disableTextSelect', function() { return false; }); });
              }
            }
            // Disable browser context menu (requires both selectors to work in IE/Safari + FF/Chrome)
            el.add($('UL.contextMenu')).bind('contextmenu', function() { return false; });
            
          });
          return $(this);
        },
        // Destroy context menu(s)
        destroyContextMenu: function() {
          // Destroy specified context menus
          $(this).each( function() {
            // Disable action
            $(this).unbind('mousedown').unbind('mouseup');
          });
          return( $(this) );
        }
        
      });
})(jQuery);