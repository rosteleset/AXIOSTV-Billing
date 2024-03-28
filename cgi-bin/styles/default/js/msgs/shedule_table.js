/**
 * Created by Anykey on 27.10.2015.
 *
 *  Draggabble and droppable tasks + table
 *
 */

class SheduleTable {
  hours = 10;
  startTime = 9;
  container = '#hour-grid';
  administrators = {}
  width = window.innerWidth;
  minute = 0;
  tasks = [];

  constructor(hours = 15, startTime = 9) {
    this.hours = hours;
    this.startTime = startTime;
    this.hoursArray = Array(this.hours).fill(0).map((_, i) => i + this.startTime);
    this.minute = this.width / this.hours / 60;
  }

  generate() {
    this.generateSidebar();
    this.generateMainBlock();
    this.generateAdminRows();

    jQuery(this.container).append(this.sidebar);
    jQuery(this.container).append(this.mainBlock);

    this.makeDraggable();
  }

  setAdmins(admins) {
    this.administrators = admins;
  }

  addTask(task) {
    let self = this;
    let newTask = new Task(task.id, task.subject || task.message, self.administrators[task.resposible], task.plan_interval);
    newTask.setPlanTime(task.plan_time);
    newTask.setPriority(task.priority_id);
    newTask.setMinuteSize(this.minute);
    newTask.setHours(this.startTime);

    newTask.render();

    this.generateEditBtn(newTask);

    if (newTask.admin) {
      let timeContainer = document.querySelectorAll(`[data-admin='${newTask.admin.aid}']`)[0];
      if (timeContainer === undefined || newTask.planTime === undefined) return;
      let taskContainer = document.getElementById(`task-${newTask.id}`);
      let newTaskContainer = document.getElementById(`new-task-container-${newTask.id}`);

      let a = newTask.planTime.split(':');
      let minutes = (+a[0]) * 60 + (+a[1]);

      let x = (minutes - newTask.hours * 60) * newTask.minuteSize;
      if (x > 0 && x < this.width) {
        newTaskContainer.classList.add('d-none');
        taskContainer.classList.add('is-drag');
        taskContainer.classList.add('dropped');
        taskContainer.classList.add(`priority-${newTask.priority}`);
        taskContainer.style.position = 'absolute';
        taskContainer.style.width = newTask.containerWidth;
        taskContainer.style.left = x + 'px';
        newTask.startX = x;
        timeContainer.append(taskContainer);
      }
    }

    newTask.makeDraggable(function() {
      self.makeDraggable(true);
    }, function () { self.makeDraggable() });
  }

  generateSidebar() {
    this.sidebar = $('<div class="time-sidebar"></div>')
    this.sidebar.append($('<div class="time-row hours"></div>'));
  }

  generateMainBlock() {
    let $container = $('<div class="time-container" id="draggable-container"></div>')
    $container.append(this.getHoursRow());
    this.mainBlock = $container;
  }

  generateAdminRows() {
    let self = this;

    Object.entries(this.administrators).forEach(([aid, admin]) => {
      this.sidebar.append($(`<div class='time-row admin-row'>${admin.name}</div>`))

      let mainRowContainer = $('<div class="time-row-container"></div>');
      let row = $(`<div class="time-row draggable-row" data-admin="${aid}" style="width: ${self.width}px !important;"></div>`);
      this.hoursArray.forEach(hour => row.append($('<div class="time-column"></div>')))
      mainRowContainer.append(row);
      this.mainBlock.append(mainRowContainer);
    });

    this.mainBlock.append(this.getHoursRow());
    this.sidebar.append($(`<div class='time-row hours'></div>`));
  }

  getHoursRow() {
    let self = this;
    let rowContainer = $('<div class="time-row-container hours"></div>');
    let row = $(`<div class="time-row draggable-row" style="width: ${self.width}px !important;"></div>`)
    this.hoursArray.forEach(hour => row.append($(`<div class='time-column'>${('0' + hour).slice(-2)}:00</div>`)))
    rowContainer.append(row);

    return rowContainer;
  }

