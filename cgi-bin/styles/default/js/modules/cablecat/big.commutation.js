let SCHEME_OPTIONS = null;
let paper = null;

let paperParams = {};

let DEFAULT_SCHEME_OPTIONS = {
    CABLE_SHELL_HEIGHT: 25 * 2,
    CABLE_WIDTH_MARGIN: 6 * 2,

    MODULE_HEIGHT: 5 * 2,
    FIBER_WIDTH: 4 * 2,
    FIBER_HEIGHT: 20 * 2,
    FIBER_MARGIN: 6 * 2,

    ROUTER_WIDTH: 25 * 2,
    ROUTER_HEIGHT_MARGIN: 5 * 2,
    OPPOSITE_SHIFT: 3 * 2
};

let CABLE_POSITIONS_ARR = [
    'left',
    'right',
    'top'
];

let CABLES_LIST = {};
let SPLITTERS_LIST = {};
let CROSSES_LIST = {};
let EQUIPMENTS_LIST = {};
let CIRCLES_LIST = {};
let LINES_LIST = {};

let CABLES_BY_ID = {};

let SCHEMES = {};
let SCHEMES_BY_BASE_ID = {};

let COLORS_NAME = {
    '#fcfefc' : 'White',
    '#04fefc' : 'Sea',
    '#fcfe04' : 'Yellow',
    '#048204' : 'Green',
    '#840204' : 'Brown',
    '#fc0204' : 'Red',
    '#fc9a04' : 'Orange',
    '#fc9acc' : 'Pink',
    '#848284' : 'Gray',
    '#0402fc' : 'Blue',
    '#840284' : 'Violet',
    '#040204' : 'Black',
    '#04fe04' : 'Yellowgreen',
    '#9cce04' : 'Olive',
    '#fcfe9c' : 'Beige',
    '#dbefdb' : 'Natural',
    '#fde910' : 'Lemon',
    '#9c3232' : 'Cherry',
};

function initOptions(options) {
    let width  = options.width || jQuery('#drawCanvas').parent().width();
    let height = options.height || Number.MAX_VALUE;

    SCHEME_OPTIONS = {
        CABLE_SHELL_HEIGHT: DEFAULT_SCHEME_OPTIONS.CABLE_SHELL_HEIGHT,
        CABLE_WIDTH_MARGIN: DEFAULT_SCHEME_OPTIONS.CABLE_WIDTH_MARGIN,
        CABLE_COLOR: DEFAULT_SCHEME_OPTIONS.CABLE_COLOR,

        MODULE_HEIGHT: DEFAULT_SCHEME_OPTIONS.MODULE_HEIGHT,

        FIBER_WIDTH: DEFAULT_SCHEME_OPTIONS.FIBER_WIDTH,
        FIBER_HEIGHT: DEFAULT_SCHEME_OPTIONS.FIBER_HEIGHT,
        FIBER_MARGIN: DEFAULT_SCHEME_OPTIONS.FIBER_MARGIN,
        OPPOSITE_SHIFT: DEFAULT_SCHEME_OPTIONS.OPPOSITE_SHIFT,

        ROUTER_WIDTH: DEFAULT_SCHEME_OPTIONS.ROUTER_WIDTH,
        ROUTER_HEIGHT_MARGIN: DEFAULT_SCHEME_OPTIONS.ROUTER_HEIGHT_MARGIN,
        ROUTER_COLOR: DEFAULT_SCHEME_OPTIONS.ROUTER_COLOR,
    };

    SCHEME_OPTIONS.CABLE_FULL_HEIGHT = SCHEME_OPTIONS.CABLE_SHELL_HEIGHT + SCHEME_OPTIONS.MODULE_HEIGHT + SCHEME_OPTIONS.FIBER_HEIGHT;
    SCHEME_OPTIONS.FIBER_FULL_WIDTH  = SCHEME_OPTIONS.FIBER_WIDTH + SCHEME_OPTIONS.FIBER_MARGIN;

    SCHEME_OPTIONS.CANVAS_WIDTH  = width;
    SCHEME_OPTIONS.CANVAS_HEIGHT = height;

    SCHEME_OPTIONS.CANVAS_Y_CENTER = SCHEME_OPTIONS.CANVAS_HEIGHT / 2;
    SCHEME_OPTIONS.CANVAS_X_CENTER = SCHEME_OPTIONS.CANVAS_WIDTH / 2;

    SCHEME_OPTIONS.CANVAS_START_X = 0;
    SCHEME_OPTIONS.CANVAS_START_Y = 0;
    SCHEME_OPTIONS.SCALE = 2;
}

function cablecatMain() {

    let drawCanvas = jQuery('#drawCanvas');
    initOptions({
        width : drawCanvas.parent().width(),
        height: drawCanvas.parent().height()
    });

    paper = new Raphael('drawCanvas', SCHEME_OPTIONS.CANVAS_WIDTH, SCHEME_OPTIONS.CANVAS_HEIGHT);
    drawCanvas.css({
        width : SCHEME_OPTIONS.CANVAS_WIDTH,
        height: SCHEME_OPTIONS.CANVAS_HEIGHT
    });

    paperParams.startWidth = SCHEME_OPTIONS.CANVAS_WIDTH;
    paperParams.startHeight = SCHEME_OPTIONS.CANVAS_HEIGHT;
    paperParams.startCoords = { x:0, y: 0 };

    paperParams.viewBoxWidth = paperParams.startWidth;
    paperParams.viewBoxHeight = paperParams.startHeight;
    paperParams.coordsViewBox = paperParams.startCoords;

    fetch('?header=2&get_index=cablecat_get_added_schemes')
        .then(response => {
            return response.json();
        })
        .then(result => {
            result.forEach(resultScheme => {
                let scheme = new Scheme(resultScheme.commutation_id, resultScheme);
                SCHEMES[scheme.id] = scheme;
                SCHEMES_BY_BASE_ID[scheme.base.id] = scheme;
                scheme.enableDrag();
            });


        })
        .catch(error => {
            console.log(error);
        });
}

jQuery(function () {
    cablecatMain();

    jQuery('#drawCanvas').on('mousedown', function (e) {
        if (e.button !== 2) return;

        let x = e.offsetX;
        let y = e.offsetY;

        if (paperParams.viewBoxWidth && paperParams.startWidth) {
            x *= paperParams.viewBoxWidth / paperParams.startWidth;
            y *= paperParams.viewBoxHeight / paperParams.startHeight;

            x += paperParams.coordsViewBox.x;
            y += paperParams.coordsViewBox.y;
        }

        SCHEME_OPTIONS.CANVAS_START_X = x;
        SCHEME_OPTIONS.CANVAS_START_Y = y;
    });

    paper.viewBoxWidth = paper.width;
    paper.startViewBoxWidth = paper.width;

    paper.viewBoxHeight = paper.height;
    paper.startViewBoxHeight = paper.height;

    zoomAndPan(paper);
});

class Scheme {
    commutation_y;
    constructor(id, params) {
        this.id = id;
        this.splitters = [];
        this.crosses = [];
        this.equipments = [];
        this.cables = [];
        this.set = paper.set();
        this.setItems = [];
        this.schemeHeight = params.height || SCHEME_OPTIONS.CANVAS_HEIGHT;
        this.schemeWidth = params.width || paper.width;
        this.cableByPositions = {
            left  : [],
            right : [],
            top   : [],
            bottom: []
        };
        this.name = params.NAME ? this.id + '. ' + params.NAME : "";

        if (params.commutation_x && params.commutation_y) {
            this.added = 1;
            SCHEME_OPTIONS.CANVAS_START_X = params.commutation_x;
            SCHEME_OPTIONS.CANVAS_START_Y = params.commutation_y;
        }

        this.schemeStartX = SCHEME_OPTIONS.CANVAS_START_X;
        this.schemeStartY = SCHEME_OPTIONS.CANVAS_START_Y;

        if (!params || !params.CABLES) return this;

        this.calculateCablePosition(params.CABLES);

        this.drawFoundation();

        SCHEMES[this.id] = this;
        this.schemeCenterX = (this.schemeStartX + (this.schemeStartX + this.schemeWidth)) / 2;
        this.schemeCenterY = (this.schemeStartY + (this.schemeStartY + this.schemeHeight)) / 2;

        this.drawCables();
        this.drawSplitters(params.SPLITTERS);
        this.drawCrosses(params.CROSSES);
        this.drawEquipment(params.EQUIPMENT);
        this.drawLinks(params.LINKS);
    }

