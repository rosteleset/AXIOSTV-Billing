(function () {
  'use strict';
  function findPos(obj) {
    var posX = obj.offsetLeft, posY = obj.offsetTop, posArray;
    while (obj.offsetParent) {
      if (obj === document.getElementsByTagName('body')[0]) {break;} else {
        posX = posX + obj.offsetParent.offsetLeft;
        posY = posY + obj.offsetParent.offsetTop;
        obj  = obj.offsetParent;
      }
    }
    posArray = [posX, posY];
    return posArray;
  }
  
  function getRelativePosition(e, obj) {
    var x, y, pos;
    if (e.deltaX || e.deltaY) {
      x = e.deltaX;
      y = e.deltaY;
    } else if (e.pageX || e.pageY) {
      x = e.pageX;
      y = e.pageY;
    } else {
      x = e.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
      y = e.clientY + document.body.scrollTop + document.documentElement.scrollTop;
    }
    pos = findPos(obj);
    x -= pos[0];
    y -= pos[1];
    return {x: x, y: y};
  }
  
  var panZoomFunctions = {
    enable            : function () {this.enabled = true;},
    disable           : function () {this.enabled = false;},
    zoomIn            : function (steps) {this.applyZoom(steps);},
    zoomOut           : function (steps) {this.applyZoom(steps > 0 ? steps * -1 : steps);},
    pan               : function (deltaX, deltaY) {this.applyPan(deltaX * -1, deltaY * -1);},
    isDragging        : function () {return this.dragTime > this.dragThreshold;},
    getCurrentPosition: function () {return this.currPos;},
    getCurrentZoom    : function () {return this.currZoom;}
  }, PanZoom           = function (el, options) {
    var paper                = el, container = paper.canvas.parentNode, me = this, settings = {}, initialPos = {
      x: 0,
      y: 0
    }, deltaX                = 0, deltaY = 0, mousewheelevt = (/Firefox/i.test(navigator.userAgent)) ? "DOMMouseScroll" : "mousewheel";
    this.enabled             = false;
    this.dragThreshold       = 5;
    this.dragTime            = 0;
    options                  = options || {};
    settings.maxZoom         = options.maxZoom || 9;
    settings.minZoom         = options.minZoom || 0;
    settings.zoomStep        = options.zoomStep || 0.1;
    settings.zoomCenter      = options.zoomCenter || null;
    settings.initialZoom     = options.initialZoom || 0;
    settings.initialPosition = options.initialPosition || {x: 0, y: 0};
    settings.enablePan       = options.enablePan || true;
    settings.enableZoom      = options.enableZoom || true;
    settings.redrawCallback  = options.redrawCallback || null;
    settings.skipScroll  = options.skipScroll || false;
    this.currZoom            = settings.initialZoom;
    this.currPos             = settings.initialPosition;
    function repaint() {
      me.currPos.x = me.currPos.x + deltaX;
      me.currPos.y = me.currPos.y + deltaY;
      var newWidth = paper.width * (1 - (me.currZoom * settings.zoomStep)), newHeight = paper.height * (1 - (me.currZoom * settings.zoomStep));
      if (me.currPos.x < 0) {me.currPos.x = 0;} else if (me.currPos.x > (paper.width * me.currZoom * settings.zoomStep)) {me.currPos.x = (paper.width * me.currZoom * settings.zoomStep);}
      if (me.currPos.y < 0) {me.currPos.y = 0;} else if (me.currPos.y > (paper.height * me.currZoom * settings.zoomStep)) {me.currPos.y = (paper.height * me.currZoom * settings.zoomStep);}
      paper.setViewBox(me.currPos.x, me.currPos.y, newWidth, newHeight);
      if (settings.redrawCallback !== null) {if (typeof settings.redrawCallback == "string") {eval(settings.redrawCallback);} else {settings.redrawCallback();}}
    }
    
    function dragging(e) {
      if (!me.enabled) {return false;}
      if (!settings.enablePan) {return false;}
      var newWidth = paper.width * (1 - (me.currZoom * settings.zoomStep)), newHeight = paper.height * (1 - (me.currZoom * settings.zoomStep));
      var evt      = window.event || e;
      var newPoint = getRelativePosition(e, container);
      deltaX       = (newWidth * (newPoint.x - initialPos.x) / paper.width) * -1;
      deltaY       = (newHeight * (newPoint.y - initialPos.y) / paper.height) * -1;
      initialPos   = newPoint;
      repaint();
      me.dragTime += 1;
      if (window.event.preventDefault) {window.event.preventDefault();} else {window.event.returnValue = false;}
      return false;
    }
    
    function applyZoom(val, centerPoint) {
      if (!me.enabled) {return false;}
      me.currZoom += val;
      if (me.currZoom < settings.minZoom) {me.currZoom = settings.minZoom;} else if (me.currZoom > settings.maxZoom) {me.currZoom = settings.maxZoom;} else {
        if (!centerPoint) {
          if (settings.zoomCenter === null) {
            centerPoint = {
              x: paper.width / 2,
              y: paper.height / 2
            };
          } else {centerPoint = settings.zoomCenter;}
        }
        deltaX = ((paper.width * settings.zoomStep) * (centerPoint.x / paper.width)) * val;
        deltaY = (paper.height * settings.zoomStep) * (centerPoint.y / paper.height) * val;
        repaint();
      }
    }
    
    this.applyZoom = applyZoom;
    function applyPan(dX, dY) {
      deltaX = dX;
      deltaY = dY;
      repaint();
    }
    
    this.applyPan = applyPan;
    function handleScroll(e) {
      if (settings.skipScroll || !me.enabled) {return false;}
      if (!settings.enableZoom) {return false;}
      var evt = window.event || e, delta = evt.detail || evt.wheelDelta * -1, zoomCenter = getRelativePosition(evt, container);
      if (delta > 0) {delta = -1;} else if (delta < 0) {delta = 1;}
      if (settings.zoomCenter !== null) {applyZoom(delta, settings.zoomCenter);} else {applyZoom(delta, zoomCenter);}
      if (evt.preventDefault) {evt.preventDefault();} else {evt.returnValue = false;}
      return false;
    }
    
    if (container.attachEvent) {container.attachEvent("on" + mousewheelevt, handleScroll);} else if (container.addEventListener) {container.addEventListener(mousewheelevt, handleScroll, false);}
   
    if (typeof window['Hammer'] !== 'undefined') {
      var touchManager = new Hammer.Manager(container, {touchAction: "none"});
      var touchPan     = new Hammer.Pan();
      var touchPinch   = new Hammer.Pinch();
      touchPinch.recognizeWith([touchPan]);
      touchManager.add(touchPan);
      touchManager.add(touchPinch);
      touchManager.on("panstart", function (e) {initialPos = getRelativePosition(e, container);});
      touchManager.on("panmove", function (e) {dragging(e);});
      touchManager.on("panend", function (e) {initialPos = getRelativePosition(e, container);});
      touchManager.on("pinchstart", function (e) {
        e.preventDefault();
        container.pinchLastScale = 1;
      });
      touchManager.on("pinchmove", function (e) {
        e.preventDefault();
        applyZoom(Math.log(e.scale / container.pinchLastScale) * 5, e.center);
        container.pinchLastScale = e.scale;
      });
      touchManager.on("pinchend", function (e) {e.preventDefault();});
      repaint();
    }
    
  };
  PanZoom.prototype    = panZoomFunctions;
  Raphael.fn.panzoom   = {};
  Raphael.fn.panzoom   = function (options) {
    var paper = this;
    return new PanZoom(paper, options);
  };
}());