<!--suppress JSSuspiciousNameCombination -->
<div class='row'>
  <div class='col-md-12'>
    <div id='canvas_container' class='table-responsive'>
      <div id='drawCanvas' style="border: 1px solid silver"></div>
    </div>
  </div>
</div>


<script src='/styles/default/js/raphael.min.js'></script>

<script>

  var POSITION_TOP = 0;
  var POSITION_RIG = 1;
  var POSITION_BOT = 2;
  var POSITION_LEF = 3;

  var SCHEME_OPTIONS = {
    CANVAS_WIDTH    : 600,
    CANVAS_HEIGHT   : 600,
//    CONTAINER_WIDTH : 300,
//    CONTAINER_HEIGHT: 400,

    CABLE_HEIGHT: 25,

    MODULE_HEIGHT: 5,

    FIBER_WIDTH : 10,
    FIBER_HEIGHT: 25,
    FIBER_MARGIN: 5
  };

  paper = new Raphael('drawCanvas', SCHEME_OPTIONS['CANVAS_WIDTH'], SCHEME_OPTIONS['CANVAS_HEIGHT']);

  jQuery('#drawCanvas').css({
    width : SCHEME_OPTIONS['CANVAS_WIDTH'],
    height: SCHEME_OPTIONS['CANVAS_HEIGHT']
  });

  var RectAbstract = function (attributes) {
    this.startX = 250;
    this.startY = 250;

    this.rendered = null;

    this.modules = attributes.modules;
    this.fibers  = attributes.fibers;

    this.position = attributes.position || POSITION_BOT;

    this.calculateSizes();

    // Canonical sizes
    this.base_height = this.height;
    this.base_width  = this.width;
  };

  RectAbstract.prototype.calculateSizes = function () {
    this.width  = (SCHEME_OPTIONS.FIBER_WIDTH + SCHEME_OPTIONS.FIBER_MARGIN) * this.fibers;
    this.full_height = SCHEME_OPTIONS.CABLE_HEIGHT + SCHEME_OPTIONS.MODULE_HEIGHT + SCHEME_OPTIONS.FIBER_HEIGHT;

    this.height = SCHEME_OPTIONS.CABLE_HEIGHT;
  };

  RectAbstract.prototype.calculateDrawDirections = function(){
    // Clear
    this.positionRelatedStartX = 0;
    this.positionRelatedStartY = 0;
    this.modulesPositionRelatedStartX = 0;
    this.modulesPositionRelatedStartY = 0;

    switch (this.position) {
      case POSITION_RIG:
        this.positionRelatedStartX = 0; //this.base_width;
        this.modulesPositionRelatedStartX = 0 - this.modules_height;
        break;
      case POSITION_BOT:
        this.positionRelatedStartY = 0 - this.base_height;
        this.modulesPositionRelatedStartY = 0 - this.modules_height;
        break;
    }
  };

  RectAbstract.prototype.remove = function () {
    if (this.rendered === null)  return true;

    this.rendered.remove();
  };

  RectAbstract.prototype.render = function () {
    this.remove();

    this.calculateModulesPosition();
    this.calculateDrawDirections();

    paper.setStart();

    // Render cable rect
    paper.rect(
        this.startX + this.positionRelatedStartX,
        this.startY + this.positionRelatedStartY,
        Math.abs(this.width),
        Math.abs(this.height)
    );

    // Render modules
    for (var m = 0; m < this.modules; m++){
      paper.rect(
          this.modules_startX + (this.modules_offsetX * m * this.modules_width) + this.modulesPositionRelatedStartX,
          this.modules_startY + (this.modules_offsetY * m * this.modules_height) + this.modulesPositionRelatedStartY,
          this.modules_width,
          this.modules_height
      )
    }

    paper.circle(this.startX, this.startY, 10);

    this.rendered = paper.setFinish();
  };

  RectAbstract.prototype.calculateModulesPosition = function (){

    var module_width = (this.base_width / this.modules) - SCHEME_OPTIONS.FIBER_MARGIN;

    switch(this.position){
      case POSITION_TOP :
        this.modules_startX = this.startX + (SCHEME_OPTIONS.FIBER_MARGIN / 2);
        this.modules_startY = this.startY + SCHEME_OPTIONS.CABLE_HEIGHT;
        break;
      case POSITION_BOT :
        this.modules_startX = this.startX + (SCHEME_OPTIONS.FIBER_MARGIN / 2);
        this.modules_startY = this.startY - SCHEME_OPTIONS.CABLE_HEIGHT;
        break;
      case POSITION_RIG :
        this.modules_startX = this.startX - SCHEME_OPTIONS.CABLE_HEIGHT;
        this.modules_startY = this.startY + (SCHEME_OPTIONS.FIBER_MARGIN / 2);
        break;
      case POSITION_LEF :
        this.modules_startX = this.startX + SCHEME_OPTIONS.CABLE_HEIGHT;
        this.modules_startY = this.startY + (SCHEME_OPTIONS.FIBER_MARGIN / 2);
        break;
    }

    if (this.position == POSITION_LEF || this.position == POSITION_RIG){
      this.modules_offsetX = 0;
      this.modules_offsetY = 1;
      //noinspection JSSuspiciousNameCombination
      this.modules_width = SCHEME_OPTIONS.MODULE_HEIGHT;
      //noinspection JSSuspiciousNameCombination
      this.modules_height = module_width;
    }
    else {
      this.modules_offsetX = 1;
      this.modules_offsetY = 0;
      this.modules_width = module_width;
      this.modules_height = SCHEME_OPTIONS.MODULE_HEIGHT;
    }

  };

  RectAbstract.prototype.rotate = function (redraw) {
    // Move start point
    switch (this.position) {
      case POSITION_TOP: // Rotate to POSITION_RIG
        this.startX += this.base_height;
        break;
      case POSITION_RIG:
        this.startX -= this.base_width;
        this.startY -= this.base_height;
        break;
      case POSITION_BOT:
        this.startY -= this.base_height;
        break;
    }

    var temp    = this.width;
    //noinspection JSSuspiciousNameCombination
    this.width  = this.height;
    this.height = temp;

    this.position = (this.position + 1) % 4;
    console.log('Position', this.position);

    if (redraw) this.render();
  };

  var rect = new RectAbstract({
    modules: 4,
    fibers : 16
  });
  rect.render();

  jQuery('#drawCanvas').on('click', function(){rect.rotate(true)});

  window['rect'] = rect;
</script>