    drawFoundation() {
        this.getSchemeHeight();

        if (!this.added) {
            fetch('?header=2&get_index=cablecat_fill_scheme_coords&COMMUTATION_ID=' + this.id + '&COMMUTATION_X=' + this.schemeStartX
                + '&COMMUTATION_Y=' + this.schemeStartY + '&WIDTH=' + this.schemeWidth + '&HEIGHT=' + this.schemeHeight)
                .catch(error => {
                    console.log(error);
                });
        }

        this.base = paper.rect(this.schemeStartX, this.schemeStartY,  this.schemeWidth,  this.schemeHeight).attr({
            'fill': '#ccc',
            'stroke-width': 1,
            'stroke-dasharray': '- ',
            'fill-opacity': '0.2',
            'class': 'base'
        });

        this.base.schemeId = this.id;

        this.schemeEndX = this.schemeWidth + this.schemeStartX - (DEFAULT_SCHEME_OPTIONS.CABLE_SHELL_HEIGHT
            + DEFAULT_SCHEME_OPTIONS.MODULE_HEIGHT + DEFAULT_SCHEME_OPTIONS.FIBER_HEIGHT + DEFAULT_SCHEME_OPTIONS.OPPOSITE_SHIFT);

        let nameTitle = paper.text(this.schemeStartX + this.schemeWidth / 2, this.schemeStartY + 50, this.name)
            .attr({'font-size': '26px', 'font-weight': 'bold', 'font-family': 'sans-serif', 'opacity': '0.2'});

        this.set.push(this.base);
        this.set.push(nameTitle);
    }

    calculateCablePosition(Cables) {
        Cables.forEach((value, index) => {
            if (CABLES_BY_ID[value.id]) return;

            let cable = new Cable(value, index, this.cableByPositions, this.id);
            CABLES_LIST[cable.id] = {};
            CABLES_LIST[cable.id].info = cable;
            this.cables.push(cable.id);

            CABLES_BY_ID[value.id] = cable.id;
        });
    }

    drawCables() {
        this.cables.forEach(cableId => {
            let oldInfo = CABLES_LIST[cableId].info;
            oldInfo.render();

            CABLES_LIST[cableId].info = oldInfo;
            this.set.push(CABLES_LIST[cableId]);
            CABLES_LIST[cableId].info.lines = [];
        });

        return this;
    }

    drawSplitters(Splitters) {
        if (!Splitters) return this;

        Splitters.forEach(value => {
            let splitter = new Splitter(value, this.id);

            this.splitters.push(splitter.id);
            SPLITTERS_LIST[splitter.id].info = splitter;
            SPLITTERS_LIST[splitter.id].info.lines = [];

            this.set.push(SPLITTERS_LIST[splitter.id]);
        });

        return this;
    }

    drawCrosses(Crosses) {
        if (!Crosses) return this;

        Crosses.forEach(value => {
            let cross = new Cross(value, this.id);

            this.crosses.push(cross.id);
            CROSSES_LIST[cross.id].info = cross;
            CROSSES_LIST[cross.id].info.lines = [];

            this.set.push(CROSSES_LIST[cross.id]);
        });

        return this;
    }

    drawEquipment(Equipments) {
        if (!Equipments) return this;

        Equipments.forEach(value => {
            let equipment = new Equipment(value, this.id);

            this.equipments.push(equipment.id);
            EQUIPMENTS_LIST[equipment.id].info = equipment;
            EQUIPMENTS_LIST[equipment.id].info.lines = [];

            this.set.push(EQUIPMENTS_LIST[equipment.id]);
        });

        return this;
    }

    drawLinks(Links) {
        if (!Links) return this;

        Links.forEach(value => {
            value.firstElement = this.getElementByType(value.element_1_type, value.element_1_id);
            value.secondElement = this.getElementByType(value.element_2_type, value.element_2_id);
            let link = new Link(value, this.id);

            if (link.renderLinks) this.set.push(link.renderLinks);
        });
    }

    enableDrag(onlyBase = false)  {
        let self = this;

        this.set.items.forEach(value => {
            if (value.type !== 'set') {
                this.setItems.push(value);
            }
            else {
                this.setItems = this.setItems.concat(value.items);
            }
        });

        this.setItems.id = this.id;

        paper.draggableSet(this.setItems, this.base, null, true, ['circle']);

        eve.on('raphael.drag.start.' + this.id, () => {
            self.cables.forEach(cable => {
                CABLES_LIST[cable].info.lines.forEach(line => {
                    if (LINES_LIST[line.id] && LINES_LIST[line.id].info.schemeId !== self.id) {
                        let oldCoords = LINES_LIST[line.id].attr('path');
                        LINES_LIST[line.id].info.oldCoords = oldCoords;
                    }
                });
            });
        });

        eve.on('raphael.drag.move.' + this.id, (dX, dY) => {
            self.cables.forEach(cable => {
                CABLES_LIST[cable].info.lines.forEach(line => {
                    let lineInfo = LINES_LIST[line.id];
                    if (lineInfo && lineInfo.info.schemeId !== self.id) {
                        let newPosition = [];
                        newPosition.push(lineInfo.info.oldCoords[0][0]);
                        newPosition.push(lineInfo.info.oldCoords[0][1]);
                        newPosition.push(lineInfo.info.oldCoords[0][2]);

                        newPosition.push(lineInfo.info.oldCoords[1][0]);
                        newPosition.push(lineInfo.info.oldCoords[1][1]);
                        newPosition.push(lineInfo.info.oldCoords[1][2]);

                        if (lineInfo.info.endFiber.reverse) {
                            newPosition[4] += dX;
                            newPosition[5] += dY;
                        }
                        else if (lineInfo.info.startFiber.reverse) {
                            newPosition[1] += dX;
                            newPosition[2] += dY;
                        }

                        lineInfo.attr('path', newPosition);

                        Link.moveCenterCircle(
                            {x: newPosition[1], y: newPosition[2]},
                            {x: newPosition[4], y: newPosition[5]},
                            lineInfo.centerCircle
                        );
                    }
                });
            });
        });

        eve.on('raphael.drag.end.' + this.id, () => {
            self.schemeStartX = self.base.attr('x');
            self.schemeStartY = self.base.attr('y');

            fetch('?header=2&get_index=cablecat_fill_scheme_coords&COMMUTATION_ID=' + self.id + '&COMMUTATION_X=' + self.base.attr('x')
                + '&COMMUTATION_Y=' + self.base.attr('y') + '&change=1')
                .then(response => {
                    return response.json();
                })
                .then(result => {
                    if (result['error']) displayJSONTooltip({MESSAGE: {caption: result['error'], message_type: 'err'}});
                })
                .catch(error => {
                    console.log(error);
                });
        });

        if (onlyBase) return;

        this.cables.forEach(cableId => {
            CABLES_LIST[cableId].info.enableDrag();
        });

        this.splitters.forEach(splitterId => {
            SPLITTERS_LIST[splitterId].info.enableDrag();
        });

        this.crosses.forEach(crossId => {
            CROSSES_LIST[crossId].info.enableDrag();
        });

        this.equipments.forEach(equipmentId => {
            EQUIPMENTS_LIST[equipmentId].info.enableDrag();
        });

        return this;
    }

    disableDrag() {
        this.base.undrag();
    }

    getSchemeHeight() {
        let edgeMargin = DEFAULT_SCHEME_OPTIONS.CABLE_SHELL_HEIGHT
            + DEFAULT_SCHEME_OPTIONS.MODULE_HEIGHT + DEFAULT_SCHEME_OPTIONS.FIBER_HEIGHT;

        let maxLeftWidth = this.cableByPositions.left.reduce(Scheme.getSideWidth, 0);
        let maxRightWidth = this.cableByPositions.right.reduce(Scheme.getSideWidth, 0);

        this.schemeHeight = Math.max(maxLeftWidth, maxRightWidth) + edgeMargin * 3;
    }

    getElementByType(type, id) {
        if (type === 'CABLE') return CABLES_LIST[id] ? CABLES_LIST[id] : {};
        if (type === 'SPLITTER') return SPLITTERS_LIST[id] ? SPLITTERS_LIST[id] : {};
        if (type === 'CROSS') return CROSSES_LIST[id] ? CROSSES_LIST[id] : {};
        if (type === 'EQUIPMENT') return EQUIPMENTS_LIST[id] ? EQUIPMENTS_LIST[id] : {};

        return {};
    }

    static getSideWidth (widthBefore, nextCable) {
        return widthBefore + nextCable + DEFAULT_SCHEME_OPTIONS.CABLE_SHELL_HEIGHT;
    }
}