  makeDraggable(disable = false) {
    let dragElement = document.getElementById('draggable-container');
    let draggableRows = document.getElementsByClassName('draggable-row');
    let self = this;

    self.oldX = 0;
    dragElement.onmousedown = function (e) {

      if (disable) {
        document.removeEventListener('mousemove', onMouseMove);
        dragElement.onmouseup = null;
        return;
      }

      let currentX = self.oldX;
      let pxToMove = dragElement.offsetWidth - draggableRows[0].offsetWidth;

      function onMouseMove(event) {
        let newX = self.oldX + event.pageX - e.pageX;
        if (newX > 0) {
          Array.from(draggableRows).forEach((row) => row.style.transform = `translateX(0px)`);
          return;
        }
        if (newX < pxToMove) {
          Array.from(draggableRows).forEach((row) => row.style.transform = `translateX(${pxToMove}px)`);
          return;
        }

        Array.from(draggableRows).forEach((row) => row.style.transform = `translateX(${newX}px)`);
        currentX = newX;
      }

      document.addEventListener('mousemove', onMouseMove);

      dragElement.onmouseup = function() {
        document.removeEventListener('mousemove', onMouseMove);
        self.oldX = currentX;
        dragElement.onmouseup = null;
      };

      dragElement.onmouseleave = function () {
        document.removeEventListener('mousemove', onMouseMove);
        self.oldX = currentX;
        dragElement.onmouseup = null;
      };
    }

    dragElement.ondragstart = function() {
      return false;
    };
  }

  generateEditBtn(task) {
    let id = `edit-${task.id}`;
    let editBtn = $(`<div class="bd-highlight"><button class="p-0 btn text-white task-btn" id="${id}">
    <span class="fa fa-pencil-alt pt-1 pb-1 pl-1 pr-0"></span></button></div>`)

    jQuery(`#title-${task.id}`).prepend(editBtn);

    jQuery(`#${id}`).hover(() => { task.canMove = false; }, () => { task.canMove = true; });
    jQuery(`#${id}`).on('click', function () {
      let btn = jQuery(this);
      btn.prop('disabled', true);
      jQuery.post('/admin/index.cgi', {
        get_index: 'shedule_hour_work',
        header: 2,
        CHANGE_TEMPLATE: 1,
        id: task.id
      }, function (data) {
        task.canMove = true;
        btn.prop('disabled', false);
        var add_contact_form = new AModal();
        add_contact_form
          .setId('add1_contact_modal')
          .isForm(true)
          .setBody(data)
          .show(function () {
            jQuery('#SAVE_DURATION_POSITION').on('click', function (e) {
              e.preventDefault();
              task.setDuration(jQuery('#HOURS').val(), jQuery('#MINUTES').val())

              jQuery("#add1_contact_modal").modal("hide");
              jQuery.post('/admin/index.cgi', {
                get_index: 'shedule_hour_work',
                header: 2,
                minutes: task.duration,
                id: task.id
              });
            });
          });
        initSelect2();
      });
    });
  }
}

class SheduleMonthTable {
  addTask(task) {
    let newTask = new Task(task.id, task.subject,
      task.resposible_admin_login ? { name: task.resposible_admin_login } : undefined, task.plan_interval);
    newTask.setPlanDate(task.plan_date);
    newTask.render();

    let taskContainer = document.getElementById(`task-${newTask.id}`);
    if (newTask.planDate) {
      let newTaskContainer = document.getElementById(`new-task-container-${newTask.id}`);
      let dayContainer = document.querySelectorAll(`[data-plan-date='${newTask.planDate}']`)[0];
      if (dayContainer === undefined) return;

      newTaskContainer.classList.add('d-none');

      taskContainer.classList.add('is-drag');
      taskContainer.classList.add('dropped');
      taskContainer.classList.add(`priority-${newTask.priority}`);
      dayContainer.append(taskContainer);
    }

    this.makeDraggable(newTask, taskContainer);
  }

