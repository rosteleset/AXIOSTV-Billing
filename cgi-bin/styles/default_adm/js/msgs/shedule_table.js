/**
 * Created by Anykey on 27.10.2015.
 *
 *  Draggabble and droppable tasks + table
 *
 */

//Default options
let tableOptions = {
  container: '#hour-grid',
  administrators: [
    {"name": 'Mickey', id: 0},
    {"name": 'Donald', id: 1},
    {"name": 'Arnold', id: 2},
    {"name": 'Donatello', id: 3},
    {"name": 'Rembo', id: 4},
    {"name": 'Splinter', id: 5}
  ],

  hours: 10,
  startTime: 9,
  fraction: 60,
  timeUnit: 0,

  dinnerTime: 13,
  dinnerLength: 60,

  highlighted: 0
}

let isDayTable = false
let isMonthTable = false

$(function () {
  isDayTable = $('div#hour-grid').length > 0
  isMonthTable = $('table.work-table-month').length > 0

  console.assert(isDayTable !== isMonthTable, "Something goes wrong")
})


let AWorkTable = (function () {
  let $Table
  let $base

  let opts = {}
  let jobs = []
  let tasks = []

  let DEFAULTS = tableOptions

  //bind events
  $(function () {

    $('#tasksForm').on('submit', function () {

      $('#jobsNew').val(JSON.stringify(jobs))
      $('#jobsPopped').val(JSON.stringify(ATasks.getTasks()))

    })

    $('#cancelBtn').on('click', function () {
      location.reload(false)
    })
  })


  function generate(options) {
    if (options) {
      for (let key in DEFAULTS) {
        opts[key] = options[key] || DEFAULTS[key]
      }
    } else {
      opts = DEFAULTS
    }

    $Table = $('' + opts.container)

    let $table = $('<table></table>')

    $table.append(getTimeRow(opts.startTime, opts.hours, opts.fraction, opts.timeUnit))

    for (let i = 0; i < opts.administrators.length; i++) {

      let $tr = $('<tr></tr>')
      let $adminTd = $('<td></td>').text(opts.administrators[i].name)
      $adminTd.addClass('adminCaption')
      $tr.append($adminTd)

      //saving row reference
      opts.administrators[i].rowNum = i
      opts.administrators[i].row = $tr

      if (opts.timeUnit == 0) {
        for (let j = 0; j < (opts.hours * 110) / opts.fraction; j++) {
          let $td = $('<td></td>')
          $td.attr('class', 'task taskFree')
          $td.attr('row', i)
          $td.attr('col', j)

          $tr.append($td)
        }
      } else if (opts.timeUnit == 1) {
        if ($.isArray(opts.hours)) {
          for (let j = 0; j < opts.hours.length; j++) {
            let $td = $('<td></td>')
            $td.attr('class', 'task taskFree')
            $td.attr('row', i)
            $td.attr('col', j)
            $tr.append($td)
          }
        } else {
          for (let j = 0; j < opts.hours; j++) {
            let $td = $('<td></td>')
            $td.attr('class', 'task taskFree')
            $td.attr('row', i)
            $td.attr('col', j)
            $tr.append($td)
          }
        }
      }

      $table.append($tr)
    }
    $table.addClass('table table-striped table-condensed')

    $base = $('<div></div>')
    $base.addClass('table-responsive')

    $base.append($table)

    return $base
  }

  function render() {
    if ($base) {
      $Table.empty()
      $Table.append($base)
    }

    if (jobs.length > 0) {
      $.each(jobs, function (i, task) {
        renderJob(task)
      })
    }

    calculateFreeSets()
  }

  function renderJob(job) {
    let admin = getAdministratorById(job.administrator)
    let $row = $(admin.row)

    $.each(job.tasks, function (i, task) {
      if (typeof task != 'undefined')
        fillTask(task.id, task.name, task.start, task.length, true, task.interval)

      function fillTask(id, name, start, length, first, interval) {
        let cell = $row.find('td') [+start + 1]
        let $cell = $(cell)

        if (opts.highlighted != 0 && id == opts.highlighted) $cell.addClass('taskActive')

        $cell.attr('title', name)
        $cell.attr('taskId', id)

        if (tasksInfo[id]) {
          renderTooltip($cell, tasksInfo[id], 'down')
        }

        if (first) {
          let styleWidth = ``
          if (interval !== 0) {
            styleWidth = `style="width: ${interval}%"`
          }
          else {
            styleWidth = `style="width: 100%"`
          }

          let removeLink = `<div class='resizer bottom-right' id='${task.id}' ${styleWidth}>
          <span class='btn-color' taskId='${task.id}'>
          <a onclick="AWorkTable.unlinkTask(this)">
            <span class="fa fa-remove"></span>
            </a>&nbsp&nbsp`
          let detailLink = `<a href="?header=3&full=1&get_index=msgs_admin&chg=${task.id}" target="_blank">
            <span class="fa fa-list-alt"></span>
            </a>&nbsp;&nbsp;</div></span>`

          $cell.html(removeLink + detailLink)
        }

        let newLength = length - 1
        if (newLength > 0) {
          fillTask(id, name, start + 1, newLength, false, interval)
        }
      }
    })
  }


  function calculateFreeSets() {
    $.each(opts.administrators, function (i, admin) {
      let $row = admin.row
      let $cells = $row.find('td')
      processCells($cells)
    })

    function processCells($cells) {
      let counter = 0

      for (let i = $cells.length; i >= 0; i--) {
        let $cell = $($cells[i])
        $cell.attr('lengthfree', counter++)
      }
    }
  }

  function renew() {
    generate(opts)
    render()
  }

  function getTimeRow(startTime, hours, fraction, timeUnit) {
    let formatTime = function(minutes){
      let mins = minutes % 60
      let hours = (minutes - mins) / 60

      return  ((hours < 10) ? '0' + hours : hours)
      +  ':' + ((mins < 10) ? '0' + mins : mins)
    }

    if (timeUnit === 0) {
      let quant = fraction - 30
      let start = startTime * 60
      let end = start + (hours * 55)

      let $tr = $('<tr></tr>')
      $tr.addClass('timeRow')
      $tr.append($('<td></td>'))

      for (let j = start; j < end; j += quant) {
        let $td = $('<td></td>')
        $td.text(formatTime(j))
        $td.addClass('timeTd')
        $td.css('transform', 'translateX(25px)')
        $tr.append($td)
      }

      return $tr
    } else if (timeUnit == 1) {
      if ($.isArray(hours)) {
        let quant = 1
        let $tr = $('<tr></tr>')
        $tr.addClass('timeRow')
        $tr.append($('<td></td>'))

        for (let j = 0; j < hours.length; j += quant) {
          let $td = $('<td></td>')
          let text = hours[j]

          $td.text(text)
          $td.addClass('timeTd')
          $tr.append($td)
        }

        return $tr
      } else {
        let quant = 1
        let start = startTime
        let end = start + hours

        let $tr = $('<tr></tr>')
        $tr.addClass('timeRow')
        $tr.append($('<td></td>'))

        for (let j = start; j < end; j += quant) {
          let $td = $('<td></td>')
          let text = moment({}).day(j).format('DD')

          $td.text(text)
          $td.addClass('timeTd')
          $tr.append($td)
        }

        return $tr
      }
    }
  }

  function getAdministratorById(id) {
    let admins = opts.administrators
    for (let i = 0; i < admins.length; i++) {
      if (admins[i].id == id) return admins[i]
    }
    throw new Error('ADMIN NOT FOUND : ' + id)

  }

  function getAdministratorByRowNum(rowNum) {
    let admins = opts.administrators
    for (let i = 0; i < admins.length; i++) {
      if (admins[i].rowNum == rowNum) return admins[i]
    }
    throw new Error('ADMIN NOT FOUND : ' + rowNum)

  }

  function addJob(job) {
    if (!(typeof(job) === 'undefined')) {
      jobs.push(job)
      $.each(job.tasks, function (i, task) {
        tasks[task.id] = task
      })

    }

    render()
  }

  function addJobs(jobs) {
    if (!(typeof(jobs) === 'undefined') && jobs.length > 0) {
      $.each(jobs, function (i, job) {
        addJob(job)
      })
    }
  }

  function unlinkTask(aLink) {
    let $cell = $(aLink).parent()
    let taskId = $cell.attr('taskId')

    $cell.popover('hide')

    let task = popTaskById(taskId)

    ATasks.addTask(task)

    changeTask(taskId)
  }

  function changeTask(taskId) {
    let index = jQuery('#indexJob').val()
    let url = `${SELF_URL}?index=${index}&id=${taskId}&hours=100`

    jQuery.ajax({
      url        : url,
      type       : "get",
      contentType: false,
      cache      : false,
      processData: false,
      success    : function () { }
    })
  }

  function popTaskById(taskId) {
    let result = -1
    //iterate jobs
    $.each(jobs, function (i, job) {
      //iterate tasks in jobs
      $.each(job.tasks, function (j, task) {
        if (typeof task !== 'undefined')
          if (task.id + '' === taskId) {
            let result_arr = jobs[i].tasks.splice(j, 1)
            result = result_arr[0]
            renew()
          }
      })
    })
    if (result !== -1) {
      return result
    }
    throw new Error('Task not found!')
  }


  return {
    init: generate,

    addJob: addJob,
    addJobs: addJobs,

    unlinkTask: unlinkTask,

    render: render,

    getAdministratorByRowNum: getAdministratorByRowNum
  }
})()