class HTMLTooltip {
    constructor(info, onElement, options) {
        this.html = this.formatTip(info);
        this.element = onElement;
        this.options = options;
        this.id = 'I' + generate_guid();

        this.toolTip = this.createDOM();
        this.height = this.toolTip.offsetHeight;
        this.width = this.toolTip.offsetWidth;
        this.show = () => {
            this.toolTip.style.visibility = 'visible';
        };
        this.hide = () => {
            this.toolTip.style.visibility = 'hidden';
        };

        this.hide();

        if (this.element) this.bindToEl(this.element);
    }

    createDOM () {
        let toolTip = document.createElement('div');
        toolTip.id = this.id;
        toolTip.style.zIndex = '1000';
        toolTip.style.backgroundColor = '#6d6d6d';
        toolTip.style.position = 'fixed';
        toolTip.style.color = 'white';
        toolTip.style.padding = '3px';
        toolTip.style.border = '1px solid white';
        toolTip.style.borderRadius = '5px';
        toolTip.style.maxWidth = '300px';

        toolTip.appendChild(this.html);

        document.body.appendChild(toolTip);

        return toolTip;
    }

    formatTip (input) {
        if (typeof input !== 'object') return input;

        let table = document.createElement('table');
        table.classList.add('table');
        table.classList.add('table-condensed');
        table.classList.add('no-margin');

        let tableBody = document.createElement('tbody');
        for (let key in input) {
            if (!input.hasOwnProperty(key) || typeof (input[key]) === 'undefined') continue;

            let tr = document.createElement('tr');

            let tdKey = document.createElement('td');
            tdKey.appendChild(document.createTextNode(_translate(key) + ':'));
            tdKey.style.textAlign = 'right';

            let tdValue = document.createElement('td');
            tdValue.appendChild(document.createTextNode(input[key]));

            tr.appendChild(tdKey);
            tr.appendChild(tdValue);

            tableBody.appendChild(tr);
        }
        table.appendChild(tableBody);
        return table;
    }

    bindToEl (element) {
        let self = this;
        element.hover(() => self.show(), () => self.hide()).mousemove(function (event) {self.moveTo(event.clientX, event.clientY)});
    }

    moveTo (left, top) {
        let left_shift = 70;
        let top_shift  = 40;

        if (left + this.width + left_shift > screen.width) left_shift = this.width + 10;

        this.toolTip.style.left = (left - left_shift).toString() + 'px';
        this.toolTip.style.top = (top - (this.height + top_shift)).toString() + 'px';
    }
}

class BaseElement {
    constructor(schemeId) {
        this.set = {};
        this.lines = [];
        this.fibers = [];
        this.reverseFibers = [];
        this.name = '';
        this.x = 0;
        this.y = 0;
        this.width = 0;
        this.height = 0;
        this.changed_coords = 0;
        this.schemeId = schemeId;
    }

    enableDrag() {
        let self = this;

        this.set.items.id = this.set.info.id;

        eve.on('raphael.drag.start.' + this.set.items.id, function () {
            if (!self.lines) return;

            self.lines.forEach(line => {
                let lineInfo = LINES_LIST[line.id];
                if (!lineInfo || !line.position) return;

                line.coords = lineInfo.attr('path');
            });
        });

        eve.on('raphael.drag.move.' + this.set.items.id, function (dx, dy) {
            if (!self.lines) return;

            self.lines.forEach(line => {
                Link.moveLine(line, dx, dy);
            });
        });

        eve.on('raphael.drag.end.' + this.set.items.id, function () {
            self.savePosition();
        });

        paper.draggableSet(this.set.items);
    }

    savePosition() {
        let self = this;
        let type = self.constructor.name.toLowerCase();

        let params = {
            qindex: INDEX,
            json: 1,
            header: 2,
            change_element_position: 1,
            COMMUTATION_X: (self.base.attr('x') - SCHEMES[self.schemeId].schemeStartX) / SCHEMES[self.schemeId].schemeWidth,
            COMMUTATION_Y: (self.base.attr('y') - SCHEMES[self.schemeId].schemeStartY) / SCHEMES[self.schemeId].schemeHeight,
            COMMUTATION_ID: self.schemeId,
            TYPE: type,
            ID: self.id
        };
        jQuery.post(SELF_URL, params)
            .fail(function (error) {
                aTooltip.displayError(error);
            });
    }

    drawFibers() {
        for (let i = 0; i < this.fibers.length; i++) {
            let fiberRect = paper.rect(this.fibers[i].x, this.fibers[i].y, this.fibers[i].width, this.fibers[i].height).attr({
                fill: this.fibers[i].color,
                'stroke-width': 2,
                'class': 'fiber'
            });

            if (this.fibers[i].showNum) {
                paper.text(this.fibers[i].x + SCHEME_OPTIONS.FIBER_WIDTH / 2,
                    this.fibers[i].y + SCHEME_OPTIONS.FIBER_HEIGHT / 3 + 3, this.fibers[i].num + 1);
            }

            if (this.reverseFibers[i]) {
                this.reverseFibers[i].rendered = paper.rect(this.reverseFibers[i].x, this.reverseFibers[i].y, this.reverseFibers[i].width, this.reverseFibers[i].height).attr({
                    fill: this.reverseFibers[i].color,
                    'stroke-width': 2,
                    'class': 'fiber'
                });
            }

            this.fibers[i].rendered = fiberRect;
        }
    }

    checkColorsLength(colors_array, desired_length) {
        if (colors_array.length > desired_length) {
            colors_array = colors_array.slice(0, desired_length);
        } else if (colors_array.length < desired_length) {
            alert('Check color scheme. Color scheme is not enough to show : ' + this.name);
            return false;
        }

        return colors_array;
    }

    render(className, fillColor) {
        paper.setStart();

        this.base = paper.rect(this.x, this.y, this.width, this.height).attr({
            fill: fillColor,
            'class': className,
            'stroke-width': 2
        });

        this.drawFibers();
        this.drawModules();

        this.set = paper.setFinish();
    }

    drawModules () {
        let modules = this.modules;

        if (!modules) return;
        let reverseModules = this.reverseModules;

        let modules_colors = this.checkColorsLength(this.image.modules_color_scheme, this.image.modules);

        if (!modules_colors) return false;

        this.filterMarked(modules_colors);
        let modulesColorPalette = new AColorPalette(modules_colors);

        for (let i = 0; i < this.image.modules; i++) {
            paper.rect(modules.x + modules.ox * i, modules.y + modules.oy * i, modules.width, modules.height)
                .attr({
                    fill: modulesColorPalette.getNextColorHex(),
                    'stroke-width': SCHEME_OPTIONS.SCALE
                });

            paper.rect(reverseModules.x + reverseModules.ox * i, reverseModules.y + reverseModules.oy * i,
                reverseModules.width, reverseModules.height).attr({
                fill: modulesColorPalette.getCurrentColorHex(),
                'stroke-width': SCHEME_OPTIONS.SCALE
            });
        }
    }

    filterMarked (colors_array) {
        let marked = {};

        for (var i = 0; i < colors_array.length; i++) {
            if (colors_array[i].indexOf('+') <= 0) continue;

            marked[i] = true;
            colors_array[i] = colors_array[i].substr(0, colors_array[i].indexOf('+'));
        }

        return marked;
    }

    calculateSizes (count) {
        this.width  = count * SCHEME_OPTIONS.FIBER_FULL_WIDTH + SCHEME_OPTIONS.FIBER_MARGIN / 2;
        this.height = SCHEME_OPTIONS.CABLE_SHELL_HEIGHT / 2;

        if (this.commutation_x && this.commutation_y) {
            this.x = +this.commutation_x;
            this.y = +this.commutation_y;
        }
        else {
            this.x = +(SCHEME_OPTIONS.CANVAS_X_CENTER - (this.width / 2));
            this.y = +(SCHEME_OPTIONS.CANVAS_Y_CENTER - (this.height / 2));
        }

        if (!this.commutation_x && this.num > 0) this.x += (this.width * this.num) + SCHEME_OPTIONS.FIBER_MARGIN * 2;

        if (!this.changed_coords) {
            this.x += SCHEME_OPTIONS.CANVAS_START_X;
            this.y += SCHEME_OPTIONS.CANVAS_START_Y;
        }
        else {
            this.x = this.x * SCHEMES[this.schemeId].schemeWidth + SCHEMES[this.schemeId].schemeStartX;
            this.y = this.y * SCHEMES[this.schemeId].schemeHeight + SCHEMES[this.schemeId].schemeStartY;
        }
    }