  makeDraggable(self, task) {
    task.onselectstart = function() { return false; };
    let taskContainer = document.getElementById(`new-task-container-${self.id}`);

    task.onmousedown = function(event) {
      if (self.canMove === false) return;
      if (event.which === 2 || event.which === 3) return;

      self.oldDroppableBelow = task.parentElement.classList.contains('draggable-row') ? task.parentElement : null;
      self.droppableBelow = null;

      let clone = task.cloneNode(true);
      clone.id = 'ticket-clone';
      if (task.classList.contains('is-drag')) { clone.style.display = 'none'; }
      taskContainer.appendChild(clone);
      taskContainer.classList.add('d-none');

      task.style.position = 'absolute';
      task.style.zIndex = 1000;
      task.style.width = self.containerWidth;

      task.classList.add(`priority-${self.priority}`);
      task.classList.add('is-drag');
      task.classList.remove(`dropped`);
      document.body.append(task);

      self.shiftY = task.getBoundingClientRect().height / 2;
      self.moveAt(event.pageX, event.pageY);

      function onMouseMove(event) {
        self.moveAt(event.pageX, event.pageY);

        task.hidden = true;
        let elemBelow = document.elementFromPoint(event.pageX,  event.pageY - document.documentElement.scrollTop);
        task.hidden = false;
        self.droppableBelow = elemBelow.closest('.dayCell');
      }

      document.addEventListener('mousemove', onMouseMove);

      task.onmouseup = function(e) {
        if (self.droppableBelow === null) {
          task.removeAttribute("style")
          document.getElementById('ticket-clone').remove();
          taskContainer.appendChild(task);
          taskContainer.classList.remove('d-none');
          task.classList.remove('is-drag');
          self.savePlanDate('0000-00-00');
        }
        else {
          let tasksDateContainer = self.droppableBelow.querySelectorAll('.month-tasks-container')[0];
          tasksDateContainer.append(task);
          task.classList.add('dropped');
          task.removeAttribute("style")
          document.getElementById('ticket-clone').remove();
          self.savePlanDate(tasksDateContainer.dataset.planDate || '0000-00-00');
        }

        document.removeEventListener('mousemove', onMouseMove);
        task.onmouseup = null;
      };

    };

    task.ondragstart = function() {
      return false;
    };
  }
}

class Task {
  container = '#new-tasks';
  constructor(id, message, admin, duration = 120) {
    this.id = id;
    this.message = message;
    this.admin = admin || undefined;
    this.duration = duration || 120;
    this.canMove = true;
  }

  setPlanTime(planTime) {
    let re = /\d{2}:\d{2}/;
    let foundTime = planTime.match(re);

    this.planTime = foundTime[0] || undefined;
  }

  setPlanDate(planDate) {
    this.planDate = planDate === '0000-00-00' ? undefined : planDate;
  }

  setMinuteSize(minuteSize) {
    this.minuteSize = minuteSize;
    this.width = this.duration * minuteSize;
    this.containerWidth = this.width + 'px';
  }

  setDuration(hours, minutes) {
    if (hours > SheduleTable.hours) hours = SheduleTable.hours;
    if (minutes > 59 || !minutes) minutes = 0;
    minutes = parseInt(minutes) + hours * 60;
    minutes = minutes < 20 ? 20 : minutes > 0 ? minutes : 120;

    this.duration = minutes;
    this.width = this.duration * this.minuteSize;
    this.containerWidth = this.width + 'px';
    this.task.style.width = this.containerWidth;
  }

  setHours(hours) {
    this.hours = hours;
  }

  setPriority(priority) {
    this.priority = priority;
  }

