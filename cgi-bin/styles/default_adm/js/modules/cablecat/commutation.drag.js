Raphael.fn.draggableSet = function (group, handles, isBound, attr = {}, outTheBorderCallback, endMoveCallback) {
  if (!handles) handles = group;

  var boundaryViolation = false;

  var groupSet = group && group.type === "set" ? group : this.set(group),
    handleSet = handles && handles.type === "set" ? handles : this.set(handles),
    oX = [],
    oY = [];

  if (group.id) groupSet.id = group.id;

  handleSet.drag(dragMove, dragStart, dragEnd);

  function dragStart(x, y, dE) {
    groupSet.forEach(function (e) {
      getElementCoords(e);
    });

    if (groupSet.dependentElements) {
      groupSet.dependentElements.forEach(e => getElementCoords(e.element));
    }

    eve('raphael.drag.start.' + groupSet.id, this, x, y);
  }

  function dragMove(dX, dY) {

    if (isBound && isBound.attr('x') < 0) {
      if (outTheBorderCallback) outTheBorderCallback({
        'position': 'left',
        'vertical': true,
        'start_x' : undefined,
        'start_y' : 0
      });
      return;
    } else if (isBound && isBound.attr('y') < 0) {
      if (outTheBorderCallback) outTheBorderCallback({
        'position': 'top',
        'vertical': false,
        'start_x' : isBound.attr('x') !== 0 ? paper.width - isBound.attr('height') : 0,
        'start_y' : undefined
      });
      return;
    }
    else if (isBound && paper && isBound.attr('x') > paper.width - isBound.attr('width')) {
      if (outTheBorderCallback) outTheBorderCallback({
        'position': 'right',
        'vertical': true,
        'start_x' : paper.width - isBound.attr('width'),
        'start_y' : 0
      });
      return;
    }
    if (isBound && paper && isBound.attr('y') > paper.height - isBound.attr('height')) {
      if (outTheBorderCallback) outTheBorderCallback({
        'position': isBound.attr('x') !== 0 ? 'right' : 'left',
        'vertical': true,
        'start_x' : isBound.attr('x'),
        'start_y' : paper.height - isBound.attr('height') - 1
      });
      return;
    }

    if (paperParams.viewBoxWidth && paperParams.startWidth) {
      dX *= paperParams.viewBoxWidth / paperParams.startWidth;
      dY *= paperParams.viewBoxHeight / paperParams.startHeight;
    }
    if (boundaryViolation) return;

    boundaryViolation = true;

    new Promise(function(resolve, reject) {
      groupSet.forEach(function (e) {

        let nX = attr['move_by_y'] ? oX[e.id] : oX[e.id] + dX, nY = attr['move_by_x'] ? oY[e.id] : oY[e.id] + dY;

        if (e.transform()[0] && e.transform()[0][1] === 90) {
          nX = attr['move_by_x'] ? oX[e.id] : oX[e.id] + dY; nY = attr['move_by_y'] ? oY[e.id] : oY[e.id] + dX;
        }
        else if (e.transform()[0] && e.transform()[0][1] === 270) {
          nX = attr['move_by_x'] ? oX[e.id] : oX[e.id] - dY; nY = attr['move_by_y'] ? oY[e.id] : oY[e.id] - dX;
        }

        e.attr(e.type === 'circle' || e.type === 'ellipse' ? {cx: nX, cy: nY} : {x: nX, y: nY});
      });

      eve('raphael.drag.move.' + groupSet.id, this, dX, dY);

      setTimeout(() => resolve(), 0);
    }).then(() => boundaryViolation = false);
  }

  function dragEnd(dE) {
    if (endMoveCallback) endMoveCallback();
    eve('raphael.drag.end.' + groupSet.id, this, dE);
  }

  return groupSet;

  function getElementCoords(element) {
    oX[element.id] = element.type === 'circle' || element.type === 'ellipse' ?
      element.attr('cx') : element.attr('x');
    oY[element.id] = element.type === 'circle' || element.type === 'ellipse' ?
      element.attr('cy') : element.attr('y');
  }
};
