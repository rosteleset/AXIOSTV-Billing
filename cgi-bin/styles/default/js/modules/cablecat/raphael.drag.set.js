Raphael.fn.draggableSet = function (group, handles, isBound, moveToTop, topElementsType) {
    if (!handles) handles = group;

    var boundaryViolation = false;

    var groupSet = this.set(group),
        handleSet = this.set(handles),
        oX = [],
        oY = [];

    if (group.id) groupSet.id = group.id;

    handleSet.drag(dragMove, dragStart, dragEnd);

    function dragStart(x, y, dE) {
        groupSet.forEach(function (e) {
            getElementCoords(e);

            if (moveToTop) e.toFront();
        });

        if (groupSet.dependentElements) {
            groupSet.dependentElements.forEach(e => getElementCoords(e.element));
        }

        eve('raphael.drag.start.' + groupSet.id, this, x, y);
    }

    function dragMove(dX, dY, x, y, dE) {
        if (paperParams.viewBoxWidth && paperParams.startWidth) {
            dX *= paperParams.viewBoxWidth / paperParams.startWidth;
            dY *= paperParams.viewBoxHeight / paperParams.startHeight;
        }
        if (boundaryViolation) return;

        boundaryViolation = true;

        new Promise(function(resolve, reject) {
            groupSet.forEach(function (e) {
                if (e.type === 'path') {
                    if (!oX[e.id]) return;


                    let newPathPosition = [];

                    if (!e.reverse) {
                        oX[e.id].forEach(value => {
                            newPathPosition.push(value[0]);
                            newPathPosition.push(value[1] + dX);
                            newPathPosition.push(value[2] + dY);
                        });
                    }
                    else {
                        newPathPosition.push(oX[e.id][0][0]);
                        newPathPosition.push(oX[e.id][0][1]);
                        newPathPosition.push(oX[e.id][0][2]);

                        newPathPosition.push(oX[e.id][1][0]);
                        newPathPosition.push(oX[e.id][1][1]);
                        newPathPosition.push(oX[e.id][1][2]);

                        if (e.info.startFiber.reverse) {
                            newPathPosition[4] += dX;
                            newPathPosition[5] += dY;
                        }
                        else if (e.info.endFiber.reverse) {
                            newPathPosition[1] += dX;
                            newPathPosition[2] += dY;
                        }
                    }

                    e.attr('path', newPathPosition);

                    return;
                }

                let nX = oX[e.id] + dX, nY = oY[e.id] + dY;

                e.attr(e.type === 'circle' || e.type === 'ellipse' ? {cx: nX, cy: nY} : {x: nX, y: nY});

                if (topElementsType && topElementsType.includes(e.type)) {
                    e.toFront();
                }
            });

            eve('raphael.drag.move.' + groupSet.id, this, dX, dY);
            setTimeout(() => resolve(), 20);
        }).then(() => boundaryViolation = false);
    }

    function dragEnd(dE) {
        eve('raphael.drag.end.' + groupSet.id, this, dE);
    }

    return groupSet;

    function getElementCoords(element) {
        oX[element.id] = element.type === 'circle' || element.type === 'ellipse' ?
            element.attr('cx') : element.attr('x');
        oY[element.id] = element.type === 'circle' || element.type === 'ellipse' ?
            element.attr('cy') : element.attr('y');

        if (element.type === 'path') oX[element.id] = element.attr('path');
    }
};



Raphael.el.draggable = function (options) {
    jQuery.extend(true, this, {}, options || {});

    let canMove = true;

    function dragStart(x, y) {
        this.oldX = this.type === 'circle' || this.type === 'ellipse' ? this.attr('cx') : this.attr('x');
        this.oldY = this.type === 'circle' || this.type === 'ellipse' ? this.attr('cy') : this.attr('y');

        eve('raphael.drag.element.start.' + this.id, this, this.oldX, this.oldY);
    }

    function dragMove( dx, dy ) {

        if (!canMove) return;

        canMove = false;
        let self = this;

        new Promise(function(resolve){
            if (paperParams.viewBoxWidth && paperParams.startWidth) {
                dx *= paperParams.viewBoxWidth / paperParams.startWidth;
                dy *= paperParams.viewBoxHeight / paperParams.startHeight;
            }

            self.attr(self.type === 'circle' || self.type === 'ellipse' ?
                {cx: self.oldX + dx, cy: self.oldY + dy} :
                {x: self.oldX + dx, y: self.oldY + dy});

            eve('raphael.drag.element.move.' + self.id, self, self.oldX + dx, self.oldY + dy);

            setTimeout(() => resolve(), 20);
        }).then(() => canMove = true);
    }

    this.drag(dragMove, dragStart, () => {
        eve('raphael.drag.element.end.' + this.id);
    });

    return this;
};