  getTime(minutes) {
    let realMinutes = minutes % 60;
    let hours = Math.floor(minutes / 60) + this.hours;
    let expiredHours = hours + Math.floor(this.duration / 60);
    let expiredMinutes = realMinutes + this.duration % 60;
    if (expiredMinutes % 60 > 0) {
      expiredHours += Math.floor(expiredMinutes / 60);
      expiredMinutes = expiredMinutes % 60;
    }

    this.startTime = `${('0' + hours).slice(-2)}:${('0' + realMinutes).slice(-2)}`;

    return `${this.startTime}-${('0' + expiredHours).slice(-2)}:${('0' + expiredMinutes).slice(-2)}`
  }

  render() {
    let taskDiv = $(`<div class="p-2 bd-highlight" id='new-task-container-${this.id}'></div>`)

    this.task = document.createElement('div');
    this.task.classList.add('task');
    this.task.id = `task-${this.id}`;

    let $task = jQuery(this.task);

    let title = $(`<div class="d-flex bd-highlight" id='title-${this.id}'>
      <div class="bd-highlight flex-grow-1 pt-1 w-50"><div title='${this.message}' class='task-title'>${this.message}</div></div></div>`);

    let info = $(`<div class='task-info'></div>`)
    let textColor = this.admin ? 'text-success' : 'text-danger';
    let adminName = this.admin ? this.admin.name : NO_RESPONSIBLE;
    let admin = $(`<div class='task-admin mr-2 ${textColor}'>${adminName}</div>`)
    admin.prepend($(`<i class='fa fa-user mr-1 ${textColor}'></i>`));
    info.append(admin);

    let duration = $(`<div class='task-duration'>${this.duration} мин</div>`);
    duration.prepend($(`<i class='far fa-clock mr-1'></i>`))
    info.append(duration);

    $task.append(title);
    $task.append(info);
    taskDiv.append($task);

    jQuery(this.container).append(taskDiv);
    this.generateViewBtn();
  }

  moveAt(x, y) {
    this.task.style.left = x  + 'px';
    this.task.style.top = y - this.shiftY + 'px';
  }

  savePosition() {
    let self = this;
    jQuery.post('/admin/index.cgi', {
      get_index: 'shedule_hour_work',
      header: 2,
      json: 1,
      aid: self.admin !== undefined ? self.admin.aid : '',
      plan_time: self.startTime,
      id: self.id
    });
  }

  savePlanDate(planDate) {
    let self = this;
    jQuery.post('/admin/index.cgi', {
      get_index: 'msgs_task_board',
      header: 2,
      json: 1,
      plan_date: planDate,
      id: self.id,
      change: 1
    });
  }

  makeDraggable(enableCallback, disableCallback) {
    let self = this;
    let task = this.task;
    let taskContainer = document.getElementById(`new-task-container-${self.id}`);

    task.onselectstart = function() { return false; };

    task.onmousedown = function(event) {
      if (self.canMove === false) return;
      if (event.which === 2 || event.which === 3) return;

      if (enableCallback) enableCallback();
      self.oldDroppableBelow = task.parentElement.classList.contains('draggable-row') ? task.parentElement : null;
      self.droppableBelow = null;

      let clone = task.cloneNode(true);
      clone.id = 'ticket-clone';
      if (task.classList.contains('is-drag')) { clone.style.display = 'none'; }
      taskContainer.appendChild(clone);
      taskContainer.classList.add('d-none');

      task.style.position = 'absolute';
      task.style.zIndex = 1000;
      task.style.width = self.containerWidth;

      task.classList.add(`priority-${self.priority}`);
      task.classList.add('is-drag');
      task.classList.remove(`dropped`);
      document.body.append(task);

      self.shiftY = task.getBoundingClientRect().height / 2;
      self.moveAt(event.pageX, event.pageY);

      function onMouseMove(event) {
        self.mouseMove(event.pageX, event.pageY);
      }

      document.addEventListener('mousemove', onMouseMove);

      task.onmouseup = function(e) {
        if (self.droppableBelow === null) {
          self.makeUndropped();
          self.savePosition();
          taskContainer.classList.remove('d-none');
        }
        else if (self.checkTasksBelow(e.pageX, e.pageY)) {
          self.makeDropped(e.pageX)
          self.savePosition();
        }
        else {
          taskContainer.classList.remove('d-none');
        }

        if (disableCallback) disableCallback();
        task.classList.remove('time-after');
        document.removeEventListener('mousemove', onMouseMove);
        task.onmouseup = null;
      };

    };

    task.ondragstart = function() {
      return false;
    };
  }

