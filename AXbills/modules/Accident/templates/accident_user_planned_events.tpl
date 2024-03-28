%CALENDAR_BUTTON%
%LIST_BUTTON%

<div class='card card-primary card-outline'>
  %MONTH_SWITCH%
</div>

%TABLE%

<script>

  try {
    var arr = JSON.parse('%JSON_LIST%');
  } catch (err) {
    console.log('JSON parse error');
    console.log(err);
  }

  arr.forEach(function(item) {

    let date_open = item.DATE_OPEN.substr(0,10);

    let accidentDiv = $(`<div class="p-1 bd-highlight" id='new-acc-container-${item.ID}'></div>`)
    let title = $(`<div class="d-flex bd-highlight p-1 bg-primary border" id='title-${item.ID}'>
          <div class="bd-highlight flex-grow-1 pt-1 w-50"><div title='${item.NAME}. _{WARNING_TIME}_ ${item.DATE_END}' class='accident-title'>${item.NAME}</div></div></div>`);
    accidentDiv.append(title);

    jQuery(`.month-accident-container[data-plan-date='${date_open}']`).append(accidentDiv)

  });

  var table = jQuery('table.work-table-month');
  var table_tds = table.find('td');

  table_tds.find('a.weekday').parent().addClass('bg-danger');
  table_tds.find('span.disabled').parent().addClass('active');

  table_tds.find('a.mday').parent().addClass('dayCell');

</script>


<style>

.accident {
	position: relative;
	margin: 0 0 10px;
	padding: 12px;
	background: #fff;
	box-shadow: 0 1px 4px #d8d8d8;
	border-radius: 2px;
	color: #000;
	cursor: pointer;
			background: rgb(88, 181, 232);
    	color: white;
}
.accident-title {
	font-size: 13px;
	line-height: 15px;
	font-weight: 600;
	word-wrap: break-word;

	width: 100%;
	overflow: hidden;
	display: inline-block;
	text-overflow: ellipsis;
	white-space: nowrap;

}
.accident-info {
	display: inline-flex;
	flex-flow: row wrap;
	align-items: center;
	width: 100%;
	margin: 10px 0 0;
}

/* Month shedule */
table.work-table-month > tbody > tr > td {
	 vertical-align: top !important;
 }
table.work-table-month > tbody > tr > td.active {
	cursor: not-allowed;
}
.dayCell {
	max-width: 70px;
}
table.work-table-month td {
	width: 70px;
	height: 100px;
	border: 1px silver solid;
}
table.work-table-month a.mday {
	right: 0;
	text-align: right;
}
td .workElement {
	background-color: lightblue;
	border: 1px solid lightblue;
	border-radius: 3px;
	margin: 1px 0;
	font-weight: 600;
}
.month-accidents-container {
	max-height: 100px;
	overflow-y: scroll;
}
.month-accidents-container {
	-ms-overflow-style: none; /* for Internet Explorer, Edge */
	scrollbar-width: none; /* for Firefox */
	overflow-y: scroll;
}

</style>