    getCenteredFibersStartX (fibersCount) {
        return (this.width / 2) - ((SCHEME_OPTIONS.FIBER_FULL_WIDTH * fibersCount - SCHEME_OPTIONS.FIBER_MARGIN) / 2);
    }

    addTooltip(additionalOptions) {
        let options = {
            Id: this.id || (this.meta ? this.meta.id : ''),
            name: this.name || (this.meta ? this.meta.name : '')
        };

        if (additionalOptions && typeof additionalOptions === 'object') Object.assign(options, additionalOptions);

        new HTMLTooltip(options, this.set);
    }
}

class Cable extends BaseElement{
    constructor(cable, index, cableByPositions, schemeId) {
        super(schemeId);
        Object.assign(this, cable);

        this.position = CABLE_POSITIONS_ARR[index % CABLE_POSITIONS_ARR.length];
        this.number = cableByPositions[this.position].length;
        this.cableByPositions = cableByPositions;

        this.calculateSizes();
    }

    calculateSizes() {
        this._getCableParams();
    }

    _getCableParams () {

        let position = this.position,
            number   = this.number,
            fibersCount = this.image.fibers;

        let mirrored = ((position === 'bottom') || (position === 'right'));
        let vertical = ((position === 'top') || (position === 'bottom'));

        let way = (mirrored) ? -1 : 1;

        let width = fibersCount * (SCHEME_OPTIONS.FIBER_WIDTH + SCHEME_OPTIONS.FIBER_MARGIN)
            + SCHEME_OPTIONS.CABLE_WIDTH_MARGIN;
        let height = SCHEME_OPTIONS.CABLE_SHELL_HEIGHT;

        let offset = SCHEME_OPTIONS.OPPOSITE_SHIFT;

        // If not first cable on side
        if (number !== 0) {
            let widthOfBeforeCables = this.cableByPositions[position].reduce(Scheme.getSideWidth, 0);
            offset += widthOfBeforeCables;
        }

        let x, y;
        if (vertical) {
            x = (SCHEME_OPTIONS.CABLE_FULL_HEIGHT / 2) + SCHEME_OPTIONS.CABLE_FULL_HEIGHT + offset;
            y = (mirrored) ? SCHEME_OPTIONS.CANVAS_HEIGHT - height : 0;
        }
        else {
            x = (mirrored) ? SCHEME_OPTIONS.CANVAS_WIDTH - height : 0;
            y = (SCHEME_OPTIONS.CABLE_FULL_HEIGHT / 2) + SCHEME_OPTIONS.CABLE_FULL_HEIGHT + offset;
        }

        if (!vertical) [height, width] = [width, height];

        this.cableByPositions[this.position].push(height);

        y += SCHEME_OPTIONS.CANVAS_START_Y;
        x += SCHEME_OPTIONS.CANVAS_START_X;

        this.x = this.commutation_x || x;
        this.y = this.commutation_y || y;
        this.width = width;
        this.height = height;
        this.vertical = vertical;
        this.way = way;
        this.set = {};
    }

    _getModulesParams() {
        let width  = this.image.fibers * (SCHEME_OPTIONS.FIBER_WIDTH + SCHEME_OPTIONS.FIBER_MARGIN) / this.image.modules;
        let height = SCHEME_OPTIONS.MODULE_HEIGHT;

        let y = this.y + this.height;
        let x = this.x + SCHEME_OPTIONS.CABLE_WIDTH_MARGIN / 2;

        let y2 = this.y + this.height;
        let x2 = this.x + SCHEME_OPTIONS.CABLE_WIDTH_MARGIN / 2;

        if (!this.vertical) {
            y = this.y + SCHEME_OPTIONS.CABLE_WIDTH_MARGIN / 2;
            x = this.x + SCHEME_OPTIONS.MODULE_HEIGHT * this.way;

            y2 = this.y + SCHEME_OPTIONS.CABLE_WIDTH_MARGIN / 2;
            x2 = this.x - SCHEME_OPTIONS.MODULE_HEIGHT * this.way;

            if (this.way >= 0) {
                x += SCHEME_OPTIONS.CABLE_SHELL_HEIGHT - SCHEME_OPTIONS.MODULE_HEIGHT;
            }
            else {
                x2 += SCHEME_OPTIONS.CABLE_SHELL_HEIGHT - SCHEME_OPTIONS.MODULE_HEIGHT;
            }
        }
        else {
            if (this.way < 0) {
                y -= this.height + SCHEME_OPTIONS.MODULE_HEIGHT;
            }
            else {
                y2 -= this.height + SCHEME_OPTIONS.MODULE_HEIGHT;
            }
        }

        let offset_y = 0;
        let offset_x = width;

        if (!this.vertical) {
            offset_x = 0;
            offset_y = width;

            [height, width] = [width, height];
        }

        this.modules = {
            x: x,
            y: y,
            ox: offset_x,
            oy: offset_y,
            width: width,
            height: height,
            nextColor: true
        };

        this.reverseModules = {
            x: x2,
            y: y2,
            ox: offset_x,
            oy: offset_y,
            width: width,
            height: height
        };
    }

    _getFibersParams () {
        this._getVerticalFibers();
        this._getHorizontalFibers();

        if (!this.fiberParams) return;

        let fiber_colors = this.checkColorsLength(this.image.color_scheme, this.image.fibers / this.image.modules);
        if (!fiber_colors) return false;

        // var marked             = this.filterMarked(fiber_colors);
        let fibersColorPalette = new AColorPalette(fiber_colors);

        for (let i = 0; i < this.image.fibers; i++) {

            this.fibers.push({
                x       : this.fiberParams.x + this.fiberParams.ox * i,
                y       : this.fiberParams.y + this.fiberParams.oy * i,
                width   : this.fiberParams.width,
                height  : this.fiberParams.height,
                edge    : {
                    x: this.fiberParams.x + this.fiberParams.ox * i + this.fiberParams.edge_x_offset,
                    y: this.fiberParams.y + this.fiberParams.oy * i + this.fiberParams.edge_y_offset
                },
                start   : {
                    x: this.fiberParams.x + this.fiberParams.ox * i + this.fiberParams.start_x,
                    y: this.fiberParams.y + this.fiberParams.oy * i + this.fiberParams.start_y
                },
                color   : fibersColorPalette.getNextColorHex(),
                vertical: this.fiberParams.vertical,
                // marked  : marked[i] === true
            });

            if (!this.reverseFiberParams) continue;

            this.reverseFibers.push({
                x: this.reverseFiberParams.x + this.reverseFiberParams.ox * i,
                y: this.reverseFiberParams.y + this.reverseFiberParams.oy * i,
                width: this.reverseFiberParams.width,
                height: this.reverseFiberParams.height,
                edge: {
                    x: this.reverseFiberParams.x + this.reverseFiberParams.ox * i + this.reverseFiberParams.edge_x_offset,
                    y: this.reverseFiberParams.y + this.reverseFiberParams.oy * i + this.reverseFiberParams.edge_y_offset
                },
                start: {
                    x: this.reverseFiberParams.x + this.reverseFiberParams.ox * i + this.reverseFiberParams.start_x,
                    y: this.reverseFiberParams.y + this.reverseFiberParams.oy * i + this.reverseFiberParams.start_y
                },
                color: fibersColorPalette.getCurrentColorHex(),
                vertical: this.reverseFiberParams.vertical,
            });
        }
    }