  mouseMove(x, y) {
    this.task.hidden = true;
    let elemBelow = document.elementFromPoint(x, y - document.documentElement.scrollTop);
    this.task.hidden = false;
    this.droppableBelow = elemBelow.closest('.draggable-row');

    if (this.droppableBelow !== null && !this.droppableBelow.dataset.admin) this.droppableBelow = null;

    if (this.droppableBelow === null) {
      this.task.classList.remove('time-after');
      this.moveAt(x, y);
    }
    else {
      let droppableCoords = this.droppableBelow.getBoundingClientRect();
      let center = droppableCoords.top + document.documentElement.scrollTop + droppableCoords.height / 2;

      let time = this.getTime(parseInt((x - droppableCoords.x) /this.minuteSize));
      this.task.setAttribute('data-after', time);
      this.task.classList.add('time-after');

      if (y < center + 20 && y > center - 20) {
        this.moveAt(x, center);
      }
      else {
        this.moveAt(x, y);
      }
    }
  }

  checkTasksBelow(x, y) {
    this.task.hidden = true;
    let elemBelow = document.elementFromPoint(x, y - document.documentElement.scrollTop);
    this.task.hidden = false;

    let startTaskElementBelow = elemBelow.closest('.dropped');

    elemBelow = document.elementFromPoint(x + this.width, y - document.documentElement.scrollTop);
    let endTaskElementBelow = elemBelow.closest('.dropped');

    if (startTaskElementBelow === null && endTaskElementBelow === null) return true;

    if (this.startX && this.oldDroppableBelow) {
      this.task.removeAttribute("style");
      this.task.style.position = 'absolute';
      this.task.style.width = this.containerWidth;
      this.task.classList.add(`priority-${this.priority}`);
      this.task.classList.add(`dropped`);
      this.task.style.left = this.startX + 'px';
      this.oldDroppableBelow.appendChild(this.task);
      this.admin = { aid: this.oldDroppableBelow.dataset.admin }
      document.getElementById('ticket-clone').remove();
    }
    else {
      this.makeUndropped();
    }
    return false;
  }

  makeDropped (x) {
    this.task.removeAttribute("style");
    this.task.style.position = 'absolute';
    this.task.style.width = this.containerWidth;
    this.task.classList.add(`priority-${this.priority}`);
    this.task.classList.add(`dropped`);
    this.startX = x - this.droppableBelow.getBoundingClientRect().x;
    this.task.style.left = this.startX + 'px';
    this.droppableBelow.appendChild(this.task);
    this.admin = { aid: this.droppableBelow.dataset.admin }

    document.getElementById('ticket-clone').remove();
  }

  makeUndropped () {
    this.task.removeAttribute("style")
    document.getElementById('ticket-clone').remove();
    document.getElementById(`new-task-container-${this.id}`).appendChild(this.task);
    this.task.classList.remove('is-drag');
    this.admin = undefined;
  }

  generateViewBtn() {
    let id = `view-${this.id}`;
    let viewBtn = $(`<div class='bd-highlight'>
    <a href='?get_index=msgs_admin&full=1&chg=${this.id}' target='_blank' class='p-0 btn text-white task-btn' id='${id}'>
    <span class='fa fa-eye p-1'></span></a></div>`)

    jQuery(`#title-${this.id}`).prepend(viewBtn);
    jQuery(`#${id}`).hover(() => { this.canMove = false; }, () => { this.canMove = true; });
  }
}