let AMonthWorkTable = (function () {
  let $Table = null
  let year = null
  let month = null
  let dayCells = {}

  let rawJobs = []
  let renderedJobs = []

  $(function () {
    defineFormSubmitLogic()
  })

  function init() {
    $Table = $('table.work-table-month')
    year = $Table.attr('data-year')
    month = $Table.attr('data-month')

    let mdayLinks = $Table.find('a.mday')

    // Init hash for table cells
    if (mdayLinks.length > 0) {
      for (let i = 0; i < mdayLinks.length; i++) {
        let $mdayLink = $(mdayLinks[i])
        let mday = $mdayLink.attr('data-mday')
        dayCells[mday] = $mdayLink.parent()
      }
    } else {
      _log(1, 'Msgs', 'Not a valid msgs_task_board table. No mdayLinks inside')
    }
  }

  function addJob(ui, mday) {
    let task = ui.helper

    addJobs([{
      id: task.attr('taskId'),
      name: task.attr('taskName'),
      plan_date: year + "-" + month + "-" + ensureLength(mday, 2)
    }])

    task.popover('hide')
    task.remove()
  }

  function addJobs(jobsArray) {
    if (jobsArray.length > 0) {
      // Fill tasks where date is defined
      if (jobsArray.length > 0) {
        for (let j = 0; j < jobsArray.length; j++) {
          renderJob(jobsArray[j])
        }
      }
    }
    else {
      _log(1, "Msgs", "Empty jobs array")
    }
  }

  function renderJob(task) {

    let jobDay = Number(task["plan_date"].split("-")[2])

    rawJobs[task.id] = task

    let $task = $('<div></div>')
    $task.addClass('workElement')

    let removeLink = '<a onclick="AMonthWorkTable.unlinkTask(this, ' + task.id + ')">' +
      '<span class="fa fa-remove"></span>' +
      '</a>&nbsp;&nbsp;'
    let detailLink = '<a href="?header=3&full=1&get_index=msgs_admin&chg=' + task.id + '" target="_blank">' +
      '<span class="fa fa-list-alt"></span>' +
      '</a>&nbsp;&nbsp;'
    let taskText = task.name
    if (taskText.length > 20) {
      taskText = `${taskText.substr(0, 20)}...`
    }
    $task.html(removeLink + detailLink + taskText)

    $task.attr('taskId', task.id)
    $task.attr('taskName', task.name)
    $task.attr('title', task.message)

    if (tasksInfo[task.id]) {
      renderTooltip($task, tasksInfo[task.id], 'bottom')
    }

    if (!task.admin) {
      task.admin = task.name
    }

    renderedJobs[task.id] = $task

    dayCells[jobDay].append($task)
  }

  function unlinkTask(context, taskId) {
    let holder = $(context).parent()
    holder.popover("hide")
    holder.remove()

    let task = rawJobs[taskId]

    delete task.plan_date
    delete rawJobs[taskId]

    ATasks.addTask(task)
  }

  function defineFormSubmitLogic() {

    $('#tasksFormMonth').on('submit', function (event) {

      $('#jobsNew').val(JSON.stringify(desparseArray(rawJobs)))
      $('#jobsPopped').val(JSON.stringify(ATasks.getTasks()))

    })

    $('#cancelBtn').on('click', function () {
      location.reload(false)
    })

    function desparseArray(array) {
      let result = []
      for (let i in array) {
        if (!array.hasOwnProperty(i)) continue
        if (array[i] != null) result.push(array[i])
      }
      return result
    }
  }

  return {
    addJob: addJob,
    addJobs: addJobs,
    unlinkTask: unlinkTask,
    init: init
  }
})()