    _getVerticalFibers() {
        let module = this.modules;

        if (!this.vertical) return;

        let first_y, edge_x_offset, edge_y_offset, start_y;
        let first_x = module.x + SCHEME_OPTIONS.FIBER_MARGIN / 2;

        if (this.way < 0) { // Bottom
            first_y = module.y - SCHEME_OPTIONS.FIBER_HEIGHT;
            edge_x_offset = SCHEME_OPTIONS.FIBER_WIDTH / 2;
            edge_y_offset = 0;

            start_y = SCHEME_OPTIONS.FIBER_HEIGHT;
        } else { // Up
            first_y = module.y + SCHEME_OPTIONS.MODULE_HEIGHT;
            edge_x_offset = SCHEME_OPTIONS.FIBER_WIDTH / 2;
            edge_y_offset = SCHEME_OPTIONS.FIBER_HEIGHT * this.way;
            start_y = 0;
        }

        this.fiberParams = {
            x: first_x,
            y: first_y,
            ox: SCHEME_OPTIONS.FIBER_WIDTH + SCHEME_OPTIONS.FIBER_MARGIN,
            oy: 0,
            width: SCHEME_OPTIONS.FIBER_WIDTH,
            height: SCHEME_OPTIONS.FIBER_HEIGHT,
            edge_x_offset: edge_x_offset,
            edge_y_offset: edge_y_offset,
            start_x: edge_x_offset,
            start_y: start_y,
            vertical: 1
        };

        this.reverseFiberParams = {
            x: first_x,
            y: module.y - SCHEME_OPTIONS.CABLE_SHELL_HEIGHT * 2,
            ox: SCHEME_OPTIONS.FIBER_WIDTH + SCHEME_OPTIONS.FIBER_MARGIN,
            oy: 0,
            width: SCHEME_OPTIONS.FIBER_WIDTH,
            height: SCHEME_OPTIONS.FIBER_HEIGHT,
            edge_x_offset: edge_x_offset,
            edge_y_offset: edge_y_offset,
            start_x: edge_x_offset,
            start_y: start_y,
            vertical: 1
        };
    }

    _getHorizontalFibers() {
        let module = this.modules;

        if (this.vertical) return;

        let edge_x_offset, edge_y_offset, start_x;

        let first_x = module.x + SCHEME_OPTIONS.MODULE_HEIGHT;
        let first_y = module.y + SCHEME_OPTIONS.FIBER_MARGIN / 2;

        if (this.way < 0) { // Right
            first_x -= SCHEME_OPTIONS.FIBER_HEIGHT + SCHEME_OPTIONS.MODULE_HEIGHT;

            edge_x_offset = 0;
            edge_y_offset = SCHEME_OPTIONS.FIBER_WIDTH / 2;

            start_x = SCHEME_OPTIONS.FIBER_HEIGHT;

        }
        else { // Left
            edge_x_offset = SCHEME_OPTIONS.FIBER_HEIGHT * this.way;
            edge_y_offset = SCHEME_OPTIONS.FIBER_WIDTH / 2;

            start_x = 0;
        }

        this.fiberParams = {
            x: first_x,
            y: first_y,
            ox: 0,
            oy: SCHEME_OPTIONS.FIBER_WIDTH + SCHEME_OPTIONS.FIBER_MARGIN,
            width: SCHEME_OPTIONS.FIBER_HEIGHT,
            height: SCHEME_OPTIONS.FIBER_WIDTH,
            edge_x_offset: edge_x_offset,
            edge_y_offset: edge_y_offset,
            start_x: start_x,
            start_y: edge_y_offset
        };

        this.reverseFiberParams = {
            x: this.way < 0 ? module.x + SCHEME_OPTIONS.MODULE_HEIGHT * 2 + SCHEME_OPTIONS.CABLE_SHELL_HEIGHT : module.x - SCHEME_OPTIONS.CABLE_SHELL_HEIGHT * 2,
            y: first_y,
            ox: 0,
            oy: SCHEME_OPTIONS.FIBER_WIDTH + SCHEME_OPTIONS.FIBER_MARGIN,
            width: SCHEME_OPTIONS.FIBER_HEIGHT,
            height: SCHEME_OPTIONS.FIBER_WIDTH,
            edge_x_offset: edge_x_offset,
            edge_y_offset: edge_y_offset,
            start_x: start_x,
            start_y: edge_y_offset
        };
    }

    render() {

        if (this.changed_coords) {
            if (this.vertical) {
                this.y = this.y * SCHEMES[this.schemeId].schemeHeight + SCHEMES[this.schemeId].schemeStartY;
                this.x = this.x * SCHEMES[this.schemeId].schemeWidth + SCHEMES[this.schemeId].schemeStartX;
            }
            else {
                this.x = this.x * SCHEMES[this.schemeId].schemeWidth + SCHEMES[this.schemeId].schemeStartX;
                this.y = this.y * SCHEMES[this.schemeId].schemeHeight + SCHEMES[this.schemeId].schemeStartY;
            }
        }

        this._getModulesParams();
        this._getFibersParams();

        super.render('cable',this.image.color || SCHEME_OPTIONS.CABLE_COLOR);
        CABLES_LIST[this.id] = this.set;
        this.addTooltip({length: this.meta.length});
    }
}

class Splitter extends BaseElement{
    constructor(splitter, schemeId) {
        super(schemeId);
        Object.assign(this, splitter);
        this.inputs = +this.fibers_in;
        this.outputs = +this.fibers_out;
        this.fibers = [];

        this.calculateSizes(Math.max(this.inputs, this.outputs));
        this.calculateFiberPositions();
        this.render();

        this.addTooltip({ name: this.id + '. ' + this.type});
    }

    calculateFiberPositions() {
        this.inputs_start_x = this.getCenteredFibersStartX(this.inputs);
        this.inputs_edge_y  = SCHEME_OPTIONS.FIBER_HEIGHT / 2;

        this.outputs_start_x = this.getCenteredFibersStartX(this.outputs);
        this.outputs_edge_y  = this.height;


        let fiber_colors = this.checkColorsLength(this.color_scheme, this.inputs + this.outputs);
        if (!fiber_colors) return false;

        let fibersColorPalette = new AColorPalette(fiber_colors);

        // Input fibers
        for (let i = 0; i < this.inputs; i++) {
            let fiber_x = this.x + this.inputs_start_x + SCHEME_OPTIONS.FIBER_FULL_WIDTH * i;
            let fiber_y = this.y - this.inputs_edge_y;

            this.fibers.push({
                num: i,
                x: fiber_x,
                y: fiber_y,
                width   : SCHEME_OPTIONS.FIBER_WIDTH,
                height  : SCHEME_OPTIONS.FIBER_HEIGHT / 2,
                vertical: true,
                edge: {
                    x: fiber_x + SCHEME_OPTIONS.FIBER_WIDTH / 2,
                    y: fiber_y
                },
                color: fibersColorPalette.getNextColorHex()
            });
        }

        // Output fibers
        for (let i = 0; i < this.outputs; i++) {
            let fiber_x              = this.x + this.outputs_start_x + SCHEME_OPTIONS.FIBER_FULL_WIDTH * i;
            let fiber_y              = this.y + this.outputs_edge_y;
            this.fibers.push({
                num    : this.inputs + i,
                x      : fiber_x,
                y      : fiber_y,
                width  : SCHEME_OPTIONS.FIBER_WIDTH,
                height : SCHEME_OPTIONS.FIBER_HEIGHT / 2,
                edge   : {
                    x: fiber_x + SCHEME_OPTIONS.FIBER_WIDTH / 2,
                    y: fiber_y + SCHEME_OPTIONS.FIBER_HEIGHT / 2
                },
                color: fibersColorPalette.getNextColorHex()
            });
        }
    }

    render() {
        super.render('splitter', '#FFF');
        SPLITTERS_LIST[this.id] = this.set;
    }
}

class Cross extends BaseElement{
    constructor(cross, schemeId) {
        super(schemeId);
        Object.assign(this, cross);

        this.fiberStart = this.port_start - 1;
        this.fibersStartX = 9;
        this.fibersEdgeY  = 0;

        this.calculateSizes(this.ports);
        this.calculateFiberPositions();
        this.render();

        this.addTooltip();
    }

    render() {
        super.render('cross', 'lightyellow');
        CROSSES_LIST[this.id] = this.set;
    }

    calculateFiberPositions () {
        let fiberOffset = this.fiberStart || 0;
        for (let i = 0; i < this.ports; i++) {
            let fiberX    = this.x + this.fibersStartX + SCHEME_OPTIONS.FIBER_FULL_WIDTH * i;
            let fiberY    = this.y - this.fibersEdgeY;

            this.fibers.push({
                num: fiberOffset + i,
                x: fiberX,
                y: fiberY,
                vertical: true,
                edge: {
                    x: fiberX + SCHEME_OPTIONS.FIBER_WIDTH / 2,
                    y: fiberY
                },
                color: 'silver',
                width: SCHEME_OPTIONS.FIBER_WIDTH,
                height: SCHEME_OPTIONS.FIBER_HEIGHT / 4,
                showNum: true
            });
        }
    }
}

class Equipment extends BaseElement{
    constructor(equipment, schemeId) {
        super(schemeId);
        Object.assign(this, equipment);

        this.fibersStartX = 9;
        this.fibersEdgeY  = 0;

        this.calculateSizes(this.ports);
        this.calculateFiberPositions();
        this.render();

        this.addTooltip({name: this.model_name});
    }

    render() {
        super.render('equipment', 'lightblue');
        EQUIPMENTS_LIST[this.id] = this.set;
    }

    calculateFiberPositions () {
        let fiberOffset = 0;
        for (let i = 0; i < this.ports; i++) {
            let fiberX    = this.x + this.fibersStartX + SCHEME_OPTIONS.FIBER_FULL_WIDTH * i;
            let fiberY    = this.y - this.fibersEdgeY;

            this.fibers.push({
                num: fiberOffset + i,
                x: fiberX,
                y: fiberY,
                vertical: true,
                edge: {
                    x: fiberX + SCHEME_OPTIONS.FIBER_WIDTH / 2,
                    y: fiberY
                },
                color: 'silver',
                width: SCHEME_OPTIONS.FIBER_WIDTH,
                height: SCHEME_OPTIONS.FIBER_HEIGHT / 4,
                showNum: true
            });
        }
    }
}

class Link {
    constructor(link, schemeId) {
        Object.assign(this, link);

        this.schemeId = schemeId;

        this.fillStartFiberInfo();
        this.fillEndFiberInfo();

        this.pathAttr = {
            'stroke-width'   : SCHEME_OPTIONS.FIBER_WIDTH / 2,
            'stroke-linejoin': 'round',
            'stroke-linecap' : 'round',
            'class'          : 'fiber-link',
            'id'             : this.id
        };
        this.lines = [];

        this.render();
    }

    render() {
        if (!this.startFiber || !this.endFiber) return;

        if (this.geometry) {
            this.geometry = this.geometry.map(point => {
                return {
                    x: point.x * SCHEMES[this.schemeId].schemeWidth + SCHEMES[this.schemeId].schemeStartX,
                    y: point.y * SCHEMES[this.schemeId].schemeHeight + SCHEMES[this.schemeId].schemeStartY
                }
            });
        }
        else {
            this.computePath(this.startFiber, this.endFiber);
        }

        if (!this.geometry) return;

        this.colorLeft = this.startFiber.color;
        this.colorRight = this.endFiber.color;
        this.middlePoint = Math.ceil(this.geometry.length / 2) - 1;

        if (!this.changed_coords) {
            this.geometry[0] = this.startFiber;
            this.geometry[this.geometry.length - 1] = this.endFiber;
        }
        else {
            this.geometry.unshift(this.startFiber);
            this.geometry.push(this.endFiber);
        }

        paper.setStart();

        for (let i = 0; i < this.geometry.length - 1; i++) {
            this.pathAttr.stroke = (i < this.middlePoint) ? this.colorLeft : this.colorRight;
            let line = paper.path(Link.makePathCommand([this.geometry[i], this.geometry[i + 1]])).attr(this.pathAttr);
            this.lines.push(line.id);

            LINES_LIST[line.id] = line;
            LINES_LIST[line.id].info = this;
            LINES_LIST[line.id].moveCircles = [];

            if (i === 0) {
                this.firstElement.info.lines.push({id: line.id, position: 'start'});
                LINES_LIST[line.id].reverse = this.startFiber.reverse;
            }
            else if (i + 1 === this.geometry.length - 1) {
                this.secondElement.info.lines.push({id: line.id, position: 'end'});
                LINES_LIST[line.id].reverse = this.endFiber.reverse;
            }
        }

        for (let i = 0; i < this.lines.length; i++) {
            let pathCoords = LINES_LIST[this.lines[i]].attr('path');
            LINES_LIST[this.lines[i]].centerCircle = this.drawCircle(
                {x: pathCoords[0][1], y: pathCoords[0][2]},
                {x: pathCoords[1][1], y: pathCoords[1][2]},
                this.lines[i]
            );

            if (i !== this.lines.length - 1) {
                this.drawMoveCircle({x: pathCoords[1][1], y: pathCoords[1][2]}, this.lines[i], this.lines[i + 1], i);
            }
        }

        this.renderLinks = paper.setFinish();
    }

    computePath(startFiber, endFiber) {
        this.geometry = [];
        this.geometry.push(startFiber);

        if (startFiber === endFiber) {
            this.geometry.push(endFiber);
            return;
        }

        if (startFiber.vertical === endFiber.vertical) {
            this.setVerticalLink(startFiber, endFiber);
        }
        else {
            this.geometry.push({
                x: getCloserPoint(startFiber.x, endFiber.x, SCHEMES[this.schemeId].schemeWidth),
                y: getCloserPoint(startFiber.y, endFiber.y, SCHEMES[this.schemeId].schemeHeight)
            });
        }

        this.geometry.push(endFiber);
    }

    setVerticalLink(startFiber, endFiber) {
        let offset = SCHEME_OPTIONS.FIBER_MARGIN;
        offset /= SCHEME_OPTIONS.SCALE;
        let first_point, second_point;


        if (startFiber.vertical) {

            if (startFiber.x === endFiber.x) {
                this.geometry.push({x: startFiber.x, y: SCHEMES[this.schemeId].schemeCenterY});
            }
            else {
                first_point  = {
                    x: startFiber.x,
                    y: SCHEMES[this.schemeId].schemeCenterY
                };
                second_point = {
                    x: endFiber.x,
                    y: SCHEMES[this.schemeId].schemeCenterY
                };
                Array.prototype.push.apply(this.geometry, [first_point, getCoordsBetween(first_point, second_point), second_point]);
            }
        }
        else {
            if (startFiber.y === endFiber.y) {
                this.geometry.push({x: SCHEMES[this.schemeId].schemeCenterX, y: startFiber.y});
            }
            else {
                first_point  = {
                    x: SCHEMES[this.schemeId].schemeCenterX,
                    y: startFiber.y
                };
                second_point = {
                    x: SCHEMES[this.schemeId].schemeCenterX,
                    y: endFiber.y
                };
                Array.prototype.push.apply(this.geometry, [first_point, getCoordsBetween(first_point, second_point), second_point]);
            }
        }
    }

    drawCircle(firstPoint, secondPoint, line) {

        let self = this;
        let centerPoint = getCoordsBetween(firstPoint, secondPoint);
        let circle = paper.circle(centerPoint.x, centerPoint.y, 1).attr({
            'fill': 'black',
            'class': 'link-circle',
            'stroke-width': 4
        });
        circle.toFront();

        circle.line = {id: line};
        CIRCLES_LIST[circle.id] = circle;
        let leftLine = {};
        let rightLine = {};
        let oldMoveCircles = {};

        eve.on('raphael.drag.element.move.' + circle.id, function (dx, dy) {
            if (LINES_LIST[line]) {
                let oldInfo = LINES_LIST[line];
                oldMoveCircles = oldInfo.moveCircles;
                let oldCoords = LINES_LIST[line].attr('path');
                let stroke = LINES_LIST[line].attr('stroke');

                leftLine = paper.path(Link.makePathCommand([{x: oldCoords[0][1], y: oldCoords[0][2]}, {x: dx, y: dy}])).attr({
                    'stroke-width': SCHEME_OPTIONS.FIBER_WIDTH / 2,
                    'stroke-linejoin': 'round',
                    'stroke-linecap': 'round',
                    'class': 'fiber-link',
                    'stroke': stroke
                });

                rightLine = paper.path(Link.makePathCommand([{x: dx, y: dy}, {x: oldCoords[1][1], y: oldCoords[1][2]}])).attr({
                    'stroke-width': SCHEME_OPTIONS.FIBER_WIDTH / 2,
                    'stroke-linejoin': 'round',
                    'stroke-linecap': 'round',
                    'class': 'fiber-link',
                    'stroke': stroke
                });

                self.lines.push(leftLine.id);
                self.lines.push(rightLine.id);

                leftLine.centerCircle = self.drawCircle({x: oldCoords[0][1], y: oldCoords[0][2]}, {x: dx, y: dy}, leftLine.id);
                rightLine.centerCircle = self.drawCircle({x: dx, y: dy}, {x: oldCoords[1][1], y: oldCoords[1][2]}, rightLine.id);

                LINES_LIST[leftLine.id] = leftLine;
                LINES_LIST[rightLine.id] = rightLine;
                LINES_LIST[rightLine.id].moveCircles = [];
                LINES_LIST[leftLine.id].moveCircles = [];

                self.addLineToCableInfo(oldInfo, line, rightLine.id, leftLine.id);

                oldInfo.moveCircles.forEach(circle => {
                    if (CIRCLES_LIST[circle].leftLine.id === oldInfo.id) {
                        CIRCLES_LIST[circle].leftLine.id = rightLine.id;
                        CIRCLES_LIST[circle].toFront();
                        LINES_LIST[rightLine.id].moveCircles.push(circle);
                    }
                    else if (CIRCLES_LIST[circle].rightLine.id === oldInfo.id) {
                        CIRCLES_LIST[circle].rightLine.id = leftLine.id;
                        CIRCLES_LIST[circle].toFront();
                        LINES_LIST[leftLine.id].moveCircles.push(circle);
                    }
                });

                LINES_LIST[leftLine.id].info = oldInfo.info;
                LINES_LIST[rightLine.id].info = oldInfo.info;

                if (oldInfo.reverse) {
                    if (oldInfo.info.startFiber.reverse) LINES_LIST[leftLine.id].reverse = 1;
                    if (oldInfo.info.endFiber.reverse) LINES_LIST[rightLine.id].reverse = 1;
                }

                LINES_LIST[line].remove();
                delete LINES_LIST[line];
            }

            if (!leftLine || !rightLine) return;

            let leftCoords = leftLine.attr('path');
            leftCoords[1][1] = dx;
            leftCoords[1][2] = dy;

            let rightCoords = rightLine.attr('path');
            rightCoords[0][1] = dx;
            rightCoords[0][2] = dy;

            Link.moveLine({id: leftLine.id, position: 'end', coords: leftCoords}, 0, 0);
            Link.moveLine({id: rightLine.id, position: 'end', coords: rightCoords}, 0, 0);
        });

        eve.on('raphael.drag.element.end.' + circle.id, function () {
            if (!leftLine || !rightLine) return;

            CIRCLES_LIST[circle.id].remove();
            delete CIRCLES_LIST[circle.id];

            let pathCoords = leftLine.attr('path');

            if (self.renderLinks) {
                self.renderLinks.push(leftLine);
                self.renderLinks.push(leftLine.centerCircle);
                self.renderLinks.push(rightLine);
                self.renderLinks.push(rightLine.centerCircle);
            }

            let newIndex = self.getNewMoveCircleIndex(oldMoveCircles);
            self.drawMoveCircle({x: pathCoords[1][1], y: pathCoords[1][2]}, leftLine.id, rightLine.id, newIndex,true);

            SCHEMES[self.schemeId].disableDrag();
            SCHEMES[self.schemeId].enableDrag(true);

            self.savePosition();
        });

        circle.draggable();

        return circle;
    }