let ATasks = (function () {
  let tasks = [ ]

  let $elementsWrapper

  $(function () {
    $elementsWrapper = $('#new-tasks')
  })

  function render() {
    if (tasks.length > 0) {
      $elementsWrapper.empty()
      for (let id in tasks) {
        if (!tasks.hasOwnProperty(id)) continue
        renderTask(tasks[id])
      }
    }

    function renderTask(task) {
      let $divBox = $(
        `<div class="col-md-3">
          <div class="col-md-2"></div>
        </div>
      `)

      let $task = $('<div></div>')

      $task.addClass('workElement')
      $task.addClass('card card-outline card-primary')

      if (task.id == tableOptions.highlighted) {
        $task.addClass('taskActive')
      }

      if (task.message && task.message.length > 20) {
        task.message = `${task.message.substr(0, 20)}...`
      }

      let taskText = `
          <div class="card card-primary card-outline card-header">
            ${task.id}
          </div>
          <div class="card-body">
            ${task.message}
          </div>
        `

      $task.html(taskText)
      $task.attr('taskLength', task.length)
      $task.attr('taskId', task.id)
      $task.attr('taskName', task.name)
      $task.attr('title', task.message)

      $divBox.append($task)

      $elementsWrapper.append($divBox)

      $task.draggable({
        snap: ".taskFree",
        snapMode: 'inner',
        start: initTargets,
        cursorAt: {
          top: 5,
          left: 1
        },
        revert: 'invalid'
      })
    }
  }

  function initTargets(event, ui) {
    let length = null
    if (isDayTable) length = Number($(ui.helper).attr('taskLength'))

    let classForTarget = (isDayTable) ? 'taskFree' : 'dayCell'

    let dayTableDropFunction = function (event, ui) {
      let row = $(this).attr('row')
      let col = $(this).attr('col')
      ATasks.acceptTask(ui, row, col)
    }

    let monthTableDropFunction = function (event, ui) {
      let mday = $(this).find('a').attr('data-mday')
      delete tasks[ui.helper.attr('taskId')]
      AMonthWorkTable.addJob(ui, mday)
    }

    let droppableOptions = {
      accept: '.workElement',
      activeClass: "correctTarget",
      drop: (isDayTable) ? dayTableDropFunction : monthTableDropFunction,
      tolerance: 'pointer'
    }

    if (length != null && length > 1) {
      let $cells = $('.taskFree')
      $.each($cells, function (i, cell) {
        if ($(cell).attr('lengthFree') >= length) {
          $(cell).droppable(droppableOptions)
        }
      })
    }
    else {
      $('.' + classForTarget).droppable(droppableOptions)
    }
  }

  function addTask(task, renderBool) {
    tasks[task.id] = task
    if (typeof(renderBool) === 'undefined')
      render()
  }

  function addTasks(taskArr) {
    if (!(typeof(taskArr) === 'undefined')) {
      $.each(taskArr, function (i, e) {
        addTask(e)
      })
      render()
    }
  }

  function acceptTask(ui, row, col) {
    let taskId = ui.draggable.attr('taskId')
    let taskLength = ui.draggable.attr('taskLength')
    let taskName = ui.draggable.attr('taskName')
    let start = Number(col)

    let task = {
      id: taskId,
      start: start,
      length: taskLength,
      name: taskName,
      plan_position: +col
    }

    let admin = AWorkTable.getAdministratorByRowNum(row)
    let newJob = {
      administrator: admin.id,
      tasks: [
        task
      ]
    }

    AWorkTable.addJob(newJob)

    delete tasks[taskId]
    ui.draggable.popover('hide')
    ui.draggable.remove()
  }

  function getTasks() {
    let taskIds = []
    if (tasks.length > 0) {
      for (let id in tasks) {
        if (!tasks.hasOwnProperty(id)) continue
        taskIds.push(tasks[id].id)
      }
    }
    return taskIds
  }


  return {
    render: render,

    acceptTask: acceptTask,

    addTask: addTask,
    addTasks: addTasks,

    getTasks: getTasks
  }


})()