    getNewMoveCircleIndex(oldCircles) {
        let circles = this.getMoveCircles();
        let lastCircle = oldCircles[1] || oldCircles[0];

        if (!lastCircle) return circles.length;

        let lastCircleIndex = CIRCLES_LIST[lastCircle].index;

        if (!oldCircles[1] && lastCircleIndex) return lastCircleIndex + 1;

        circles.forEach(circle => {
          if (!CIRCLES_LIST[circle] || !('index' in CIRCLES_LIST[circle]) || CIRCLES_LIST[circle].index < lastCircleIndex) return;

          CIRCLES_LIST[circle].index++;
        });


        return lastCircleIndex;
    }

    drawMoveCircle(point, leftLine, rightLine, index, addToSet = false) {
        let self = this;
        let moveCircle = paper.circle(point.x, point.y, 2).attr({
            'fill': 'black',
            'class': 'move-circle',
            'stroke-width': 4
        });

        moveCircle.toFront();

        moveCircle.leftLine = {id: leftLine};
        moveCircle.rightLine = {id: rightLine};
        moveCircle.index = index;
        CIRCLES_LIST[moveCircle.id] = moveCircle;

        LINES_LIST[leftLine].moveCircles.push(moveCircle.id);
        LINES_LIST[rightLine].moveCircles.push(moveCircle.id);

        eve.on('raphael.drag.element.move.' + moveCircle.id, function (dx, dy) {
            if (LINES_LIST[moveCircle.leftLine.id]) {
                moveCircle.leftLine.coords = LINES_LIST[moveCircle.leftLine.id].attr('path');
                moveCircle.leftLine.coords[1][1] = dx;
                moveCircle.leftLine.coords[1][2] = dy;
                Link.moveLine({id: moveCircle.leftLine.id, position: 'end', coords: moveCircle.leftLine.coords}, 0, 0);
            }

            if (LINES_LIST[moveCircle.rightLine.id]) {
                moveCircle.rightLine.coords = LINES_LIST[moveCircle.rightLine.id].attr('path');
                moveCircle.rightLine.coords[0][1] = dx;
                moveCircle.rightLine.coords[0][2] = dy;
                Link.moveLine({id: moveCircle.rightLine.id, position: 'end', coords: moveCircle.rightLine.coords}, 0, 0);
            }
        });

        eve.on('raphael.drag.element.end.' + moveCircle.id, function () {
            self.savePosition();
        });

        moveCircle.draggable();
        if (addToSet && this.renderLinks) this.renderLinks.push(moveCircle);
    }

    addLineToCableInfo(line, id, firstNewLineId, secondNewLineId) {
        let lineInfo = line.info;
        if (!lineInfo.firstElement || !lineInfo.secondElement) return;

        for (let i = 0; i < lineInfo.firstElement.info.lines.length; i++) {
            if (id === lineInfo.firstElement.info.lines[i].id) {
                let newLineId = lineInfo.firstElement.info.lines[i].position === 'start' ? secondNewLineId : firstNewLineId;
                lineInfo.firstElement.info.lines.push({id: newLineId, position: lineInfo.firstElement.info.lines[i].position});

                return;
            }
        }

        for (let i = 0; i < lineInfo.secondElement.info.lines.length; i++) {
            if (id === lineInfo.secondElement.info.lines[i].id) {
                let newLineId = lineInfo.secondElement.info.lines[i].position === 'start' ? secondNewLineId : firstNewLineId;
                lineInfo.secondElement.info.lines.push({id: newLineId, position: lineInfo.secondElement.info.lines[i].position });

                return;
            }
        }
    }

    fillStartFiberInfo () {
        if (!this.firstElement.info) return;

        if (this.firstElement.info && this.firstElement.info.schemeId && this.schemeId !== this.firstElement.info.schemeId) {
            let fiber = this.firstElement.info.reverseFibers ? this.firstElement.info.reverseFibers[this.fiber_num_1] : undefined;
            this.startFiber = {
                x: fiber.rendered.attr('x'),
                y: fiber.rendered.attr('y') + SCHEME_OPTIONS.FIBER_WIDTH / 2,
                vertical: fiber.vertical,
                color: fiber.color,
                reverse: 1
            };

            return;
        }

        let fiber = this.firstElement.info.fibers ? this.firstElement.info.fibers[this.fiber_num_1] : undefined;
        this.startFiber = {
            x: fiber.edge.x,
            y: fiber.edge.y,
            vertical: fiber.vertical,
            color: fiber.color
        };
    }

    fillEndFiberInfo () {
        if (!this.secondElement.info) return;

        if (this.secondElement.info && this.secondElement.info.schemeId && this.schemeId !== this.secondElement.info.schemeId) {
            let fiber = this.secondElement.info.reverseFibers ? this.secondElement.info.reverseFibers[this.fiber_num_2] : undefined;
            this.endFiber = {
                x: fiber.rendered.attr('x'),
                y: fiber.rendered.attr('y') + SCHEME_OPTIONS.FIBER_WIDTH / 2,
                vertical: fiber.vertical,
                color: fiber.color,
                reverse: 1
            };

            return;
        }

        let fiber = this.secondElement.info.fibers ? this.secondElement.info.fibers[this.fiber_num_2] : undefined;
        this.endFiber = {
            x: fiber.edge.x,
            y: fiber.edge.y,
            vertical: fiber.vertical,
            color: fiber.color
        };

    }

    getMoveCircles() {
        if (!this.renderLinks || !this.renderLinks.items) return [];

        let circles = [];

        this.renderLinks.items.forEach(item => {
            if (item.type !== 'circle' || !item.leftLine) return;

            circles.push(item.id);
        });

        return circles.sort((a, b) => {
            return CIRCLES_LIST[a].index - CIRCLES_LIST[b].index;
        });
    }

    getPoints() {
        let points = [];

        let circles = this.getMoveCircles();
        circles.forEach(item => {
            if (!CIRCLES_LIST[item]) return;
            points.push({
                x: (CIRCLES_LIST[item].attr('cx') - SCHEMES[this.schemeId].schemeStartX) / SCHEMES[this.schemeId].schemeWidth,
                y: (CIRCLES_LIST[item].attr('cy') - SCHEMES[this.schemeId].schemeStartY) / SCHEMES[this.schemeId].schemeHeight
            });
        });

        return points;
    }

    savePosition() {
        let self = this;

        let params = {
            qindex: INDEX,
            json: 1,
            header: 2,
            change_link: 1,
            ID: self.id,
            GEOMETRY: JSON.stringify(self.getPoints()),
            COMMUTATION_ID: self.schemeId
        };

        jQuery.post(SELF_URL, params)
            .fail(function (error) {
                aTooltip.displayError(error);
            });
    }

    static moveCenterCircle (firstPoint, secondPoint, centerCircle) {
        if (!centerCircle) return;

        let newCenterPoint = getCoordsBetween(
            {x: firstPoint.x, y: firstPoint.y},
            {x: secondPoint.x, y: secondPoint.y}
        );
        if (!newCenterPoint) return;

        centerCircle.attr({cx: newCenterPoint.x, cy: newCenterPoint.y});
    }

    static moveLine(line, dx, dy, lineInfo) {
        lineInfo = lineInfo || LINES_LIST[line.id];
        if (!lineInfo || !line.position || !line.coords) return;

        let newPathPosition = [];
        if (line.position === 'start') {
            newPathPosition.push(line.coords[0][0]);
            newPathPosition.push(line.coords[0][1] + dx);
            newPathPosition.push(line.coords[0][2] + dy);

            newPathPosition.push(line.coords[1][0]);
            newPathPosition.push(line.coords[1][1]);
            newPathPosition.push(line.coords[1][2]);
        }
        else if (line.position === 'end') {
            newPathPosition.push(line.coords[0][0]);
            newPathPosition.push(line.coords[0][1]);
            newPathPosition.push(line.coords[0][2]);

            newPathPosition.push(line.coords[1][0]);
            newPathPosition.push(line.coords[1][1] + dx);
            newPathPosition.push(line.coords[1][2] + dy);
        }

        lineInfo.attr('path', newPathPosition);

        Link.moveCenterCircle(
            {x: newPathPosition[1], y: newPathPosition[2]},
            {x: newPathPosition[4], y: newPathPosition[5]},
            lineInfo.centerCircle
        );
    }

    static makePathCommand(pointsArr) {
        let command = 'M ' + pointsArr[0].x + ',' + pointsArr[0].y;

        for (let i = 1; i < pointsArr.length; i++) {
            command += ' L' + pointsArr[i].x + ',' + pointsArr[i].y;
        }

        return command;
    }
}

jQuery.contextMenu({
    selector: "#drawCanvas",
    trigger: 'right',
    itemClickEvent: "click",

    build: function () {

        function loadScheme(id, callback) {
            if (!id) return 0;

            fetch('?header=2&get_index=cablecat_get_commutation&ID=' + id + '&RETURN_JSON=1')
                .then(response => {
                    return response.json();
                })
                .then(result => {
                    if (callback) callback();

                    let scheme = new Scheme(id, result);
                    scheme.enableDrag();
                })
                .catch(error => {
                    console.log(error);

                    if (callback) callback();
                });
        }

        return {
            items: {
                add_scheme: {
                    name    : _translate('ADD SCHEME'),
                    icon    : 'add',
                    callback: function () {
                        new AModal()
                            .setRawMode(true)
                            .setId('COMMUTATION_MODAL')
                            .loadUrl('?header=2&get_index=cablecat_commutations_select&RETURN_JSON=1', () => {
                                jQuery('#ADD_COMMUTATION').on('click', () => {
                                    loadScheme(jQuery('#COMMUTATION_ID').val(), () => {
                                        aModal.hide();
                                        jQuery('#COMMUTATION_MODAL').hide();
                                    });
                                });
                            })
                            .show();
                    }
                }
            }
        }
    }
});

jQuery.contextMenu({
    selector: ".base",
    trigger: 'right',
    itemClickEvent: "click",

    build: function (trigger) {
        let baseElement = paper.getById(trigger[0].raphaelid);

        return {
            items: {
                add_scheme: {
                    name    : _translate('REMOVE SCHEME'),
                    icon    : 'delete',
                    callback: function () {
                        if (!baseElement.schemeId || !SCHEMES[baseElement.schemeId]) return;

                        fetch('?header=2&get_index=cablecat_big_commutation&ID=' + baseElement.schemeId + '&del=1')
                            .then(response => {
                                SCHEMES[baseElement.schemeId].set.remove();
                            })
                            .catch(error => {
                                console.log(error);

                                if (callback) callback();
                            });
                    }
                }
            }
        }
    }
});

function zoomAndPan(paper) {
    let oX = 0, oY = 0,
        viewBox = paper.setViewBox(oX, oY, paperParams.startWidth, paperParams.startHeight),
        mousedown = false,
        dX, dY, startX, startY;

    let boundaryViolation = false;

    viewBox.X = oX;
    viewBox.Y = oY;

    let drawCanvasElement = document.getElementById('drawCanvas');
    drawCanvasElement.addEventListener('wheel', wheel);

    function handle(delta) {
        let vBHo = paperParams.viewBoxHeight;
        let vBWo = paperParams.viewBoxWidth;
        if (delta < 0) {
            paperParams.viewBoxWidth *= 0.8;
            paperParams.viewBoxHeight *= 0.8;
        } else {
            paperParams.viewBoxWidth *= 1.2;
            paperParams.viewBoxHeight *= 1.2;
        }

        viewBox.X -= (paperParams.viewBoxWidth - vBWo) / 2;
        viewBox.Y -= (paperParams.viewBoxHeight - vBHo) / 2;

        paperParams.coordsViewBox.x = viewBox.X;
        paperParams.coordsViewBox.y = viewBox.Y;
        paper.setViewBox(viewBox.X, viewBox.Y, paperParams.viewBoxWidth, paperParams.viewBoxHeight);
    }

    function wheel(event){
        let delta = 0;
        if(!event) event = window.event;

        if(event.wheelDelta){
            delta = event.wheelDelta/120;
        } else if (event.detail) {
            delta = -event.detail/3;
        }

        if(delta) handle(delta);
        if(event.preventDefault){
            event.preventDefault();
        }
        event.returnValue = false;
    }

    jQuery('#drawCanvas').mousedown(function(e){
        if (e.button == 2 || boundaryViolation) return;

        if (paper.getElementByPoint( e.pageX, e.pageY ) !== null) return;

        mousedown = true;
        startX = e.pageX;
        startY = e.pageY;
    });
    jQuery('#drawCanvas').mousemove(function(e){
        if (mousedown === false) return;

        if (boundaryViolation) return;

        boundaryViolation = true;

        new Promise(function (resolve, reject) {
            dX = (startX - e.pageX) * paperParams.viewBoxWidth / paper.width;
            dY = (startY - e.pageY) * paperParams.viewBoxHeight / paper.height;
            paper.setViewBox(viewBox.X + dX, viewBox.Y + dY, paperParams.viewBoxWidth, paperParams.viewBoxHeight);
            setTimeout(() => resolve(), 20);
        }).then(() => boundaryViolation = false);
    });
    jQuery('#drawCanvas').mouseup(function (e) {
        if (mousedown === false) return;
        viewBox.X += dX;
        viewBox.Y += dY;
        mousedown = false;

        paperParams.coordsViewBox.x = viewBox.X;
        paperParams.coordsViewBox.y = viewBox.Y;
    });
}

function getCoordsBetween(p1, p2) {
    return {
        x: (p1.x + p2.x) / 2,
        y: (p1.y + p2.y) / 2
    }
}

function getCloserPoint(p1, p2, value) {
    let del1 = Math.abs(value / 2 - p1);
    let del2 = Math.abs(value / 2 - p2);
    return (Math.max(del1, del2) === del1) ? p2 : p1;
}

function _translate(text, insertion) {
    let translated = document['LANG'][text.toUpperCase()];

    if (typeof translated === 'undefined') {
        console.log('[ Commutation:_translate ] No translation for: ' + text);
        return text;
    }

    if (typeof insertion !== 'undefined') {
        let insert_translated = function (prev, to_translate) {
            let translated_insertion = _translate(to_translate);
            return prev.replace('%s', translated_insertion);
        };

        if (Array.isArray(insertion)) {
            for (let i = 0; i < insertion.length; i++) {
                translated = insert_translated(translated, insertion[i])
            }
        }
        else {
            translated = insert_translated(translated, insertion);
        }

    }

    translated = translated.replace(/&#39;/gm, '\'');

    return translated;
}